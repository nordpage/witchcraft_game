extends Control

signal plant_selected(plant_type)

@onready var item_container = $VBoxContainer/GridContainer
@onready var witch_player = get_node_or_null("/root/MainScene/WitchPlayer")

var plant_button_scene = preload("res://UI/PlantButton.tscn")
var soil_instance = null
var plant_options = {}
var player_input_state = false

func _ready():
	# Подключаем сигнал кнопки закрытия
	#if close_button:
		#close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	visible = false
	

func show_for_soil(soil):
	soil_instance = soil
	plant_options = soil.plant_options
	
	# Сохраняем состояние игрока и замораживаем его
	if witch_player:
		player_input_state = witch_player.is_processing_input()
		witch_player.set_process_input(false)
		witch_player.set_physics_process(false)
	
	# Освобождаем мышь
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Анимируем затемнение фона
	#background_overlay.color = Color(0, 0, 0, 0)
	#background_overlay.visible = true
	#var tween = create_tween()
	#tween.tween_property(background_overlay, "color", Color(0, 0, 0, 0.7), 0.3)
	
	# Очищаем предыдущие кнопки
	for child in item_container.get_children():
		child.queue_free()
	
	# Создаем кнопки для каждого растения
	for plant_id in plant_options.keys():
		var plant_data = plant_options[plant_id]
		var button = plant_button_scene.instantiate()
		button.setup(plant_id, plant_data)
		button.connect("plant_selected", Callable(self, "_on_plant_selected"))
		item_container.add_child(button)
	
	# Показываем меню
	visible = true

func _on_plant_selected(plant_id):
	if soil_instance:
		soil_instance.plant(plant_id)
		hide_menu()

func _on_close_button_pressed():
	print("Close button pressed")
	hide_menu()

func hide_menu():
	# Анимация закрытия
	var tween = create_tween()
	#tween.tween_property(background_overlay, "color", Color(0, 0, 0, 0), 0.3)
	tween.tween_callback(func():
		# Восстанавливаем состояние игрока
		if witch_player:
			witch_player.set_process_input(player_input_state)
			witch_player.set_physics_process(true)
		
		# Возвращаем захват мыши для управления камерой
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		visible = false
	)

# Обработка нажатия Escape для закрытия меню
func _input(event):
	if visible and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_close_button_pressed()
