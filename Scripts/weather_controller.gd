extends Node

enum WeatherType {
	CLEAR,
	RAIN,
	FOG
}

@export var current_weather: int = WeatherType.CLEAR
@export var weather_change_interval: float = 15.0  
@export var use_random_weather: bool = true  

# 🌧️ Настройки дождя
@export_group("Rain Settings")
@export var rain_intensity: float = 1.0  
@export var rain_drying_delay: float = 5.0  

# 🌫️ Настройки тумана
@export_group("Fog Settings")
@export var fog_enabled: bool = true
@export var fog_density_rain: float = 0.12
@export var fog_density_clear: float = 0.03
@export var fog_density_fog: float = 0.2

@onready var rain_particles: GPUParticles3D = $RainParticles
@onready var world_env: WorldEnvironment = $"../WorldEnvironment"
@onready var terrain = $"../HTerrain"
@onready var day_night_cycle = $"../DayNightCycle"

signal weather_changed(new_weather)
signal fog_density_changed(density)

var weather_timer: Timer
var transition_tween: Tween

func _ready() -> void:
	set_weather(current_weather, false)

	weather_timer = Timer.new()
	weather_timer.wait_time = weather_change_interval
	weather_timer.one_shot = false
	weather_timer.autostart = use_random_weather
	add_child(weather_timer)
	weather_timer.connect("timeout", Callable(self, "_on_weather_timer_timeout"))

	if rain_particles:
		adjust_rain_intensity(rain_intensity)

	randomize()

# ⏳ Таймер смены погоды
func _on_weather_timer_timeout() -> void:
	if !use_random_weather:
		return

	var new_weather = current_weather
	while new_weather == current_weather:
		new_weather = randi() % WeatherType.size()

	set_weather(new_weather)

# 🌤️ Установка погоды
func set_weather(weather: int, _with_transition: bool = true) -> void:
	current_weather = weather

	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

	match weather:
		WeatherType.CLEAR:
			fade_fog_out(1.5)
			fade_rain(false, 1.0)
			set_ground_wetness(false)

		WeatherType.RAIN:
			fade_fog_out(1.0)
			fade_rain(true, 1.0)
			set_ground_wetness(true)

		WeatherType.FOG:
			fade_fog_in(2.0)
			fade_rain(false, 1.0)

	emit_signal("weather_changed", weather)

# 🌧️ Управление дождём (Интенсивность)
func adjust_rain_intensity(intensity: float) -> void:
	rain_intensity = clamp(intensity, 0.1, 2.0)
	if rain_particles and rain_particles.visible:
		rain_particles.amount = int(1000 * rain_intensity)

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

# 🌫️ Плавное появление/исчезновение тумана
func fade_fog_in(duration: float = 2.0) -> void:
	var env = world_env.environment
	if env:
		transition_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
		transition_tween.tween_property(env, "fog_density", fog_density_fog, duration)
		transition_tween.parallel().tween_property(env, "volumetric_fog_density", fog_density_fog, duration)

func fade_fog_out(duration: float = 2.0) -> void:
	var env = world_env.environment
	if env:
		transition_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
		transition_tween.tween_property(env, "fog_density", fog_density_clear, duration)
		transition_tween.parallel().tween_property(env, "volumetric_fog_density", 0.0, duration)

# 🌧️ Намокание земли (Меняем `wetness` в `ShaderMaterial` HTerrain)
func set_ground_wetness(is_wet: bool):
	var material = terrain.get("material")  # Получаем ShaderMaterial HTerrain
	if material and material is ShaderMaterial:
		var target = 1.0 if is_wet else 0.0
		var tween = create_tween()
		tween.tween_method(
			func(v): material.set_shader_parameter("wetness", v),
			material.get_shader_parameter("wetness"),
			target,
			3.0
		)
