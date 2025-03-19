extends Node

enum WeatherType {
	CLEAR,
	RAIN,
	FOG
}

# 🌤️ Основные настройки погоды
@export var current_weather: int = WeatherType.CLEAR
@export var weather_change_interval: float = 15.0  # Интервал смены погоды
@export var use_random_weather: bool = true  # Включить случайную смену

# 🌫️ Настройки тумана
@export_group("Fog Settings")
@export var fog_enabled: bool = true
@export var fog_density: float = 0.05
@export var fog_height: float = 10.0
@export var fog_height_density: float = 0.1
@export var fog_aerial_perspective: float = 1.0
@export var fog_depth_begin: float = 10.0
@export var fog_depth_end: float = 100.0
@export var fog_color: Color = Color(0.8, 0.8, 0.8)

# ☁️ Настройки объемного тумана
@export_group("Volumetric Fog Settings")
@export var volumetric_fog_enabled: bool = true
@export var volumetric_fog_density: float = 0.05
@export var volumetric_fog_albedo: Color = Color(0.8, 0.8, 0.8)
@export var volumetric_fog_emission: Color = Color(0, 0, 0)
@export var volumetric_fog_ambient: float = 0.1
@export var volumetric_fog_height: float = 10.0
@export var volumetric_fog_detail_spread: float = 2.0
@export var volumetric_fog_gi_inject: float = 0.0

# 🌧️ Настройки дождя
@export_group("Rain Settings")
@export var rain_intensity: float = 1.0  # Интенсивность дождя
@export var rain_drying_delay: float = 5.0  # Высыхание после дождя

@onready var rain_particles: GPUParticles3D = $RainParticles
@onready var world_env: WorldEnvironment = $"../WorldEnvironment"

signal weather_changed(new_weather)
signal fog_density_changed(density)

var weather_timer: Timer
var transition_tween: Tween

func _ready() -> void:
	set_weather(current_weather, false)  # Начальная погода

	weather_timer = Timer.new()
	weather_timer.wait_time = weather_change_interval
	weather_timer.one_shot = false
	weather_timer.autostart = use_random_weather
	add_child(weather_timer)
	weather_timer.connect("timeout", Callable(self, "_on_weather_timer_timeout"))

	if rain_particles:
		adjust_rain_intensity(rain_intensity)

	randomize()
	
func adjust_rain_intensity(intensity: float) -> void:
	rain_intensity = clamp(intensity, 0.1, 2.0)  # Ограничиваем диапазон значений
	if rain_particles and rain_particles.visible:
		rain_particles.amount = int(1000 * rain_intensity)  # Количество частиц зависит от интенсивности

func _on_weather_timer_timeout() -> void:
	if !use_random_weather:
		return

	var new_weather = current_weather
	while new_weather == current_weather:
		new_weather = randi() % WeatherType.size()

	set_weather(new_weather)

# 🌤️ Установка погоды
func set_weather(weather: int, with_transition: bool = true) -> void:
	var old_weather = current_weather
	current_weather = weather

	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

	match weather:
		WeatherType.CLEAR:
			if with_transition:
				fade_rain(false, 1.0)
				fade_fog_out(1.5)
			else:
				if rain_particles:
					rain_particles.visible = false
				disable_fog()

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
				disable_fog()
				water_all_soil()

		WeatherType.FOG:
			if with_transition:
				fade_rain(false, 1.0)
				enable_fog()
				fade_fog_in(2.0)
			else:
				enable_fog()

	emit_signal("weather_changed", weather)

func start_drying_all_soil() -> void:
	for soil in get_tree().get_nodes_in_group("soil"):
		if soil.has_method("start_drying"):
			soil.start_drying()
			
func water_all_soil() -> void:
	for soil in get_tree().get_nodes_in_group("soil"):
		if soil.has_method("water"):
			soil.water()

# 🌧️ Плавное появление/исчезновение дождя
func fade_rain(visible: bool, duration: float = 1.0) -> void:
	if rain_particles:
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT)

		if visible:
			rain_particles.visible = true
			rain_particles.emitting = true
			tween.tween_property(rain_particles, "speed_scale", 1.0, duration)  
		else:
			tween.tween_property(rain_particles, "speed_scale", 0.1, duration)  
			tween.tween_callback(Callable(rain_particles, "set_visible").bind(false))

# 🏞️ Включение тумана с параметрами из `Inspector`
func enable_fog() -> void:
	var env = world_env.environment
	if env and fog_enabled:
		env.fog_enabled = true
		env.volumetric_fog_enabled = volumetric_fog_enabled

		env.fog_density = fog_density
		env.fog_light_color = fog_color
		env.volumetric_fog_density = volumetric_fog_density
		env.volumetric_fog_albedo = volumetric_fog_albedo
		env.volumetric_fog_emission = volumetric_fog_emission
		env.volumetric_fog_emission_energy = 0.3  # Заменяем отсутствующий параметр
# ❌ Отключение тумана
func disable_fog() -> void:
	var env = world_env.environment
	if env:
		env.fog_enabled = false
		env.volumetric_fog_enabled = false

# 🌫️ Плавное появление тумана
func fade_fog_in(duration: float = 2.0) -> void:
	var env = world_env.environment
	if env:
		transition_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
		transition_tween.tween_property(env, "fog_density", fog_density, duration)
		transition_tween.parallel().tween_property(env, "volumetric_fog_density", volumetric_fog_density, duration)
		transition_tween.tween_callback(Callable(self, "_on_fog_transition_complete"))

# ☀️ Плавное исчезновение тумана
func fade_fog_out(duration: float = 2.0) -> void:
	var env = world_env.environment
	if env:
		transition_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
		transition_tween.tween_property(env, "fog_density", 0.0, duration)
		transition_tween.parallel().tween_property(env, "volumetric_fog_density", 0.0, duration)
		transition_tween.tween_callback(Callable(self, "_on_fog_transition_complete").bind(false))

# Завершаем анимацию тумана
func _on_fog_transition_complete(keep_enabled: bool = true) -> void:
	if not keep_enabled:
		disable_fog()
	emit_signal("fog_density_changed", volumetric_fog_density if keep_enabled else 0.0)
