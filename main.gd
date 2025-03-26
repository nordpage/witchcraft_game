extends Node3D

const PLANT_TEXTURE = preload("res://UI/Menus/Soil/planting.svg")
const WATER_TEXTURE = preload("res://UI/Menus/Soil/watering.svg")
const COMPOST_TEXTURE = preload("res://UI/Menus/Soil/compost.svg")
const HARVEST_TEXTURE = preload("res://UI/Menus/Soil/pruning.svg")

# Import the Radial Menu
const RadialMenu = preload("res://addons/RadialMenu/RadialMenu.gd")
var selected_soil : StaticBody3D = null
var is_moving_state: bool = false
@onready var fade_anim = $CanvasLayer/AnimationPlayer
@onready var plant_selection_menu = $CanvasLayer/PlantSelectionMenu
@onready var Cart = $CART

func fade_in():
	fade_anim.play("fade_in")

func fade_out():
	fade_anim.play("fade_out")


func create_plant_submenu():
	# Создаем подменю для каждого типа растения
	var submenu = RadialMenu.new()
	submenu.circle_coverage = 0.45
	submenu.width = $SoilMenu.width * 1.25
	submenu.default_theme = $SoilMenu.default_theme
	submenu.show_animation = $SoilMenu.show_animation
	submenu.animation_speed_factor = $SoilMenu.animation_speed_factor
	
	# Динамически заполняем подменю доступными растениями
	var plant_items = []
	
	if selected_soil and selected_soil.plant_options:
		for plant_id in selected_soil.plant_options.keys():
			var plant_data = selected_soil.plant_options[plant_id]
			plant_items.append({
				'texture': PLANT_TEXTURE,
				'title': plant_data.name,
				'id': plant_id
			})
	
	submenu.menu_items = plant_items
	return submenu
	
	
func _input(event):
	if event.is_action_pressed("switch_mode"):
		if GameState.current_mode == GameState.Mode.DRIVING:
			fade_switch_to_witch()
		else:
			fade_switch_to_cart()

func switch_to_witch():
	var witch = $WitchPlayer
	var spawn_point = $CART/WitchSpawnPoint
	var cart = $CART

	# Перемещаем ведьму в точку, только если она не активна
	if GameState.current_mode != GameState.Mode.WALKING:
		witch.global_transform.origin = spawn_point.global_transform.origin
		witch.global_transform.basis = spawn_point.global_transform.basis

	# Сначала полностью деактивируем физику тележки
	cart.freeze = true
	cart.engine_force = 0
	cart.brake = 100 # Включаем тормоза
	cart.linear_velocity = Vector3.ZERO
	cart.angular_velocity = Vector3.ZERO
	cart.set_physics_process(false)
	
	# Затем отключаем колеса
	for child in cart.get_children():
		if child is VehicleWheel3D:
			child.use_as_traction = false
			child.use_as_steering = false

	# Только после этого активируем ведьму
	witch.visible = true
	witch.get_node("WitchCameraPivot/WitchCamera").current = true
	cart.get_node("CartCamera").current = false

	GameState.current_mode = GameState.Mode.WALKING
	print("Switched to WALKING mode")

func fade_switch_to_witch():
	fade_out()
	await fade_anim.animation_finished
	switch_to_witch()
	fade_in()
	
func fade_switch_to_cart():
	fade_out()
	await fade_anim.animation_finished
	switch_to_cart()
	fade_in()


func switch_to_cart():
	var witch = $WitchPlayer
	var cart = $CART
	
	# Скрываем ведьму
	witch.visible = false
	
	# Сначала активируем камеру тележки
	cart.get_node("CartCamera").current = true
	
	# Затем настраиваем колеса
	for child in cart.get_children():
		if child is VehicleWheel3D:
			child.use_as_traction = true
			child.use_as_steering = (child.name.contains("Front"))
	
	# Затем аккуратно активируем физику
	cart.freeze = false
	cart.set_physics_process(true)
	cart.brake = 0 # Отпускаем тормоза
	
	# Устанавливаем начальную скорость в ноль для уверенности
	cart.linear_velocity = Vector3.ZERO
	cart.angular_velocity = Vector3.ZERO

	GameState.current_mode = GameState.Mode.DRIVING
	print("Switched to DRIVING mode")


# Called when the node enters the scene tree for the first time.
func _ready():
	# Инициализируем необходимые ресурсы, если их еще нет
	if ResourceManager.get_resource("water") == 0:
		ResourceManager.add_resource("water", 10)
	if ResourceManager.get_resource("fertilizer") == 0:
		ResourceManager.add_resource("fertilizer", 5)
		
	# Подключаем сигналы
	Cart.connect("is_moving", Callable(self, "_on_cart_updated"))
	for soil in get_tree().get_nodes_in_group("soil"):
		soil.connect("soil_clicked", Callable(self, "_on_soil_clicked"))

	# Настраиваем меню посадки растений
	if plant_selection_menu:
		plant_selection_menu.connect("plant_selected", Callable(self, "_on_plant_selected"))
	else:
		print("ERROR: PlantSelectionMenu not found in the scene!")

	# Настраиваем меню взаимодействия с грядкой
	setup_soil_menu()

func setup_soil_menu():
	# Создаем подменю для растений
	var plant_submenu = create_plant_submenu()
	
	# Настраиваем основное меню взаимодействия с грядкой
	$SoilMenu.menu_items = [
		{'texture': PLANT_TEXTURE, 'title': "Plant", 'id': plant_submenu},
		{'texture': WATER_TEXTURE, 'title': "Watering", 'id': "watering"},
		{'texture': COMPOST_TEXTURE, 'title': "Fertilize", 'id': "fertilize"},
		{'texture': HARVEST_TEXTURE, 'title': "Harvest", 'id': "harvest"}
	]
	
	# Подключаем сигнал выбора пункта меню
	$SoilMenu.connect("item_selected", Callable(self, "_on_soil_menu_item_selected"))

func _on_cart_updated(data):
	is_moving_state = data

func _on_soil_menu_item_selected(item_id):
	if selected_soil == null:
		return
	
	# Обрабатываем действия из основного меню
	match item_id:
		"watering":
			selected_soil.water_plant()
		"fertilize":
			selected_soil.fertilize()
		"harvest":
			if selected_soil.has_method("collect_plant"):
				selected_soil.collect_plant()
			else:
				print("Method collect_plant not found")
	
	# Если это подменю растений, вызываем метод посадки
	if typeof(item_id) == TYPE_STRING and selected_soil.plant_options.has(item_id):
		selected_soil.plant(item_id)

func _on_plant_selected(plant_id):
	if selected_soil:
		selected_soil.plant(plant_id)

func _on_soil_clicked(soil, position):
	if !is_moving_state:
		selected_soil = soil
		print("Получена информация от грядки:", soil.soil_parameters.soil_title)
		
		# Обновляем подменю с растениями, так как теперь у нас новая грядка
		setup_soil_menu()
		
		# Открываем радиальное меню
		$SoilMenu.open_menu(position)
		get_viewport().set_input_as_handled()
	else:
		print("You need to stop before action!")
