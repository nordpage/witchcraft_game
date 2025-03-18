extends RigidBody3D

@export var wheel_friction: float = 5.0  # Максимальное сцепление
@export var wheel_bounce: float = 0.0  # Убираем отскок

func _ready():
	var wheel_material = PhysicsMaterial.new()
	wheel_material.friction = wheel_friction
	wheel_material.bounce = wheel_bounce
	wheel_material.rough = true

	physics_material_override = wheel_material

	# **Гасим дрожание колёс**
	linear_damp = 2.0  # Сильно уменьшаем дрожание
	angular_damp = 5.0  # Уменьшаем вибрации и самопроизвольные повороты
