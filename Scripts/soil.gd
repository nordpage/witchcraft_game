extends StaticBody3D

@onready var body = $SoilBody  # body должен быть MeshInstance3D
var soil_material: StandardMaterial3D

# Сигнал, который отправляется при клике на грядку.
signal soil_clicked(soil, position)

# Экспорт параметров грядки (например, is_watered, is_sown, и опционально has_plant)
@export var soil_parameters: SoilData

# Сцена растения, которую будем инстанцировать после посадки
@export var plant_scene: PackedScene

# Время (в секундах) необходимое для роста растения
@export var growth_time: float = 5.0

func _ready():
	if soil_parameters:
		soil_parameters = soil_parameters.duplicate() as SoilData
	add_to_group("soil")

func _input_event(camera: Camera3D, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		print("Soil clicked!")
		emit_signal("soil_clicked", self, event.position)
		
func water():
	if not soil_parameters.is_watered:
		soil_parameters.is_watered = true
		water_material(soil_parameters.is_watered)
	else:
		print("Garden bed already watered!")
		
func plant():
	if not soil_parameters.is_sown:
		soil_parameters.is_sown = true
		print("Planting... waiting for growth")
		grow_plant_after_delay()
	else:
		print("Garden bed is already planted!")
		
func grow_plant_after_delay() -> void:
	# Ждём заданное время для имитации роста растения
	await get_tree().create_timer(growth_time).timeout
	grow_plant()
	
func grow_plant() -> void:
	if plant_scene:
		var plant_instance = plant_scene.instantiate()
		plant_instance.name = "Plant"
		body.add_child(plant_instance)
		
		# Получаем размер меша почвы для правильного позиционирования
		var soil_aabb = body.get_aabb()
		# Размещаем растение на поверхности почвы
		plant_instance.position = Vector3(0, soil_aabb.size.y / 2, 0)
		
		# Убедимся, что растение видно
		if plant_instance.has_method("set_visible"):
			plant_instance.visible = true
			
		print("Plant has grown! Global position: ", plant_instance.global_position)
		soil_parameters.has_plant = true
	else:
		print("No plant scene assigned!")


		
func harvest():
	# Ищем дочерний узел с именем "Plant" и удаляем его, симулируя сбор урожая
	for child in get_children():
		if child is MeshInstance3D and child.name == "Plant":
			child.queue_free()
			soil_parameters.is_sown = false
			soil_parameters.has_plant = false
			print("Plant harvested!")
			return
	print("No plant to harvest!")
	
func water_material(watered: bool):
	if watered:
		soil_material = body.material_override
		if soil_material == null:
			soil_material = StandardMaterial3D.new()
			body.material_override = soil_material
		# Пример: меняем цвет материала, чтобы визуально показать, что грядка полита
		soil_material.albedo_color = Color(0.205, 0.205, 0.205, 1)
		body.material_override = soil_material
