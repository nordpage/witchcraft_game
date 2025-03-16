extends Node3D

# Общая длительность одного цикла дня/ночи в секундах.
# Например, 120.0 секунд = 2 минуты на полный оборот солнца.
@export var day_duration: float = 120.0

# Текущее время суток (накопительное), используется вместе с fmod для цикла.
var time_of_day: float = 0.0

# Узел света (DirectionalLight3D), имитирующий солнце.
@onready var sun: DirectionalLight3D = $"../Sun"

# Environment, который влияет на глобальное освещение.
# Предполагается, что WorldEnvironment находится на том же уровне в дереве,
# например: ../WorldEnvironment
@onready var env: Environment = $"../WorldEnvironment".environment

func _process(delta: float) -> void:
	# Увеличиваем время суток, чтобы солнце непрерывно "облетало" сцену.
	time_of_day += delta / day_duration

	# Получаем дробную часть от 0.0 до 1.0, чтобы цикл повторялся бесконечно.
	var cycle = fmod(time_of_day, 1.0)

	# Вычисляем угол солнца (0° → 360°). 
	# При cycle=0.0 угол = 0°, при cycle=1.0 угол = 360° (что визуально то же самое).
	var angle = 360.0 * cycle
	sun.rotation_degrees.x = angle

	# Дополнительно можно вращать солнце вокруг других осей,
	# например sun.rotation_degrees.y = 30.0, если хотите наклон.

	# Плавная смена освещения: чем ближе cycle к 0.5 (полдень), тем светлее, 
	# чем ближе к 0.0 или 1.0 (ночь), тем темнее.
	var day_night_factor = 1.0 - abs(cycle - 0.5) * 2.0
	day_night_factor = clamp(day_night_factor, 0.0, 1.0)

	# Настраиваем интенсивность окружающего света. 
	# При day_night_factor=1.0 (полдень) – ярко, при 0.0 (полночь) – темно.
	if env:
		# Например, можно ограничить минимум (0.2) и максимум (1.0) для освещения.
		env.ambient_light_energy = lerp(0.2, 1.0, day_night_factor)
	else:
		# На случай, если environment не найден.
		print("WorldEnvironment.environment не задан! Проверьте путь.")
