# PlantSelectionMenu.gd
extends Control

signal plant_selected(plant_type)

@onready var item_container = $VBoxContainer/ScrollContainer/GridContainer
@onready var close_button = $VBoxContainer/HBoxContainer/CloseButton

var soil_instance = null
var plant_options = {}

func _ready():
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	visible = false

func show_for_soil(soil):
	soil_instance = soil
	plant_options = soil.plant_options
	
	# Очищаем предыдущие кнопки
	for child in item_container.get_children():
		child.queue_free()
	
	# Создаем кнопки для каждого растения
	for plant_id in plant_options.keys():
		var plant_data = plant_options[plant_id]
		var button = create_plant_button(plant_id, plant_data)
		item_container.add_child(button)
	
	# Показываем меню
	visible = true

func create_plant_button(plant_id, plant_data):
	var button = Button.new()
	button.text = plant_data.name
	button.custom_minimum_size = Vector2(150, 100)
	
	# Добавляем информацию о времени роста и шансе
	var label = Label.new()
	label.text = "Growth: " + str(plant_data.growth_time) + "s\nChance: " + str(int(plant_data.growth_chance * 100)) + "%"
	button.add_child(label)
	label.position = Vector2(10, 30)
	
	# Подключаем сигнал
	button.connect("pressed", Callable(self, "_on_plant_button_pressed").bind(plant_id))
	
	# Если недостаточно семян, блокируем кнопку
	if ResourceManager.get_resource("seeds") < 1:
		button.disabled = true
		button.tooltip_text = "Not enough seeds!"
	
	return button

func _on_plant_button_pressed(plant_id):
	if soil_instance:
		soil_instance.plant(plant_id)
		hide()

func _on_close_button_pressed():
	hide()
