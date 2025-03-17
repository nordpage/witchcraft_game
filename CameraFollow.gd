# CameraFollow.gd - прикрепите к узлу Camera3D
extends Camera3D

@export var target_path: NodePath  # Путь к тележке
@export var smooth_speed: float = 5.0  # Скорость сглаживания
@export var position_offset: Vector3 = Vector3(0, 7, 15)  # Позади и выше
@export var look_offset: Vector3 = Vector3(0, 1, -2)      # Смотрим вперед и немного вверх

@onready var target = get_node_or_null(target_path)

func _process(delta):
	if target:
		# Вычисляем желаемую позицию камеры (позади тележки)
		var target_pos = target.global_transform.origin + target.global_transform.basis.x * position_offset.x + Vector3.UP * position_offset.y + target.global_transform.basis.z * position_offset.z

		# Плавно перемещаем камеру
		global_transform.origin = global_transform.origin.lerp(target_pos, smooth_speed * delta)

		# Заставляем камеру смотреть на тележку с небольшим смещением вперед
		var look_target = target.global_transform.origin + target.global_transform.basis.x * look_offset.x + Vector3.UP * look_offset.y + target.global_transform.basis.z * look_offset.z
		look_at(look_target, Vector3.UP)
