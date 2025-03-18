# В WheelController.gd
extends RigidBody3D

@export var wheel_friction: float = 5.0
@export var wheel_bounce: float = 0.0

func _ready():
	# Увеличиваем массу колеса для соответствия размеру
	mass = 50.0  # Для обычных колес это было бы около 10 кг

	var wheel_material = PhysicsMaterial.new()
	wheel_material.friction = wheel_friction
	wheel_material.bounce = wheel_bounce
	wheel_material.rough = true

	physics_material_override = wheel_material

	linear_damp = 2.0
	angular_damp = 5.0
