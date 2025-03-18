extends Node3D

# Общая длительность одного цикла дня/ночи в секундах.
# Например, 120.0 секунд = 2 минуты на полный оборот солнца.
@export var day_duration: float = 120.0

# Текущее время суток (накопительное), используется вместе с fmod для цикла.
var time_of_day: float = 0.0

# Перечисление для времени суток
enum TimeOfDay {
	NIGHT,
	DAWN,
	MORNING,
	DAY,
	EVENING,
	DUSK
}

# Текущее время суток как перечисление
var current_time_of_day: TimeOfDay = TimeOfDay.DAY

# Узел света (DirectionalLight3D), имитирующий солнце.
@onready var sun: DirectionalLight3D = $"../Sun"

# Environment, который влияет на глобальное освещение.
# Предполагается, что WorldEnvironment находится на том же уровне в дереве,
# например: ../WorldEnvironment
@onready var env: Environment = $"../WorldEnvironment".environment

# Сигнал о смене времени суток
signal time_of_day_changed(new_time_of_day)

func _process(delta: float) -> void:
	# Увеличиваем время суток, чтобы солнце непрерывно "облетало" сцену.
	time_of_day += delta / day_duration

	# Получаем дробную часть от 0.0 до 1.0, чтобы цикл повторялся бесконечно.
	var cycle = fmod(time_of_day, 1.0)

	# Вычисляем угол солнца (0° → 360°).
	# При cycle=0.0 угол = 0°, при cycle=1.0 угол = 360° (что визуально то же самое).
	var angle = 360.0 * cycle
	sun.rotation_degrees.x = angle

	# Определяем текущее время суток и отправляем сигнал при изменении
	update_time_of_day(cycle)

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

# Функция для определения текущего времени суток
func update_time_of_day(cycle: float) -> void:
	var previous_time = current_time_of_day

	# Определяем время суток по циклу (0.0-1.0)
	if cycle < 0.08 or cycle > 0.92:
		current_time_of_day = TimeOfDay.NIGHT     # Ночь (22:00 - 04:00)
	elif cycle < 0.21:
		current_time_of_day = TimeOfDay.DAWN      # Рассвет (04:00 - 06:00)
	elif cycle < 0.33:
		current_time_of_day = TimeOfDay.MORNING   # Утро (06:00 - 10:00)
	elif cycle < 0.67:
		current_time_of_day = TimeOfDay.DAY       # День (10:00 - 16:00)
	elif cycle < 0.79:
		current_time_of_day = TimeOfDay.EVENING   # Вечер (16:00 - 19:00)
	else:
		current_time_of_day = TimeOfDay.DUSK      # Закат (19:00 - 22:00)

	# Отправляем сигнал только если время суток изменилось
	if previous_time != current_time_of_day:
		emit_signal("time_of_day_changed", current_time_of_day)

# Функция для получения текущего времени суток как строки
func get_time_of_day_string() -> String:
	match current_time_of_day:
		TimeOfDay.NIGHT:
			return "Night"
		TimeOfDay.DAWN:
			return "Dawn"
		TimeOfDay.MORNING:
			return "Morning"
		TimeOfDay.DAY:
			return "Day"
		TimeOfDay.EVENING:
			return "Evening"
		TimeOfDay.DUSK:
			return "Dusk"
		_:
			return "Unknown"

# Функция для получения текущего цикла (0.0-1.0)
func get_day_cycle() -> float:
	return fmod(time_of_day, 1.0)
