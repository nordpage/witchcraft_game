# Изменения в HUD.gd
extends CanvasLayer

@onready var DayTimeLabel = $PanelContainer/HBoxContainer/DayTimeLabel
@onready var FirewoodLabel = $PanelContainer/HBoxContainer/FirewoodLabel
@onready var FatigueBar = $PanelContainer/HBoxContainer/FatigueBar
@onready var SeedLabel = $PanelContainer/HBoxContainer/SeedLabel
@onready var PlantsLabel = $PanelContainer/HBoxContainer/PlantsLabel
#@onready var brewing_ui = $BrewingUI
#@onready var brewing_button = $BrewingButton

func _ready():
	ResourceManager.connect("resource_changed", Callable(self, "_on_resource_changed"))
	_update_resource_ui("firewood", ResourceManager.get_resource("firewood"))
	_update_resource_ui("seeds", ResourceManager.get_resource("seeds"))
	_update_resource_ui("plants", ResourceManager.get_resource("plants"))
	_update_resource_ui("witch_fatigue", ResourceManager.get_resource("witch_fatigue"))
	var DayNightCycle = $"../DayNightCycle"
	DayNightCycle.connect("time_of_day_changed", Callable(self, "_on_time_of_day_changed"))

	# Скрываем UI зельеварения
	#brewing_ui.visible = false

func _on_time_of_day_changed(current_time_of_day):
	match current_time_of_day:
		1:
			DayTimeLabel.text = "Рассвет"
		2:
			DayTimeLabel.text = "Утро"
		3:
			DayTimeLabel.text = "День"
		4:
			DayTimeLabel.text = "Вечер"
		5:
			DayTimeLabel.text = "Ночь"
		_:
			DayTimeLabel.text = ""


func _on_brewing_button_pressed():
	# Переключаем видимость UI зельеварения
	#brewing_ui.visible = !brewing_ui.visible
	pass

func _process(_delta):
	# Обновляем индикатор усталости каждый кадр для плавности
	_update_fatigue_ui(ResourceManager.get_resource("witch_fatigue"))

func _on_resource_changed(resource_name: String, new_value) -> void:
	_update_resource_ui(resource_name, new_value)

func _update_resource_ui(resource_name: String, new_value) -> void:
	match resource_name:
		"firewood":
			FirewoodLabel.text = "Firewood: " + str(int(new_value))
		"seeds":
			SeedLabel.text = "Seeds: " + str(int(new_value))
		"plants":
			PlantsLabel.text = "Plants: " + str(int(new_value))
		"witch_fatigue":
			_update_fatigue_ui(new_value)
		_:
			pass  # Можно добавить обработку других ресурсов

# Отдельная функция для обновления интерфейса усталости
func _update_fatigue_ui(fatigue_value: float) -> void:
	# Проверяем, существует ли индикатор усталости
	if FatigueBar:
		# Устанавливаем значение индикатора (ProgressBar принимает float)
		FatigueBar.value = fatigue_value

		# Меняем цвет индикатора усталости в зависимости от значения
		if fatigue_value > 0.7:
			FatigueBar.modulate = Color(1.0, 0.3, 0.3)  # Красный
		elif fatigue_value > 0.4:
			FatigueBar.modulate = Color(1.0, 0.8, 0.2)  # Желтый
		else:
			FatigueBar.modulate = Color(0.2, 0.8, 0.2)  # Зеленый
