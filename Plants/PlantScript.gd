extends Node3D

# Переменные для роста и идентификации
var plant_type: String = ""
var current_growth_stage: int = 0
var max_growth_stages: int = 4

# Ссылки на узлы
@onready var growth_particles = $Effects/GrowthParticles
@onready var idle_particles = $Effects/IdleParticles
@onready var models = $Models

# Вызывается при добавлении растения в сцену
func _ready():
	# Отключаем частицы при запуске
	if growth_particles:
		growth_particles.emitting = false
	
	if idle_particles:
		idle_particles.emitting = false
	
	# По умолчанию показываем только первую стадию
	if models:
		for i in range(1, max_growth_stages + 1):
			var model_node = models.get_node_or_null("Stage" + str(i))
			if model_node:
				model_node.visible = (i == 1)

# Устанавливает тип растения и настраивает эффекты
func initialize(new_plant_type: String):
	plant_type = new_plant_type
	
	# Настраиваем эффекты частиц
	if growth_particles:
		setup_growth_particles()
	
	if idle_particles:
		setup_idle_particles()
	
	# Обновляем подсказку для интерактивности, если это нужно
	update_tooltip()

# Настройка частиц роста
func setup_growth_particles():
	# Проверяем, существует ли материал частиц
	if not growth_particles.process_material:
		var material = ParticleProcessMaterial.new()
		growth_particles.process_material = material
		
	# Получаем материал частиц
	var material = growth_particles.process_material
	
	# Настройки базовых параметров
	growth_particles.amount = 50
	growth_particles.lifetime = 2.0
	growth_particles.explosiveness = 0.8
	growth_particles.one_shot = true
	
	# Настройки материала частиц (в зависимости от типа растения)
	if material is ParticleProcessMaterial:
		# Форма эмиссии и направление
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		material.emission_sphere_radius = 0.2
		material.direction = Vector3(0, 1, 0)
		material.spread = 45.0
		
		# Физика частиц
		material.gravity = Vector3(0, -0.5, 0)
		material.initial_velocity_min = 1.0
		material.initial_velocity_max = 2.0
		
		# Размер частиц
		material.scale_min = 0.05
		material.scale_max = 0.15
		
		# Цвет частиц - настраивается для каждого растения
		match plant_type:
			"witchs_thimbles":
				material.color = Color(0.6, 0.3, 0.9, 0.8)  # Фиолетовый блеск
			"purple_rebel":
				material.color = Color(0.4, 0.1, 0.8, 0.8)  # Темно-фиолетовый
			"trolls_grin":
				material.color = Color(0.2, 0.8, 0.3, 0.8)  # Зеленый
			"blazing_splinter":
				material.color = Color(0.9, 0.3, 0.1, 0.8)  # Красно-оранжевый
			"cunning_cabbage":
				material.color = Color(0.3, 0.9, 0.4, 0.8)  # Светло-зеленый
			"mermaids_tendrils":
				material.color = Color(0.1, 0.8, 0.6, 0.8)  # Бирюзовый
			_:
				material.color = Color(0.5, 0.8, 0.5, 0.8)  # Стандартный зеленый

# Настройка постоянных частиц
func setup_idle_particles():
	# Проверяем, существует ли материал частиц
	if not idle_particles.process_material:
		var material = ParticleProcessMaterial.new()
		idle_particles.process_material = material

	# Отключаем на старте, включим когда растение вырастет
	idle_particles.emitting = false
	
	# Базовые настройки в зависимости от типа растения
	match plant_type:
		"witchs_thimbles":
			idle_particles.amount = 15
			idle_particles.lifetime = 3.5
			# Частицы медленно поднимаются и мерцают
			var material = idle_particles.process_material
			if material is ParticleProcessMaterial:
				material.gravity = Vector3(0, 0.08, 0)
				material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
				material.emission_sphere_radius = 0.25
			
		"purple_rebel":
			idle_particles.amount = 12
			idle_particles.lifetime = 2.8
			# Электрическое свечение вокруг шишечек
			var material = idle_particles.process_material
			if material is ParticleProcessMaterial:
				material.gravity = Vector3(0, 0.03, 0)
				material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
				material.emission_box_extents = Vector3(0.2, 0.2, 0.2)
			
		"trolls_grin":
			idle_particles.amount = 8
			idle_particles.lifetime = 4.0
			# Редкие капли зеленой слизи
			var material = idle_particles.process_material
			if material is ParticleProcessMaterial:
				material.gravity = Vector3(0, -0.15, 0)  # Падают вниз
				material.initial_velocity_min = 0.01
				material.initial_velocity_max = 0.05
				material.scale_min = 0.03
				material.scale_max = 0.08
			
		"blazing_splinter":
			idle_particles.amount = 25
			idle_particles.lifetime = 1.8
			# Тлеющие частицы огня
			var material = idle_particles.process_material
			if material is ParticleProcessMaterial:
				material.gravity = Vector3(0, 0.2, 0)
				# Заменяем material.damping на правильное свойство
				material.damping_min = 0.1  # Минимальное затухание
				material.damping_max = 0.3  # Максимальное затухание
				material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
				material.emission_sphere_radius = 0.3
			
		"cunning_cabbage":
			idle_particles.amount = 10
			idle_particles.lifetime = 3.2
			# Зеленоватое свечение и пыльца
			var material = idle_particles.process_material
			if material is ParticleProcessMaterial:
				material.gravity = Vector3(0, 0.04, 0)
				material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
				material.emission_sphere_radius = 0.3
				material.scale_min = 0.02
				material.scale_max = 0.04
			
		"mermaids_tendrils":
			idle_particles.amount = 18
			idle_particles.lifetime = 2.5
			# Водоподобные частицы, стекающие по листьям
			var material = idle_particles.process_material
			if material is ParticleProcessMaterial:
				material.gravity = Vector3(0, -0.1, 0)
				material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
				material.emission_sphere_radius = 0.2
				material.initial_velocity_min = 0.05
				material.initial_velocity_max = 0.15
			
		_:
			# Стандартные настройки для любого другого типа
			idle_particles.amount = 15
			idle_particles.lifetime = 3.0
			var material = idle_particles.process_material
			if material is ParticleProcessMaterial:
				material.gravity = Vector3(0, 0.05, 0)
				material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
				material.emission_sphere_radius = 0.3
	
	# Общие настройки для всех
	idle_particles.local_coords = true
	
	# Настройка цветовых градиентов для разных растений
	var material = idle_particles.process_material
	if material is ParticleProcessMaterial:
		match plant_type:
			"witchs_thimbles":
				material.color = Color(0.6, 0.4, 1.0, 0.3)
			"purple_rebel":
				material.color = Color(0.4, 0.2, 0.9, 0.35)
			"trolls_grin":
				material.color = Color(0.3, 0.8, 0.3, 0.4)
			"blazing_splinter":
				material.color = Color(1.0, 0.7, 0.3, 0.4)
			"cunning_cabbage":
				material.color = Color(0.3, 0.9, 0.4, 0.25)
			"mermaids_tendrils":
				material.color = Color(0.2, 0.7, 0.9, 0.3)
			_:
				# Стандартный зеленый градиент для неизвестных типов
				material.color = Color(0.4, 0.8, 0.4, 0.2)

# Устанавливает стадию роста растения
func set_growth_stage(stage: int):
	current_growth_stage = clamp(stage, 0, max_growth_stages)
	
	# Обновляем видимость моделей
	update_models()
	
	# Запускаем эффект роста при переходе к новой стадии
	if growth_particles and stage > 0:
		growth_particles.restart()
		growth_particles.emitting = true
	
	# Включаем эффект состояния покоя только на последней стадии
	if idle_particles:
		idle_particles.emitting = (stage == max_growth_stages)

# Обновляет видимость моделей в зависимости от стадии роста
func update_models():
	if models:
		for i in range(1, max_growth_stages + 1):
			var model_node = models.get_node_or_null("Stage" + str(i))
			if model_node:
				model_node.visible = (i == current_growth_stage)

# Обновляет подсказку для интерактивности (если используется система интерактивных объектов)
func update_tooltip():
	if has_method("set_interaction_hint"):
		# Это для совместимости с вашей системой интерактивных объектов
		match plant_type:
			"witchs_thimbles":
				call("set_interaction_hint", "Собрать Ведьмины Наперстки")
			"purple_rebel":
				call("set_interaction_hint", "Собрать Пурпурный Бунтарь")
			"trolls_grin":
				call("set_interaction_hint", "Собрать Ухмылку Тролля")
			"blazing_splinter":
				call("set_interaction_hint", "Собрать Пылающую Занозу")
			"cunning_cabbage":
				call("set_interaction_hint", "Собрать Хитрый Кочан")
			"mermaids_tendrils":
				call("set_interaction_hint", "Собрать Щупальца Русалки")
			_:
				call("set_interaction_hint", "Собрать растение")

# Запускает анимацию сбора урожая
func play_harvest_animation():
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation("collect"):
		anim_player.play("collect")
		return true
	return false
