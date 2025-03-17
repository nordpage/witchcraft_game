extends Node

enum WeatherType {
	CLEAR,
	RAIN,
	FOG
}

# Основные настройки погодной системы
@export var current_weather: int = WeatherType.CLEAR
@export var weather_change_interval: float = 15.0  # Интервал смены погоды в секундах
@export var use_random_weather: bool = true  # Включить/выключить случайную смену погоды

# Параметры тумана
@export_group("Fog Settings")
@export var fog_density: float = 0.05
@export var fog_height: float = 10.0
@export var fog_height_density: float = 0.1
@export var fog_aerial_perspective: float = 1.0
@export var fog_depth_begin: float = 10.0
@export var fog_depth_end: float = 100.0
@export var fog_light_color: Color = Color(0.8, 0.8, 0.8)

# Дополнительные параметры объемного тумана
@export_group("Volumetric Fog Settings")
@export var volumetric_fog_density: float = 0.05
@export var volumetric_fog_albedo: Color = Color(0.8, 0.8, 0.8)
@export var volumetric_fog_emission: Color = Color(0, 0, 0)
@export var volumetric_fog_ambient: float = 0.1
@export var volumetric_fog_height: float = 10.0
@export var volumetric_fog_detail_spread: float = 2.0
@export var volumetric_fog_gi_inject: float = 0.0

# Настройки дождя
@export_group("Rain Settings")
@export var rain_intensity: float = 1.0  # Интенсивность частиц дождя
@export var rain_drying_delay: float = 5.0  # Задержка перед началом высыхания после дождя

@onready var rain_particles: GPUParticles3D = $RainParticles
@onready var world_env: WorldEnvironment = $"../WorldEnvironment"

signal weather_changed(new_weather)
signal fog_density_changed(density)

var weather_timer: Timer
var transition_tween: Tween

func _ready() -> void:
	set_weather(current_weather, false)  # Установка начальной погоды без перехода

	# Настройка таймера случайной смены погоды
	weather_timer = Timer.new()
	weather_timer.wait_time = weather_change_interval
	weather_timer.one_shot = false
	weather_timer.autostart = use_random_weather
	add_child(weather_timer)
	weather_timer.connect("timeout", Callable(self, "_on_weather_timer_timeout"))

	# Настройка частиц дождя, если они есть
	if rain_particles:
		adjust_rain_intensity(rain_intensity)

	randomize()  # Инициализируем генератор случайных чисел

func _on_weather_timer_timeout() -> void:
	if !use_random_weather:
		return

	# Выбираем новую погоду, отличную от текущей
	var new_weather = current_weather
	while new_weather == current_weather:
		new_weather = randi() % WeatherType.size()

	set_weather(new_weather)

# Установка погоды с опциональным плавным переходом
func set_weather(weather: int, with_transition: bool = true) -> void:
	var old_weather = current_weather
	current_weather = weather

	# Отменяем предыдущий переход, если он активен
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

	# Применяем эффекты новой погоды
	match weather:
		WeatherType.CLEAR:
			if with_transition:
				fade_rain(false, 1.0)
				fade_fog_out(1.5)
			else:
				if rain_particles:
					rain_particles.visible = false
				disable_volumetric_fog()
			#print("Weather set to CLEAR (sunny)")

			# Если был дождь, запускаем высыхание для всех грядок с задержкой
			if old_weather == WeatherType.RAIN:
				await get_tree().create_timer(rain_drying_delay).timeout
				start_drying_all_soil()

		WeatherType.RAIN:
			if with_transition:
				fade_rain(true, 1.0)
				fade_fog_out(1.0)
			else:
				if rain_particles:
					rain_particles.visible = true
				disable_volumetric_fog()
			#print("Weather set to RAIN")

			# Поливаем все грядки, когда начинается дождь
			water_all_soil()

		WeatherType.FOG:
			if with_transition:
				fade_rain(false, 1.0)

				# Определяем тип тумана в зависимости от времени суток
				var day_night_cycle = get_node_or_null("/root/DayNightCycle")
				if day_night_cycle and (day_night_cycle.time_of_day > 0.75 or day_night_cycle.time_of_day < 0.25):
					# Ночной туман - более густой и темный
					set_fog_properties(0.1, Color(0.5, 0.5, 0.6), Color(0.3, 0.3, 0.4))
				else:
					# Дневной туман - более светлый и рассеянный
					set_fog_properties(0.05, Color(0.8, 0.8, 0.8), Color(0.7, 0.7, 0.7))

				fade_fog_in(2.0)
			else:
				if rain_particles:
					rain_particles.visible = false
				enable_volumetric_fog()
			#print("Weather set to FOG (volumetric fog)")

	# Отправляем сигнал о смене погоды
	emit_signal("weather_changed", weather)

# Установка свойств тумана
func set_fog_properties(density: float, vol_albedo: Color, light_color: Color) -> void:
	volumetric_fog_density = density
	volumetric_fog_albedo = vol_albedo
	fog_light_color = light_color

# Плавное появление дождя
func fade_rain(visible: bool, duration: float = 1.0) -> void:
	if rain_particles:
		if visible:
			rain_particles.visible = true
			var tween = create_tween().set_ease(Tween.EASE_IN)
			tween.tween_property(rain_particles, "amount_scale", rain_intensity, duration)
		else:
			var tween = create_tween().set_ease(Tween.EASE_OUT)
			tween.tween_property(rain_particles, "amount_scale", 0.0, duration)
			tween.tween_callback(Callable(rain_particles, "set_visible").bind(false))

# Настройка интенсивности дождя
func adjust_rain_intensity(intensity: float) -> void:
	rain_intensity = clamp(intensity, 0.1, 2.0)
	if rain_particles and rain_particles.visible:
		rain_particles.amount_scale = rain_intensity

# Включение объемного тумана с расширенными настройками
func enable_volumetric_fog() -> void:
	var env = world_env.environment
	if env:
		env.fog_enabled = true
		env.volumetric_fog_enabled = true

		# Основные параметры
		env.volumetric_fog_density = volumetric_fog_density
		env.volumetric_fog_albedo = volumetric_fog_albedo
		env.volumetric_fog_emission = volumetric_fog_emission
		env.volumetric_fog_emission_energy = 0.0
		env.volumetric_fog_ambient = volumetric_fog_ambient

		# Настройки качества и деталей
		env.volumetric_fog_detail_spread = volumetric_fog_detail_spread
		env.volumetric_fog_gi_inject = volumetric_fog_gi_inject

		# Высота тумана
		env.volumetric_fog_length = 128.0
		env.volumetric_fog_height = volumetric_fog_height
		env.volumetric_fog_sky_affect = 0.8

		# Также настраиваем обычный туман
		env.fog_density = fog_density
		env.fog_height = fog_height
		env.fog_height_density = fog_height_density
		env.fog_aerial_perspective = fog_aerial_perspective
		env.fog_light_color = fog_light_color  # Используем fog_light_color вместо fog_color
		env.fog_depth_begin = fog_depth_begin
		env.fog_depth_end = fog_depth_end

		print("Volumetric fog enabled with density: ", volumetric_fog_density)
	else:
		print("WorldEnvironment.environment не найден!")

# Отключение тумана
func disable_volumetric_fog() -> void:
	var env = world_env.environment
	if env:
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
	else:
		print("WorldEnvironment.environment не найден!")

# Плавное появление тумана
func fade_fog_in(duration: float = 2.0) -> void:
	var env = world_env.environment
	if env:
		env.fog_enabled = true
		env.volumetric_fog_enabled = true
		env.volumetric_fog_albedo = volumetric_fog_albedo
		env.fog_light_color = fog_light_color  # Используем fog_light_color вместо fog_color
		env.fog_depth_begin = fog_depth_begin
		env.fog_depth_end = fog_depth_end

		# Начинаем с нулевой плотности
		env.fog_density = 0.0
		env.volumetric_fog_density = 0.0

		# Плавно увеличиваем плотность
		transition_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
		transition_tween.tween_property(env, "fog_density", fog_density, duration)
		transition_tween.parallel().tween_property(env, "volumetric_fog_density", volumetric_fog_density, duration)
		transition_tween.tween_callback(Callable(self, "_on_fog_transition_complete"))
	else:
		print("WorldEnvironment.environment не найден!")

# Плавное исчезновение тумана
func fade_fog_out(duration: float = 2.0) -> void:
	var env = world_env.environment
	if env and (env.fog_enabled or env.volumetric_fog_enabled):
		transition_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
		transition_tween.tween_property(env, "fog_density", 0.0, duration)
		transition_tween.parallel().tween_property(env, "volumetric_fog_density", 0.0, duration)
		transition_tween.tween_callback(Callable(self, "_on_fog_transition_complete").bind(false))
	else:
		print("Туман уже отключен или WorldEnvironment.environment не найден!")

# Обработчик завершения перехода тумана
func _on_fog_transition_complete(keep_enabled: bool = true) -> void:
	if not keep_enabled:
		disable_volumetric_fog()
	emit_signal("fog_density_changed", volumetric_fog_density if keep_enabled else 0.0)

# Функция для полива всех грядок при дожде
func water_all_soil() -> void:
	for soil in get_tree().get_nodes_in_group("soil"):
		soil.water()

# Функция для запуска процесса высыхания всех грядок
func start_drying_all_soil() -> void:
	for soil in get_tree().get_nodes_in_group("soil"):
		soil.start_drying()

# Форсировать определенную погоду и отключить автоматическую смену
func force_weather(weather: int) -> void:
	use_random_weather = false
	weather_timer.stop()
	set_weather(weather)

# Возобновить автоматическую смену погоды
func resume_random_weather() -> void:
	use_random_weather = true
	weather_timer.start()
