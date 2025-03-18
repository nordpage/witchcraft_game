extends VehicleBody3D

@export var MAX_STEER = 0.9
@export var ENGINE_POWER = 3000

# Меш лампы, который будет покачиваться
@export var lamp_mesh_path: NodePath
@export var max_lamp_swing: float = 10.0  # Максимальный угол наклона лампы в градусах

# Ссылки на визуальные модели колес
@export var wheel_fl_mesh_path: NodePath
@export var wheel_fr_mesh_path: NodePath
@export var wheel_bl_mesh_path: NodePath
@export var wheel_br_mesh_path: NodePath


var previous_velocity: Vector3 = Vector3.ZERO

var lamp_mesh: Node3D
var wheel_fl_mesh: Node3D
var wheel_fr_mesh: Node3D
var wheel_bl_mesh: Node3D
var wheel_br_mesh: Node3D

# Управление
var forward_pressed: bool = false
var backward_pressed: bool = false
var left_pressed: bool = false
var right_pressed: bool = false

# Значения для лампы
var lamp_target_rotation: float = 0.0
var lamp_current_rotation: float = 0.0
signal is_moving(state)

func _ready():
	center_of_mass_mode = VehicleBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.5, 0)

	# Получаем ссылку на меш лампы
	if lamp_mesh_path:
		lamp_mesh = get_node(lamp_mesh_path)

	# Получаем ссылки на меши колес
	if wheel_fl_mesh_path:
		wheel_fl_mesh = get_node(wheel_fl_mesh_path)
	if wheel_fr_mesh_path:
		wheel_fr_mesh = get_node(wheel_fr_mesh_path)
	if wheel_bl_mesh_path:
		wheel_bl_mesh = get_node(wheel_bl_mesh_path)
	if wheel_br_mesh_path:
		wheel_br_mesh = get_node(wheel_br_mesh_path)

func _physics_process(delta: float) -> void:
	# Обработка руления
	var steer_input = 0.0
	if left_pressed:
		steer_input += 1.0
	if right_pressed:
		steer_input -= 1.0

	steering = move_toward(steering, steer_input * MAX_STEER, delta * 10)

	# Обработка движения
	var throttle_input = 0.0
	if forward_pressed:
		throttle_input += 1.0
	if backward_pressed:
		throttle_input -= 1.0

	engine_force = throttle_input * ENGINE_POWER

	# Вращаем колеса
	rotate_wheels(delta)

	# Обновляем покачивание лампы
	update_lamp_swing(delta)

func _input(event: InputEvent) -> void:
	# Обработка нажатий клавиш
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
	# Вычисляем скорость вращения
	var forward_velocity = -linear_velocity.z  # Скорость вдоль оси Z
	var is_cart_moving = forward_velocity > 0.5
	emit_signal("is_moving", is_cart_moving)
	var wheel_radius = 1.875  # Радиус колеса
	var rotation_speed = forward_velocity / wheel_radius  # Угловая скорость

	# Вращаем колеса
	if wheel_fl_mesh:
		wheel_fl_mesh.rotate_x(rotation_speed * delta)
	if wheel_fr_mesh:
		wheel_fr_mesh.rotate_x(rotation_speed * delta)
	if wheel_bl_mesh:
		wheel_bl_mesh.rotate_x(rotation_speed * delta)
	if wheel_br_mesh:
		wheel_br_mesh.rotate_x(rotation_speed * delta)

func update_lamp_swing(delta: float) -> void:
	if lamp_mesh:
		# Рассчитываем целевой угол покачивания лампы на основе ускорения
		var acceleration = (linear_velocity - previous_velocity) / delta
		previous_velocity = linear_velocity

		# Вычисляем вклад от ускорения вперед/назад и от поворотов
		var forward_accel = -acceleration.z * 0.05  # Масштабирующий коэффициент
		var turn_effect = angular_velocity.y * 0.5  # Эффект от поворота

		# Комбинируем эффекты для целевого угла
		lamp_target_rotation = clamp(forward_accel + turn_effect, -max_lamp_swing, max_lamp_swing)

		# Плавно интерполируем текущий угол к целевому
		lamp_current_rotation = lerp(lamp_current_rotation, lamp_target_rotation, delta * 5.0)

		# Применяем вращение (сбрасываем предыдущее и устанавливаем новое)
		lamp_mesh.rotation_degrees.z = lamp_current_rotation
