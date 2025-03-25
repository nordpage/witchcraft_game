class_name InteractiveObject
extends StaticBody3D

# Свойства подсветки
@export var can_highlight: bool = true
@export var highlight_color: Color = Color(0.0, 0.5, 1.0, 1.0)  # Цвет подсветки
@export var highlight_intensity: float = 0.3  # Интенсивность подсветки
@export var mesh_paths: Array[NodePath] = []  # Пути к мешам внутри иерархии объекта

# Свойства взаимодействия
@export var interaction_distance: float = 3.0
@export_multiline var default_hint_text: String = "Взаимодействовать"

# Приватные свойства
var _mesh_instances: Array = []
var is_highlighted: bool = false
var _highlight_shader: Shader
var _tween: Tween

func _ready():
	add_to_group("interactive_objects")
	
	# Загружаем шейдер
	_highlight_shader = load_highlight_shader()
	
	# Если массив путей к мешам пуст, пытаемся найти все мешы автоматически
	if mesh_paths.is_empty():
		_find_all_meshes(self)
	else:
		# Используем указанные пути
		for path in mesh_paths:
			var mesh_node = get_node_or_null(path)
			if mesh_node and mesh_node is MeshInstance3D:
				_mesh_instances.append(mesh_node)
	
	# Настраиваем шейдерные материалы для всех найденных мешей
	_setup_shader_materials()
	
	print("InteractiveObject initialized with ", _mesh_instances.size(), " meshes")

# Рекурсивно ищет все мешинстансы внутри объекта
func _find_all_meshes(node):
	for child in node.get_children():
		if child is MeshInstance3D:
			_mesh_instances.append(child)
		if child.get_child_count() > 0:
			_find_all_meshes(child)

# Создает и возвращает шейдер подсветки
func load_highlight_shader() -> Shader:
	var shader_code = """
	shader_type spatial;
	
	uniform vec4 albedo : source_color = vec4(1.0);
	uniform sampler2D albedo_texture : source_color;
	uniform vec4 highlight_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
	uniform float highlight_amount : hint_range(0.0, 1.0) = 0.0;
	
	void fragment() {
		vec4 tex_color = texture(albedo_texture, UV);
		
		// Сохраняем оригинальный цвет и прозрачность
		ALBEDO = mix(tex_color.rgb * albedo.rgb, tex_color.rgb, highlight_amount * 0.3);
		
		// Добавляем эмиссию для подсветки
		EMISSION = highlight_color.rgb * highlight_amount * 0.5;
		
		// Поддерживаем альфа-прозрачность из текстуры, если она есть
		ALPHA = tex_color.a;
	}
	"""
	
	var shader = Shader.new()
	shader.code = shader_code
	return shader

# Настраивает шейдерные материалы для всех мешей
func _setup_shader_materials():
	for mesh in _mesh_instances:
		if not mesh or not mesh.mesh:
			continue
			
		for surface_idx in range(mesh.get_surface_override_material_count()):
			var original_material = mesh.get_surface_override_material(surface_idx)
			
			# Если нет переопределенного материала, пробуем получить из меша
			if not original_material and mesh.mesh.get_surface_count() > surface_idx:
				original_material = mesh.mesh.surface_get_material(surface_idx)
			
			# Если до сих пор нет материала, создаем стандартный
			if not original_material:
				original_material = StandardMaterial3D.new()
			
			# Создаем шейдерный материал
			var shader_material = ShaderMaterial.new()
			shader_material.shader = _highlight_shader
			
			# Устанавливаем базовые параметры
			shader_material.set_shader_parameter("highlight_amount", 0.0)
			shader_material.set_shader_parameter("highlight_color", highlight_color)
			
			# Копируем свойства из оригинального материала
			if original_material is StandardMaterial3D:
				shader_material.set_shader_parameter("albedo", original_material.albedo_color)
				
				# Создаем белую текстуру по умолчанию, если нет оригинальной
				var default_texture = Texture2D.new()
				
				if original_material.albedo_texture:
					shader_material.set_shader_parameter("albedo_texture", original_material.albedo_texture)
				else:
					# Создаем белую текстуру 2x2 пикселя
					var image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
					image.fill(Color(1, 1, 1, 1))
					var texture = ImageTexture.create_from_image(image)
					shader_material.set_shader_parameter("albedo_texture", texture)
				
				# Настраиваем прозрачность, если это нужно
				if original_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					shader_material.render_priority = original_material.render_priority
			
			# Применяем шейдерный материал
			mesh.set_surface_override_material(surface_idx, shader_material)

# Основной метод для получения подсказки при наведении
func get_interaction_hint() -> String:
	return default_hint_text

# Метод, вызываемый при взаимодействии с объектом
func interact() -> void:
	print("Base interaction with ", name)
	# Переопределите этот метод в дочерних классах

# Методы подсветки с использованием твинов для плавности
func highlight() -> void:
	if not can_highlight or is_highlighted or _mesh_instances.is_empty():
		return
	
	is_highlighted = true
	
	# Отменяем предыдущий твин, если он был
	if _tween != null and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	for mesh in _mesh_instances:
		if not mesh:
			continue
			
		for surface_idx in range(mesh.get_surface_override_material_count()):
			var material = mesh.get_surface_override_material(surface_idx)
			if material is ShaderMaterial:
				_tween.tween_method(
					func(val): material.set_shader_parameter("highlight_amount", val),
					0.0,  # Начальное значение
					1.0,  # Конечное значение
					0.3   # Продолжительность в секундах
				)

func unhighlight() -> void:
	if not can_highlight or not is_highlighted or _mesh_instances.is_empty():
		return
	
	is_highlighted = false
	
	# Отменяем предыдущий твин, если он был
	if _tween != null and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	for mesh in _mesh_instances:
		if not mesh:
			continue
			
		for surface_idx in range(mesh.get_surface_override_material_count()):
			var material = mesh.get_surface_override_material(surface_idx)
			if material is ShaderMaterial:
				_tween.tween_method(
					func(val): material.set_shader_parameter("highlight_amount", val),
					material.get_shader_parameter("highlight_amount"),  # Текущее значение
					0.0,  # Конечное значение
					0.3   # Продолжительность в секундах
				)
