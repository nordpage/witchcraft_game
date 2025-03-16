extends StaticBody3D
@onready var body = $SoilBody  # body должен быть MeshInstance3D
# Сигнал, который отправляется при клике на грядку.
signal soil_clicked(soil, position)
# Экспорт параметров грядки (например, is_watered, is_sown, и опционально has_plant)
@export var soil_parameters: SoilData
# Сцена растения, которую будем инстанцировать после посадки
@export var plant_scene: PackedScene
# Время (в секундах) необходимое для роста растения
@export var growth_time: float = 5.0
var original_material: Material = null
var wet_material: StandardMaterial3D = null
@export var drying_time: float = 30.0
var drying_timer: Timer = null
var drying_progress: float = 0.0

func _ready():
	if soil_parameters:
		soil_parameters = soil_parameters.duplicate() as SoilData
	add_to_group("soil")
	
	drying_timer = Timer.new()
	drying_timer.one_shot = true
	drying_timer.wait_time = drying_time
	drying_timer.connect("timeout", Callable(self, "_on_drying_timer_timeout"))
	add_child(drying_timer)
	
	# Захватываем точную копию текущего материала
	if body.get_surface_override_material(0) != null:
		original_material = body.get_surface_override_material(0)
	elif body.material_override != null:
		original_material = body.material_override
	else:
		# Создаем стандартный материал, если отсутствует
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = Color(0.55, 0.27, 0.07, 1)
		original_material = new_mat
		body.material_override = original_material
	
	# Создаем "мокрый" материал на основе оригинального
	wet_material = StandardMaterial3D.new()
	if original_material is StandardMaterial3D:
		# Копируем все свойства из оригинального материала
		wet_material.albedo_texture = original_material.albedo_texture
		wet_material.normal_texture = original_material.normal_texture
		wet_material.roughness_texture = original_material.roughness_texture
		# Прочие свойства, если нужно
	wet_material.albedo_color = Color(0.205, 0.205, 0.205, 1)

func start_drying() -> void:
	if soil_parameters.is_watered:
		drying_timer.wait_time = drying_time * randf_range(0.8, 1.2)  # Добавляем немного случайности
		drying_timer.start()
		print("Soil is drying, will be dry in ", drying_timer.wait_time, " seconds")

# Остановка высыхания грядки
func stop_drying() -> void:
	drying_timer.stop()

# Обработчик завершения высыхания
func _on_drying_timer_timeout() -> void:
	soil_parameters.is_watered = false
	water_material(false)
	print("Soil is now dry")

func _input_event(camera: Camera3D, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		print("Soil clicked!")
		emit_signal("soil_clicked", self, event.position)
		
func water():
	if not soil_parameters.is_watered:
		soil_parameters.is_watered = true
		water_material(soil_parameters.is_watered)
		stop_drying()
		ResourceManager.add_resource("witch_fatigue", 0.1)
	else:
		print("Garden bed already watered!")
		
func plant():
	if not soil_parameters.is_sown:
		# Проверяем, есть ли семена
		if ResourceManager.remove_resource("seeds", 1):
			soil_parameters.is_sown = true
			print("Planting... waiting for growth")
			ResourceManager.add_resource("witch_fatigue", 0.1)
			grow_plant_after_delay()
		else:
			print("Not enough seeds!")
	else:
		print("Garden bed is already planted!")
		
func grow_plant_after_delay() -> void:
	var growth_modifier = 1.0
	
	# Проверяем погоду через singleton WeatherController
	var weather_controller = get_node("/root/WeatherController")
	if weather_controller and weather_controller.current_weather == weather_controller.WeatherType.RAIN:
		growth_modifier = 0.7  # Быстрее растет во время дождя
	
	# Модифицированное время роста
	var modified_time = growth_time * growth_modifier
	await get_tree().create_timer(modified_time).timeout
	grow_plant()
	
func grow_plant() -> void:
	if plant_scene:
		# Базовый шанс на успешный рост
		var growth_chance = 0.8
		
		# Увеличиваем шанс, если грядка полита
		if soil_parameters.is_watered:
			growth_chance += 0.15
		
		# Проверяем успешность роста
		if randf() <= growth_chance:
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
			print("Plant failed to grow!")
			soil_parameters.is_sown = false
	else:
		print("No plant scene assigned!")
		
func harvest():
	# Ищем дочерний узел с именем "Plant" среди дочерних элементов body
	for child in body.get_children():
		if child.name == "Plant":
			child.queue_free()
			soil_parameters.is_sown = false
			soil_parameters.has_plant = false
			print("Plant harvested!")
			# Сбрасываем состояние полива при сборе урожая
			stop_drying()
			soil_parameters.is_watered = false
			water_material(soil_parameters.is_watered)
			ResourceManager.add_resource("witch_fatigue", 0.1)
			ResourceManager.add_resource("plants", 1)
			return
	print("No plant to harvest!")
	
func water_material(watered: bool):
	if watered:
		# Применяем материал для политой почвы
		body.material_override = wet_material
	else:
		# Возвращаем оригинальный материал
		body.material_override = original_material
	
	soil_parameters.is_watered = watered
	
func _process(delta: float) -> void:
	# Если таймер активен, обновляем визуальный прогресс высыхания
	if drying_timer.is_stopped() == false && soil_parameters.is_watered:
		drying_progress = 1.0 - (drying_timer.time_left / drying_timer.wait_time)
		update_drying_visual()
			
func update_drying_visual() -> void:
	if soil_parameters.is_watered:
		# Постепенно изменяем цвет от мокрого к сухому
		var current_color = wet_material.albedo_color.lerp(
			original_material.albedo_color if original_material is StandardMaterial3D else Color(0.55, 0.27, 0.07, 1), 
			drying_progress
		)
		body.material_override.albedo_color = current_color
