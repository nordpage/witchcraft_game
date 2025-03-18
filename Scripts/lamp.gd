extends Node3D

@export var lamp_light_path: NodePath
var lamp_light: OmniLight3D

func _ready() -> void:
	var DayNightCycle = $"../../DayNightCycle"
	DayNightCycle.connect("time_of_day_changed", Callable(self, "_on_time_of_day_changed"))

	# Проверяем и инициализируем свет сразу
	if lamp_light_path:
		lamp_light = get_node(lamp_light_path)

func _on_time_of_day_changed(current_time_of_day: int) -> void:
	if not lamp_light:
		return  # Если свет не найден, не выполняем код

	match current_time_of_day:
		0, 5:  # Рассвет, вечер, ночь
			lamp_light.visible = true
		_:
			lamp_light.visible = false  # Отключаем свет днём
