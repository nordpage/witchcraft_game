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
		# Задаем фиксированные ограничения для задних колес (только вращение)
		set_hinge_angle(hinge_bl, 0)  # Фиксируем в прямом положении
		set_hinge_angle(hinge_br, 0)  # Фиксируем в прямом положении

		# Дополнительные настройки для стабильности
		hinge_bl.set_param(HingeJoint3D.PARAM_BIAS, 0.9)
		hinge_br.set_param(HingeJoint3D.PARAM_BIAS, 0.9)

# Применяем двигательные силы к колесам
func apply_motor_forces():
	if abs(speed_input) > 0.05:
		# Вычисляем силу на основе ввода
		var drive_force = speed_input * engine_force

		# Распределяем силу между колесами
		var wheel_force = drive_force / 4.0

		# Применяем силу к каждому колесу
		apply_wheel_force(wheel_fl, wheel_force)
		apply_wheel_force(wheel_fr, wheel_force)
		apply_wheel_force(wheel_bl, wheel_force)
		apply_wheel_force(wheel_br, wheel_force)

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
		# Вычисляем угол на основе ввода
		var steer_angle = steering_input * steering_angle

		# Применяем к передним шарнирам
		set_hinge_angle(hinge_fl, steer_angle)
		set_hinge_angle(hinge_fr, steer_angle)

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
