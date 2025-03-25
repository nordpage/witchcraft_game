extends StaticBody3D

@onready var body = $SoilBody
signal soil_clicked(soil, position, soil_parameters)

@export var soil_parameters: SoilData
@export var plant_options: Dictionary = {
	"drunken_petunia": {
		"name": "Drunken Petunia",
		"scene": preload("res://Plants/Petunia.tscn"),
		"growth_time": 5.0,
		"growth_chance": 0.85
	},
	"rebel_basil": {
		"name": "Rebel Basil",
		"scene": preload("res://Plants/Basil.tscn"),
		"growth_time": 6.0,
		"growth_chance": 0.8
	},
	"shadow_heather": {
		"name": "Shadow Heather",
		"scene": preload("res://Plants/Heather.tscn"),
		"growth_time": 7.0,
		"growth_chance": 0.9
	},
	"lunatic_mint": {
		"name": "Lunatic Mint",
		"scene": preload("res://Plants/Mint.tscn"),
		"growth_time": 4.0,
		"growth_chance": 0.88
	},
	"witches_thyme": {
		"name": "Witches' Thyme",
		"scene": preload("res://Plants/Thyme.tscn"),
		"growth_time": 5.5,
		"growth_chance": 0.82
	},
	"frostbite_fennel": {
		"name": "Frostbite Fennel",
		"scene": preload("res://Plants/Fennel.tscn"),
		"growth_time": 6.5,
		"growth_chance": 0.77
	}
}


func get_interaction_hint():
	if not soil_parameters.is_sown:
		return "Посадить"
	elif not soil_parameters.is_watered:
		return "Полить"
	else:
		return "Собрать"


var drying_timer: Timer = null

func _ready():
	add_to_group("soil")
	drying_timer = Timer.new()
	drying_timer.one_shot = true
	add_child(drying_timer)

func _input_event(camera: Camera3D, event: InputEvent, click_position: Vector3, click_normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		print("Soil clicked at:", click_position)
		emit_signal("soil_clicked", self, click_position, soil_parameters)

func plant(plant_type: String):
	if not soil_parameters.is_sown and plant_options.has(plant_type):
		var plant_data = plant_options[plant_type]
		if ResourceManager.remove_resource("seeds", 1):
			soil_parameters.is_sown = true
			soil_parameters.current_plant = plant_type
			print("Planting:", plant_type)
			WitchFatigue.add_fatigue(0.1)
			grow_plant_after_delay(plant_data)
		else:
			print("Not enough seeds!")

func grow_plant_after_delay(plant_data: Dictionary) -> void:
	var growth_modifier = 1.0
	var weather_controller = $"../../../../WeatherController"
	if weather_controller and weather_controller.current_weather == weather_controller.WeatherType.RAIN:
		growth_modifier = 0.7  # Быстрее растёт во время дождя

	var modified_time = plant_data["growth_time"] * growth_modifier
	await get_tree().create_timer(modified_time).timeout
	grow_plant(plant_data)

func grow_plant(plant_data: Dictionary) -> void:
	if randf() <= plant_data["growth_chance"]:
		var plant_instance = plant_data["scene"].instantiate()
		plant_instance.name = "Plant"
		body.add_child(plant_instance)
		plant_instance.position = Vector3(0, body.get_aabb().size.y / 2, 0)
		if plant_instance.has_method("set_visible"):
			plant_instance.visible = true
		print("Plant has grown:", plant_instance.name)
		soil_parameters.has_plant = true
	else:
		print("Plant failed to grow!")
		soil_parameters.is_sown = false
