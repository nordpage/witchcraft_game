extends Node3D

"""
(c) 2021-2024 Pascal Schuppli

Demonstrates the use of the RadialMenu control.

This code is made available under the MIT license. See LICENSE for further
information.
"""

const PLANT_TEXTURE = preload("res://UI/Menus/Soil/planting.svg")
const WATER_TEXTURE = preload("res://UI/Menus/Soil/watering.svg")
const COMPOST_TEXTURE = preload("res://UI/Menus/Soil/compost.svg")
const HARVEST_TEXTURE = preload("res://UI/Menus/Soil/pruning.svg")

# Import the Radial Menu
const RadialMenu = preload("res://addons/RadialMenu/RadialMenu.gd")
var selected_soil : StaticBody3D = null
var is_moving_state: bool = false


func create_submenu(parent_menu):
	# create a new radial menu
	var submenu = RadialMenu.new()
	# copy some important properties from the parent menu
	submenu.circle_coverage = 0.45
	submenu.width = parent_menu.width*1.25
	submenu.default_theme = parent_menu.default_theme
	submenu.show_animation = parent_menu.show_animation
	submenu.animation_speed_factor = parent_menu.animation_speed_factor
	submenu.menu_items = [
		{'texture': PLANT_TEXTURE, 'title': "Drunken Petunia", 'id': "plant1"},
		{'texture': PLANT_TEXTURE, 'title': "Rebel Basil", 'id': "plant2"},
		{'texture': PLANT_TEXTURE, 'title': "Rebellious Heather", 'id': "plant3"},

	]
	return submenu


# Called when the node enters the scene tree for the first time.
func _ready():
	var Cart = $CART
	Cart.connect("is_moving", Callable(self, "_on_cart_updated"))
	for soil in get_tree().get_nodes_in_group("soil"):
		soil.connect("soil_clicked", Callable(self, "_on_soil_clicked"))

	# Create a few dummy submenus
	var submenu1 = create_submenu($SoilMenu)

	# Define the main menu's items
	$SoilMenu.menu_items = [
		{'texture': PLANT_TEXTURE, 'title': "Plant", 'id': "planting"},
		{'texture': WATER_TEXTURE, 'title': "Watering", 'id': "watering"},
		{'texture': COMPOST_TEXTURE, 'title': "Compost", 'id': "compost"},
		{'texture': HARVEST_TEXTURE, 'title': "Harvest", 'id': "harvest"},


		#{'texture': ORIGIN_TEXTURE, 'title': "Back to\norigin", 'id': "action5"},
		#{'texture': SCALE_TEXTURE, 'title': "Reset\nscale", 'id': "action6"},
	]


#func _input(event):
	#if event is InputEventMouseButton:
		## open the menu
		#if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			#var m = get_local_mouse_position()
			#$Node/RadialMenu.open_menu(m)
			#get_viewport().set_input_as_handled()

func _on_cart_updated(data):
	is_moving_state = data
	# Обработка сигнала, data — это данные, переданные сигналом


func _on_ArcPopupMenu_item_selected(action, _position):
	if str(action) == "watering":
		selected_soil.water();
	if str(action) == "planting":
		selected_soil.plant()
	if str(action) == "harvest":
		selected_soil.harvest()

func _on_soil_clicked(soil, position):
	if !is_moving_state:
		selected_soil = soil
		print("Получена информация от грядки:", soil.soil_parameters.soil_title)
		var m = position
		$SoilMenu.open_menu(m)
		get_viewport().set_input_as_handled()
		# Здесь можно, например, обновить интерфейс или запустить какую-либо логику
	else:
		print("You need to stop before action!")
