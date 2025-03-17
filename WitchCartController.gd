# WitchCartController.gd - прикрепите к RigidBody3D witch_cart
extends RigidBody3D

@export var max_speed: float = 5.0
@export var engine_force: float = 50.0
@export var steering_angle: float = 0.5  # В радианах (~28 градусов)

# Ссылки на колеса
@onready var wheel_fl: RigidBody3D = $"../WheelFrontLeft"
@onready var wheel_fr: RigidBody3D = $"../WheelFrontRight"
@onready var wheel_bl: RigidBody3D = $"../WheelBackLeft"
@onready var wheel_br: RigidBody3D = $"../WheelBackRight"

# Ссылки на все шарниры
@onready var hinge_fl: HingeJoint3D = $"../HingeJoint_FL"
@onready var hinge_fr: HingeJoint3D = $"../HingeJoint_FR"
@onready var hinge_bl: HingeJoint3D = $"../HingeJoint_BL"
@onready var hinge_br: HingeJoint3D = $"../HingeJoint_BR"

# Управляющие параметры
var speed_input: float = 0.0
var steering_input: float = 0.0

# Сигнал о движении для других систем
signal is_moving(state)

func _ready():
	# Настройка физики тележки
	add_to_group("cart")
	axis_lock_angular_x = true
	axis_lock_angular_z = true

	# Настраиваем физические параметры
	mass = 200.0
	linear_damp = 0.3
	angular_damp = 1.5

	# Создаем физический материал для тележки
	var cart_material = PhysicsMaterial.new()
	cart_material.friction = 1.0
	cart_material.rough = true
	cart_material.bounce = 0.1
	physics_material_override = cart_material

	for child in get_parent().get_children():
		if child.name.begins_with("Wheel"):
			child.set_collision_layer_value(1, false)  # Колёса не сталкиваются с тележкой
			child.set_collision_mask_value(1, false)

	# Смещаем центр масс вниз (делаем тележку устойчивее)
	set_center_of_mass(Vector3(0, -2, 0))

	# Настраиваем задние шарниры
	setup_rear_hinges()

func _physics_process(delta):
	# Применяем двигательные силы к колесам
	apply_motor_forces()

	# Обрабатываем рулевое управление
	handle_steering()

	# Добавляем небольшую прижимающую силу для лучшего сцепления
	apply_downforce()

	# Отправляем сигнал о состоянии движения
	var is_cart_moving = linear_velocity.length() > 0.5
	emit_signal("is_moving", is_cart_moving)

	# Добавляем усталость ведьме при движении
	if is_cart_moving:
		var fatigue_amount = delta * 0.01 * linear_velocity.length() / max_speed
		WitchFatigue.add_fatigue(fatigue_amount)

# Настройка задних шарниров
func setup_rear_hinges():
	if hinge_bl and hinge_br:
		hinge_bl.set("axis", Vector3(0,1,0))  # Задаём ось вращения
		hinge_br.set("axis", Vector3(0,1,0))  # Задаём ось вращения

		hinge_bl.set_param(HingeJoint3D.PARAM_BIAS, 0.9)
		hinge_br.set_param(HingeJoint3D.PARAM_BIAS, 0.9)

# Применяем двигательные силы к колесам
func apply_motor_forces():
	if abs(speed_input) > 0.05:
		# Вычисляем силу на основе ввода
		var drive_force = speed_input * engine_force

		# Применяем силу **только к задним колёсам**
		apply_wheel_force(wheel_bl, drive_force)
		apply_wheel_force(wheel_br, drive_force)

# Применяем силу к отдельному колесу
func apply_wheel_force(wheel: RigidBody3D, force: float):
	if wheel:
		# Вычисляем направление "вперед" для колеса
		var forward_dir = -wheel.global_transform.basis.z

		# Применяем силу
		wheel.apply_central_force(forward_dir * force)

# Обрабатываем рулевое управление
func handle_steering():
	if hinge_fl and hinge_fr:
		var steer_angle = steering_input * steering_angle

		hinge_fl.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, steer_angle - 0.1)  # Даем запас
		hinge_fl.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, steer_angle + 0.1)

		hinge_fr.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, steer_angle - 0.1)
		hinge_fr.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, steer_angle + 0.1)

		hinge_fl.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
		hinge_fr.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)

		# Включаем мотор для передних колёс
		hinge_fl.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, steer_angle * 2)
		hinge_fr.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, steer_angle * 2)

		hinge_fl.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		hinge_fr.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)

# Устанавливаем угол шарнира
func set_hinge_angle(hinge: HingeJoint3D, angle: float):
	# Настраиваем верхний и нижний пределы с небольшим допуском
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, angle - 0.01)
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, angle + 0.01)

	# Убеждаемся, что ограничения включены
	hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)

# Добавляем прижимающую силу для лучшего сцепления
func apply_downforce():
	# Дополнительная сила вниз для лучшего сцепления при движении
	if linear_velocity.length() > 0.1:
		var down_force = Vector3(0, -9.8 * mass * 0.2, 0)  # 20% от веса
		apply_central_force(down_force)

# Метод для получения ввода от UI слайдера
func set_speed_input(value: float):
	speed_input = value

# Метод для получения ввода руления от UI слайдера
func set_steering_input(value: float):
	steering_input = value

# Обработка входных данных (опционально, если есть прямой контроль с клавиатуры)
func _input(event):
	# Пример обработки клавиатуры (можно удалить, если используется только UI)
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_W:
				speed_input = 1.0
			elif event.keycode == KEY_S:
				speed_input = -1.0
			elif event.keycode == KEY_A:
				steering_input = -1.0
			elif event.keycode == KEY_D:
				steering_input = 1.0
		else:  # Клавиша отпущена
			if event.keycode == KEY_W or event.keycode == KEY_S:
				speed_input = 0.0
			elif event.keycode == KEY_A or event.keycode == KEY_D:
				steering_input = 0.0
