extends CanvasLayer

@onready var FirewoodLabel = $PanelContainer/HBoxContainer/FirewoodLabel
@onready var FatigueBar = $PanelContainer/HBoxContainer/FatigueBar
@onready var SeedLabel = $PanelContainer/HBoxContainer/SeedLabel
@onready var PlantsLabel = $PanelContainer/HBoxContainer/PlantsLabel
# В скрипте UI, например, InventoryUI.gd
func _ready():
	ResourceManager.connect("resource_changed", Callable(self, "_on_resource_changed"))
	_update_resource_ui("firewood", ResourceManager.get_resource("firewood"))
	_update_resource_ui("seeds", ResourceManager.get_resource("seeds"))
	_update_resource_ui("plants", ResourceManager.get_resource("plants"))
	_update_resource_ui("witch_fatigue", ResourceManager.get_resource("witch_fatigue"))

func _on_resource_changed(resource_name: String, new_value: float) -> void:
	_update_resource_ui(resource_name, new_value)
		
func _update_resource_ui(resource_name: String, new_value: float) -> void:
	match resource_name:
		"firewood":
			FirewoodLabel.text = "Firewood: " + str(new_value)
		"seeds":
			SeedLabel.text = "Seeds: " + str(new_value)
		"plants":
			PlantsLabel.text = "Plants: " + str(new_value)
		"witch_fatigue":
			FatigueBar.value = new_value
		_:
			pass  # Можно добавить обработку других ресурсов
