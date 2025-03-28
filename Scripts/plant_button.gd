extends Button

signal plant_selected(plant_id)

@export var plant_name: Label
@export var growth_info: Label
@export var chance_info: Label
@export var no_seeds_overlay: ColorRect

var plant_id = ""

func setup(id: String, data: Dictionary):
	plant_id = id
	plant_name.text = data.name
	growth_info.text = "Growth: " + str(data.growth_time) + "s"
	chance_info.text = "Chance: " + str(int(data.growth_chance * 100)) + "%"
	
	# Установка иконки, если она есть
	if data.has("icon") and data.icon != null:
		icon = data.icon
	
	# Проверка наличия семян
	if ResourceManager.get_resource("seeds") < 1:
		disabled = true
		no_seeds_overlay.visible = true
	else:
		disabled = false
		no_seeds_overlay.visible = false

func _ready():
	print("Button ready:", plant_id)
	connect("pressed", Callable(self, "_on_button_pressed"))
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))

func _on_mouse_entered():
	print("Mouse entered:", plant_id)


func _on_button_pressed():
	emit_signal("plant_selected", plant_id)
