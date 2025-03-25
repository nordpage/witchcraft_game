extends VehicleBody3D

@export var MAX_STEER = 0.4  # Угол поворота руля
@export var ENGINE_POWER = 5000.0  # Значительно увеличил мощность с 2000 до 5000
@export var BRAKE_POWER = 100.0  # Сила торможения

# Ссылки на меши
@export var lamp_mesh_path: NodePath
@export var max_lamp_swing: float = 10.0
@export var wheel_fl_mesh_path: NodePath
@export var wheel_fr_mesh_path: NodePath
@export var wheel_bl_mesh_path: NodePath
@export var wheel_br_mesh_path: NodePath

# Переменные
var previous_velocity: Vector3 = Vector3.ZERO
var lamp_mesh: Node3D
var wheel_fl_mesh: Node3D
var wheel_fr_mesh: Node3D
var wheel_bl_mesh: Node3D
var wheel_br_mesh: Node3D
var forward_pressed: bool = false
var backward_pressed: bool = false
var left_pressed: bool = false
var right_pressed: bool = false
var lamp_target_rotation: float = 0.0
var lamp_current_rotation: float = 0.0
signal is_moving(state)

func _ready():
	# Физические настройки
	mass = 800.0  # Уменьшил массу для более быстрого ускорения
	center_of_mass_mode = VehicleBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.8, 0)  # Сохраняем низкий центр масс
	
	# Ограничения вращения
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	# Настройка демпфирования - уменьшил для большей скорости
	linear_damp = 0.2  # Было 0.5
	angular_damp = 2.0  # Было 3.0

	# Настройка VehicleBody3D
	engine_force = 0.0
	brake = 0.0
	steering = 0.0
	
	# Установка ссылок на объекты
	if lamp_mesh_path:
		lamp_mesh = get_node(lamp_mesh_path)
	if wheel_fl_mesh_path:
		wheel_fl_mesh = get_node(wheel_fl_mesh_path)
	if wheel_fr_mesh_path:
		wheel_fr_mesh = get_node(wheel_fr_mesh_path)
	if wheel_bl_mesh_path:
		wheel_bl_mesh = get_node(wheel_bl_mesh_path)
	if wheel_br_mesh_path:
		wheel_br_mesh = get_node(wheel_br_mesh_path)
	
	# Устанавливаем физические параметры для колес
	setup_wheel_properties()
	

func setup_wheel_properties():
	# Для всех VehicleWheel3D на тележке
	for child in get_children():
		if child is VehicleWheel3D:
			# Оптимизированные настройки для скорости и стабильности
			child.suspension_stiffness = 25.0  # Более мягкая подвеска для лучшего сцепления
			child.wheel_friction_slip = 10.0  # Хорошее сцепление, но не чрезмерное
			child.wheel_roll_influence = 0.01  # Оставляем низким для стабильности
			child.damping_compression = 0.5
			child.damping_relaxation = 0.6
			child.suspension_max_force = 8000.0  # Меньше силы для более мягкой подвески

func _physics_process(delta: float) -> void:
	# Плавное управление рулем
	var steer_target = 0.0
	if left_pressed:
		steer_target += MAX_STEER
	if right_pressed:
		steer_target -= MAX_STEER
	
	steering = move_toward(steering, steer_target, delta * 3.0)  # Быстрее изменяем руль
	
	# Управление двигателем и торможением
	var engine_target = 0.0
	var brake_target = 0.0
	
	if forward_pressed:
		engine_target = ENGINE_POWER
		brake_target = 0.0
	elif backward_pressed:
		engine_target = -ENGINE_POWER * 0.7  # Меньшая мощность для заднего хода
		brake_target = 0.0
	else:
		engine_target = 0.0
		brake_target = BRAKE_POWER  # Автоматическое торможение
	
	engine_force = move_toward(engine_force, engine_target, delta * 1500.0)  # Быстрее набираем скорость
	brake = move_toward(brake, brake_target, delta * 100.0)
	
	# Обновляем вращение колес и лампы
	rotate_wheels(delta)
	#update_lamp_swing(delta)
	
	# Отправляем сигнал о движении
	var speed = linear_velocity.length()
	var is_cart_moving = speed > 0.5
	emit_signal("is_moving", is_cart_moving)
	
	# Отладочный вывод скорости
	if Engine.get_frames_drawn() % 60 == 0:  # Примерно раз в секунду
		#print("Cart speed: ", speed, " m/s (", speed * 3.6, " km/h)")
		pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			forward_pressed = event.pressed
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			backward_pressed = event.pressed
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			left_pressed = event.pressed
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			right_pressed = event.pressed

func rotate_wheels(delta: float) -> void:
	# Получаем абсолютную скорость тележки
	var speed = linear_velocity.length()
	
	# Определяем направление движения (вперёд/назад)
	var moving_forward = linear_velocity.dot(-global_transform.basis.z) > 0
	
	var wheel_radius = 1.875
	var rotation_speed = (speed / wheel_radius) * (-1 if moving_forward else 1)  # Учитываем реверс
	
	# Вращаем колёса
	if wheel_fl_mesh:
		wheel_fl_mesh.rotate_x(rotation_speed * delta)
	if wheel_fr_mesh:
		wheel_fr_mesh.rotate_x(rotation_speed * delta)
	if wheel_bl_mesh:
		wheel_bl_mesh.rotate_x(rotation_speed * delta)
	if wheel_br_mesh:
		wheel_br_mesh.rotate_x(rotation_speed * delta)
