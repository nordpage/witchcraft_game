extends Node

enum WeatherType {
	CLEAR,
	RAIN,
	FOG
}

@export var current_weather: int = WeatherType.CLEAR
@export var weather_change_interval: float = 15.0  # Интервал смены погоды в секундах

@onready var rain_particles: GPUParticles3D = $RainParticles
@onready var world_env: WorldEnvironment = $"../WorldEnvironment"

func _ready() -> void:
	set_weather(current_weather)
	# Запускаем таймер для смены погоды
	var timer = Timer.new()
	timer.wait_time = weather_change_interval
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_weather_timer_timeout"))
	
	randomize()  # Инициализируем генератор случайных чисел

func _on_weather_timer_timeout() -> void:
	# Выбираем случайное значение погоды из диапазона 0-2
	var random_weather = randi() % 3
	set_weather(random_weather)

func set_weather(weather: int) -> void:
	current_weather = weather
	match weather:
		WeatherType.CLEAR:
			if rain_particles:
				rain_particles.visible = false
			disable_volumetric_fog()
			print("Weather set to CLEAR (sunny)")
		WeatherType.RAIN:
			if rain_particles:
				rain_particles.visible = true
			disable_volumetric_fog()
			print("Weather set to RAIN")
		WeatherType.FOG:
			if rain_particles:
				rain_particles.visible = false
			enable_volumetric_fog()
			print("Weather set to FOG (volumetric fog)")
			
func enable_volumetric_fog() -> void:
	var env = world_env.environment
	if env:
		env.fog_enabled = true
		env.volumetric_fog_enabled = true
		env.volumetric_fog_albedo = Color(0.8, 0.8, 0.8)
		env.fog_density = 0.2
		env.fog_depth_begin = 10.0
		env.fog_depth_end = 50.0
	else:
		print("WorldEnvironment.environment не найден!")

func disable_volumetric_fog() -> void:
	var env = world_env.environment
	if env:
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
	else:
		print("WorldEnvironment.environment не найден!")
