extends InteractiveObject

@onready var body = $SoilBody
signal soil_clicked(soil, position, soil_parameters)

@export var soil_parameters: SoilData
@export var plant_options: Dictionary = {
	"witchs_thimbles": {
		"name_ru": "Ведьмины Наперстки",
		"name_en": "Witch's Thimbles",
		"scene": preload("res://Plants/WitchsThimbles/WitchsThimbles.tscn"),
		"growth_time": 30.0,
		"growth_chance": 0.85
	},
	"purple_rebel": {
		"name_ru": "Пурпурный Бунтарь",
		"name_en": "Purple Rebel",
		"scene": preload("res://Plants/PurpleRebel/PurpleRebel.tscn"),
		"growth_time": 36.0,
		"growth_chance": 0.8
	},
	"trolls_grin": {
		"name_ru": "Ухмылка Тролля",
		"name_en": "Troll's Grin",
		"scene": preload("res://Plants/TrollsGrin/TrollsGrin.tscn"),
		"growth_time": 42.0,
		"growth_chance": 0.9
	},
	"blazing_splinter": {
		"name_ru": "Пылающая Заноза",
		"name_en": "Blazing Splinter",
		"scene": preload("res://Plants/BlazingSplinter/BlazingSplinter.tscn"),
		"growth_time": 24.0,
		"growth_chance": 0.88
	},
	"cunning_cabbage": {
		"name_ru": "Хитрый Кочан",
		"name_en": "Cunning Cabbage",
		"scene": preload("res://Plants/CunningCabbage/CunningCabbage.tscn"),
		"growth_time": 33,
		"growth_chance": 0.82
	},
	"mermaids_tendrils": {
		"name_ru": "Щупальца Русалки",
		"name_en": "Mermaid's Tendrils",
		"scene": preload("res://Plants/MermaidsTendrils/MermaidsTendrils.tscn"),
		"growth_time": 39,
		"growth_chance": 0.77
	}
}

var drying_timer: Timer = null

func _ready():
	# Вызываем метод родительского класса
	super._ready()
	
	add_to_group("soil")
	drying_timer = Timer.new()
	drying_timer.one_shot = true
	add_child(drying_timer)
	
	# Устанавливаем начальную подсказку
	default_hint_text = get_interaction_hint()

func get_interaction_hint() -> String:
	if not soil_parameters.is_sown:
		return "Посадить"
	elif soil_parameters.has_plant:
		return "Собрать"
	elif not soil_parameters.is_watered:
		return "Полить"
	else:
		return "Подождать"
		
func interact() -> void:
	if not soil_parameters.is_sown:
		# Открываем меню выбора растения
		var plant_menu = get_node_or_null("/root/MainScene/CanvasLayer/PlantSelectionMenu")
		if plant_menu:
			plant_menu.show_for_soil(self)
		else:
			print("Plant selection menu not found!")
	elif soil_parameters.has_plant:
		# Собираем выросшее растение напрямую
		collect_plant()
	elif not soil_parameters.is_watered:
		# Поливаем растение
		water_plant()
	else:
		# Просто информируем пользователя
		print("Растение растет... Нужно подождать.")
		
func water_plant():
	# Проверяем, есть ли у игрока вода
	if ResourceManager.get_resource("water") > 0:
		soil_parameters.is_watered = true
		ResourceManager.remove_resource("water", 1)
		print("Watering plant...")
		
		# Запускаем таймер высыхания
		if drying_timer:
			drying_timer.stop()
			drying_timer.wait_time = 60.0  # 60 секунд до высыхания
			drying_timer.one_shot = true
			drying_timer.start()
			if not drying_timer.is_connected("timeout", Callable(self, "_on_drying_timer_timeout")):
				drying_timer.connect("timeout", Callable(self, "_on_drying_timer_timeout"))
			
		# Добавляем немного усталости
		WitchFatigue.add_fatigue(0.05)
		
		# Проверяем, нужно ли ускорить рост из-за полива
		if soil_parameters.is_sown and not soil_parameters.has_plant:
			accelerate_growth()
			
		# Обновляем подсказку
		default_hint_text = get_interaction_hint()
	else:
		print("You need water to water the plants!")

func _on_drying_timer_timeout():
	soil_parameters.is_watered = false
	print("Soil has dried out")
	
	# Обновляем визуальное состояние грядки
	update_soil_appearance()
	
	# Обновляем подсказку
	default_hint_text = get_interaction_hint()
	
func update_soil_appearance():
	# Обновляем внешний вид грядки в зависимости от состояния
	if body:
		var material = body.get_surface_override_material(0)
		if material and material is StandardMaterial3D:
			if soil_parameters.is_watered:
				# Темная, влажная почва
				material.albedo_color = Color(0.3, 0.2, 0.1)
			else:
				# Сухая почва
				material.albedo_color = Color(0.6, 0.4, 0.2)
			
			if soil_parameters.is_fertilized:
				# Немного другой оттенок для удобренной почвы
				material.albedo_color.r -= 0.1
				material.albedo_color.g += 0.05

func accelerate_growth():
	# Ускоряем рост на 20% при поливе
	# Это логика для "скрытого" роста, который уже запущен
	print("Growth accelerated due to watering")
	# Реализация будет зависеть от вашей системы роста
		
func collect_plant():
	if soil_parameters.has_plant:
		print("Collecting plant:", soil_parameters.current_plant)
		
		# Находим растение
		var plant_node = body.get_node_or_null("Plant")
		if plant_node:
			# Проверяем, использует ли растение новый скрипт
			var animation_played = false
			if plant_node.has_method("play_harvest_animation"):
				animation_played = plant_node.play_harvest_animation()
				if animation_played:
					# Ждем завершения анимации перед удалением
					var anim_player = plant_node.get_node("AnimationPlayer")
					await anim_player.animation_finished
			
			# Если новая анимация не воспроизводилась, пробуем старый способ
			if not animation_played and plant_node.has_node("AnimationPlayer"):
				var anim_player = plant_node.get_node("AnimationPlayer")
				if anim_player.has_animation("collect"):
					anim_player.play("collect")
					# Ждем завершения анимации перед удалением
					await anim_player.animation_finished
			
			# Удаляем растение
			plant_node.queue_free()
		
		# Определяем количество собираемого урожая (может зависеть от удобрений и других факторов)
		var yield_amount = 1
		if soil_parameters.is_fertilized:
			yield_amount += 1
		
		# Добавляем растение в инвентарь
		ResourceManager.add_resource("plants", yield_amount)
		ResourceManager.add_resource(soil_parameters.current_plant, yield_amount)
		
		# Возможно, получаем семена
		var seed_chance = 0.5  # 50% шанс получить семена
		if randf() <= seed_chance:
			ResourceManager.add_resource("seeds", 1)
			print("You got a seed!")
		
		# Сбрасываем состояние почвы
		soil_parameters.has_plant = false
		soil_parameters.is_sown = false
		soil_parameters.is_watered = false
		soil_parameters.current_plant = ""
		
		# Добавляем усталость
		WitchFatigue.add_fatigue(0.05)
		
		# Обновляем внешний вид грядки
		update_soil_appearance()
		
		# Обновляем подсказку
		default_hint_text = get_interaction_hint()
	else:
		print("Nothing to collect!")

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
			
			# Создаем временную модель ростка
			var seedling = MeshInstance3D.new()
			seedling.name = "SeedlingMesh"
			var mesh = SphereMesh.new()
			mesh.radius = 0.1
			mesh.height = 0.2
			seedling.mesh = mesh
			body.add_child(seedling)
			seedling.position = Vector3(0, body.get_aabb().size.y / 2, 0)
			
			# Материал ростка
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.1, 0.5, 0.1)  # Зеленый цвет
			seedling.material_override = material
			
			grow_plant_after_delay(plant_data)
			
			# Обновляем подсказку
			default_hint_text = get_interaction_hint()
		else:
			print("Not enough seeds!")

func grow_plant_after_delay(plant_data: Dictionary) -> void:
	# Установка начальных параметров
	soil_parameters.growth_stage = 0
	soil_parameters.growth_progress = 0.0
	
	# Расчет модификатора времени роста (как раньше)
	var growth_modifier = 1.0
	
	# (Код проверки модификаторов остается прежним)
	
	# Сразу создаем экземпляр растения
	var plant_instance = plant_data.scene.instantiate()
	plant_instance.name = "Plant"
	body.add_child(plant_instance)
	plant_instance.position = Vector3(0, body.get_aabb().size.y / 2, 0)
	
	# Инициализируем растение
	if plant_instance.has_method("initialize"):
		plant_instance.initialize(soil_parameters.current_plant)
	
	# Обязательно устанавливаем начальную стадию (стадия 1)
	if plant_instance.has_method("set_growth_stage"):
		plant_instance.set_growth_stage(1)
	else:
		# Если растение не использует новый скрипт, просто делаем его видимым
		plant_instance.visible = true
	
	# Удаляем временную модель ростка
	var seedling = body.get_node_or_null("SeedlingMesh")
	if seedling:
		seedling.queue_free()
	
	# Настраиваем время и шаги роста
	var modified_time = plant_data.growth_time * growth_modifier
	var growth_steps = 4  # Всего 4 стадии роста
	var time_per_step = modified_time / growth_steps
	
	# Ждем между стадиями роста (стадия 1 уже установлена)
	for i in range(1, growth_steps):
		# Ждем до следующей стадии
		await get_tree().create_timer(time_per_step).timeout
		
		# Обновляем стадию роста в параметрах
		soil_parameters.growth_stage = i + 1
		soil_parameters.growth_progress = float(i + 1) / growth_steps
		
		# Обновляем визуальное представление
		if plant_instance.has_method("set_growth_stage"):
			plant_instance.set_growth_stage(i + 1)
		
		print("Plant growth stage:", soil_parameters.growth_stage, 
			  ", Progress:", soil_parameters.growth_progress * 100, "%")
	
	# Проверка успешности роста после всех стадий
	if randf() > plant_data.growth_chance:
		# Растение не выросло - удаляем его
		plant_instance.queue_free()
		
		print("Plant failed to grow!")
		soil_parameters.is_sown = false
		soil_parameters.growth_stage = 0
		soil_parameters.growth_progress = 0.0
	else:
		# Растение успешно выросло
		soil_parameters.has_plant = true
		print("Plant has grown successfully:", plant_data.name_ru)
	
	# Обновляем внешний вид и подсказку
	update_soil_appearance()
	default_hint_text = get_interaction_hint()

func complete_growth(plant_data: Dictionary) -> void:
	# Удаляем временную модель ростка
	var seedling = body.get_node_or_null("SeedlingMesh")
	if seedling:
		seedling.queue_free()
		
	if randf() <= plant_data.growth_chance:
		# Растение успешно выросло
		var plant_instance = plant_data.scene.instantiate()
		plant_instance.name = "Plant"
		body.add_child(plant_instance)
		
		# Настраиваем положение растения
		plant_instance.position = Vector3(0, body.get_aabb().size.y / 2, 0)
		
		# Инициализируем растение с помощью нового скрипта
		if plant_instance.has_method("initialize"):
			# Передаем тип растения для настройки эффектов
			plant_instance.initialize(soil_parameters.current_plant)
			# Установка стадии роста на 4 (финальную)
			if plant_instance.has_method("set_growth_stage"):
				plant_instance.set_growth_stage(4)
		else:
			# Для обратной совместимости со старыми растениями
			plant_instance.visible = true
			
		print("Plant has grown:", plant_data.name_ru)
		soil_parameters.has_plant = true
		
		# Создаем эффект роста
		create_growth_particles()
	else:
		# Растение не выросло
		print("Plant failed to grow!")
		soil_parameters.is_sown = false
		soil_parameters.growth_stage = 0
		soil_parameters.growth_progress = 0.0
	
	# Обновляем внешний вид
	update_soil_appearance()
	
	# Обновляем подсказку
	default_hint_text = get_interaction_hint()

func create_growth_particles():
	# Создаем новую систему частиц
	var particles = GPUParticles3D.new()
	body.add_child(particles)
	
	# Настраиваем положение
	particles.position = Vector3(0, body.get_aabb().size.y / 2, 0)
	
	# Создаем материал для частиц
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.3
	material.direction = Vector3(0, 1, 0)
	material.spread = 45.0
	material.gravity = Vector3(0, -0.5, 0)
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 2.0
	material.scale_min = 0.05
	material.scale_max = 0.1
	material.color = Color(0.2, 0.8, 0.3, 0.8)  # Зеленоватый цвет для роста
	
	# Назначаем материал частицам
	particles.process_material = material
	
	# Создаем меш для частиц (простой квадрат)
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.1, 0.1)
	particles.draw_pass_1 = quad_mesh
	
	# Настраиваем параметры эмиттера
	particles.amount = 30
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.emitting = true
	
	# Автоматически удаляем систему частиц после завершения
	await get_tree().create_timer(particles.lifetime + 0.5).timeout
	particles.queue_free()

func update_growth_appearance():
	# Например, можно менять размер или текстуру саженца
	var plant_node = body.get_node_or_null("SeedlingMesh")
	if plant_node:
		var scale_factor = 0.5 + (soil_parameters.growth_progress * 0.5)
		plant_node.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Меняем цвет по мере роста (от светло-зеленого к темно-зеленому)
		if plant_node.material_override is StandardMaterial3D:
			var material = plant_node.material_override
			var green_intensity = 0.5 + soil_parameters.growth_progress * 0.3
			material.albedo_color = Color(0.1, green_intensity, 0.1)

# Этот метод оставлен для обратной совместимости
# Рекомендуется использовать grow_plant_after_delay вместо него
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
		
		# Обновляем подсказку
		default_hint_text = get_interaction_hint()
	else:
		print("Plant failed to grow!")
		soil_parameters.is_sown = false
		
		# Обновляем подсказку
		default_hint_text = get_interaction_hint()
		
func fertilize():
	if ResourceManager.get_resource("fertilizer") > 0 and !soil_parameters.is_fertilized:
		ResourceManager.remove_resource("fertilizer", 1)
		soil_parameters.is_fertilized = true
		print("Applied fertilizer")
		
		# Визуальное обновление
		update_soil_appearance()
		
		# Если растение уже растет, ускоряем его рост
		if soil_parameters.is_sown and !soil_parameters.has_plant:
			accelerate_growth()
			
		# Небольшая усталость
		WitchFatigue.add_fatigue(0.03)
		
		return true
	elif soil_parameters.is_fertilized:
		print("Already fertilized!")
	else:
		print("You don't have any fertilizer!")
	
	return false
