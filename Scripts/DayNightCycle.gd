extends Node3D

@export var day_duration: float = 120.0  # Длительность полного цикла дня/ночи
var time_of_day: float = 0.0  # Текущее время суток (0.0 - 1.0)

enum TimeOfDay {
	NIGHT,
	DAWN,
	MORNING,
	DAY,
	EVENING,
	DUSK
}

var current_time_of_day: TimeOfDay = TimeOfDay.DAY
var current_weather: int = 0  # 0 - Clear, 1 - Rain, 2 - Fog

@onready var sun: DirectionalLight3D = $"../Sun"
@onready var world_env: WorldEnvironment = $"../WorldEnvironment"
@onready var sky_material: ProceduralSkyMaterial = world_env.environment.sky.sky_material
@onready var weather_controller = $"../WeatherController"

signal time_of_day_changed(new_time_of_day)

func _ready():
	if weather_controller:
		weather_controller.weather_changed.connect(_on_weather_changed)

func _process(delta: float) -> void:
	time_of_day += delta / day_duration
	var cycle = fmod(time_of_day, 1.0)
	sun.rotation_degrees.x = 360.0 * cycle

	update_time_of_day(cycle)
	update_sky_energy(cycle)

	var day_night_factor = 1.0 - abs(cycle - 0.5) * 2.0
	day_night_factor = clamp(day_night_factor, 0.0, 1.0)

	if world_env:
		world_env.environment.ambient_light_energy = lerp(0.2, 1.0, day_night_factor)

func _on_weather_changed(new_weather: int):
	current_weather = new_weather  # Обновляем текущую погоду
	update_sky_energy(fmod(time_of_day, 1.0))  # Пересчитываем освещение и цвет неба

func update_time_of_day(cycle: float) -> void:
	var previous_time = current_time_of_day

	if cycle < 0.08 or cycle > 0.92:
		current_time_of_day = TimeOfDay.NIGHT  
	elif cycle < 0.21:
		current_time_of_day = TimeOfDay.DAWN  
	elif cycle < 0.33:
		current_time_of_day = TimeOfDay.MORNING  
	elif cycle < 0.67:
		current_time_of_day = TimeOfDay.DAY  
	elif cycle < 0.79:
		current_time_of_day = TimeOfDay.EVENING  
	else:
		current_time_of_day = TimeOfDay.DUSK  

	if previous_time != current_time_of_day:
		emit_signal("time_of_day_changed", current_time_of_day)

# 🔥 Плавное изменение освещения, облаков и горизонта
func update_sky_energy(cycle: float):
	if not sky_material or not world_env:
		return

	var target_energy: float
	var target_cover: Color
	var target_top_color: Color
	var target_horizon_color: Color
	var target_ground_horizon: Color
	var target_ground_bottom: Color
	var target_fog_density: float
	var ssao_enabled: bool
	var glow_enabled: bool

	# 🌙 Яркость и цвета неба по времени суток
	if cycle < 0.08 or cycle > 0.92:  # Ночь
		target_energy = 0.2
		target_top_color = Color(0.0, 0.0, 0.05)
		target_horizon_color = Color(0.02, 0.02, 0.08)
		target_ground_horizon = Color(0.02, 0.02, 0.05)
		target_ground_bottom = Color(0.0, 0.0, 0.0)
		target_fog_density = 0.05
		ssao_enabled = false
		glow_enabled = false
	elif cycle < 0.21:  # Рассвет
		target_energy = 0.6
		target_top_color = Color(1.0, 0.7, 0.4)
		target_horizon_color = Color(1.0, 0.5, 0.3)
		target_ground_horizon = Color(0.2, 0.2, 0.3)
		target_ground_bottom = Color(0.1, 0.1, 0.2)
		target_fog_density = 0.1
		ssao_enabled = true
		glow_enabled = true
	elif cycle < 0.67:  # День
		target_energy = 1.2
		target_top_color = Color(0.3, 0.6, 1.0)
		target_horizon_color = Color(1.0, 1.0, 1.0)
		target_ground_horizon = Color(0.4, 0.4, 0.5)
		target_ground_bottom = Color(0.3, 0.3, 0.4)
		target_fog_density = 0.2
		ssao_enabled = true
		glow_enabled = true
	else:  # Вечер / Закат
		target_energy = 0.3
		target_top_color = Color(0.5, 0.3, 0.4)
		target_horizon_color = Color(0.6, 0.2, 0.2)
		target_ground_horizon = Color(0.3, 0.2, 0.3)
		target_ground_bottom = Color(0.2, 0.1, 0.2)
		target_fog_density = 0.15
		ssao_enabled = true
		glow_enabled = true

	# ☁️ Облачность (`sky_cover_modulate`) по погоде
	match current_weather:
		0:  # CLEAR
			target_cover = Color(1, 1, 1, 0.1)
		1:  # RAIN
			target_cover = Color(0.7, 0.7, 0.7, 0.8)
			target_energy *= 0.7
		2:  # FOG
			target_cover = Color(0.6, 0.6, 0.6, 1.0)
			target_energy *= 0.5

	# 🎯 Плавное изменение параметров
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(sky_material, "sky_energy_multiplier", target_energy, 3.0)
	tween.parallel().tween_property(sky_material, "sky_cover_modulate", target_cover, 3.0)
	tween.parallel().tween_property(sky_material, "sky_top_color", target_top_color, 3.0)
	tween.parallel().tween_property(sky_material, "sky_horizon_color", target_horizon_color, 3.0)
	tween.parallel().tween_property(sky_material, "ground_horizon_color", target_ground_horizon, 3.0)
	tween.parallel().tween_property(sky_material, "ground_bottom_color", target_ground_bottom, 3.0)
	tween.parallel().tween_property(world_env.environment, "fog_height_density", target_fog_density, 3.0)
	tween.parallel().tween_property(world_env.environment, "ssao_enabled", ssao_enabled, 3.0)
	tween.parallel().tween_property(world_env.environment, "glow_enabled", glow_enabled, 3.0)
