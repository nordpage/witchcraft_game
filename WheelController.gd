# WheelController.gd - прикрепите к каждому RigidBody3D колеса
extends RigidBody3D

@export var wheel_friction: float = 1.5
@export var wheel_bounce: float = 0.3

func _ready():
	# Создаем физический материал для колеса
	var wheel_material = PhysicsMaterial.new()
	wheel_material.friction = wheel_friction
	wheel_material.bounce = wheel_bounce
	wheel_material.rough = true

	# Применяем материал
	physics_material_override = wheel_material

	# Настраиваем другие параметры колеса
	custom_integrator = false
	linear_damp = 0.1
	angular_damp = 0.1

	# Вращаем меш колеса, если необходимо
	# (в зависимости от того, как ориентирован ваш меш)
	for child in get_children():
		if child is MeshInstance3D:
			# Проверьте и настройте ориентацию меша по необходимости
			pass
