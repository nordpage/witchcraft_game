extends RigidBody3D

@export var max_speed: float = 30.0
@export var acceleration: float = 200.0
@export var steering_speed: float = 1.5
@export var suspension_strength: float = 200.0
@export var damping: float = 0.9

@onready var wheel_fl: RigidBody3D = $Suspension_FL/WheelFrontLeft
@onready var wheel_fr: RigidBody3D = $Suspension_FR/WheelFrontRight
@onready var wheel_bl: RigidBody3D = $Suspension_BL/WheelBackLeft
@onready var wheel_br: RigidBody3D = $Suspension_BR/WheelBackRight
@onready var terrain = $HTerrain # Указываем путь к HTerrain


var speed_input: float = 0.0
var steering_input: float = 0.0

func _ready() -> void:
	lock_wheel_axes()
	for wheel in [wheel_fl, wheel_fr, wheel_bl, wheel_br]:
		wheel.set_collision_mask_value(3, false)  # Колёса не сталкиваются с тележкой

	if terrain:
		terrain.regenerate_collision()  # Принудительно обновляем коллизии

func _physics_process(delta):
	apply_suspension()
	handle_steering()
	apply_motor_force()
	align_to_terrain()
	prevent_rollover()
	for wheel in [wheel_fl, wheel_fr, wheel_bl, wheel_br]:
		print("Высота колеса:", wheel.global_transform.origin.y)



func align_to_terrain():
	if not terrain:
		return

	var ray_start = global_transform.origin + Vector3(0, 2, 0)  # Луч сверху
	var ray_end = global_transform.origin + Vector3(0, -5, 0)  # Луч вниз

	var ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query)

	if result:
		var normal = result["normal"]

		# Получаем новый Basis с правильным наклоном
		var forward = -global_transform.basis.z  # Текущий вектор вперёд
		var new_basis = Basis().looking_at(forward, normal)  # Выравниваем по нормали

		# Плавно интерполируем (чтобы не дёргалось)
		global_transform.basis = global_transform.basis.slerp(new_basis, 0.1)

func prevent_rollover():
	var up = global_transform.basis.y  # Направление вверх
	var angle = up.angle_to(Vector3.UP)  # Угол отклонения

	if angle > deg_to_rad(20):  # Если завал тележки больше 20 градусов
		var correction_force = up.cross(Vector3.UP) * mass * 10.0
		apply_torque(correction_force)  # Стабилизируем тележку


# 📌 Подвеска (мягкость)
func apply_suspension():
	for wheel in [wheel_fl, wheel_fr, wheel_bl, wheel_br]:
		var ray_start = wheel.global_transform.origin + Vector3(0, 1, 0)
		var ray_end = wheel.global_transform.origin + Vector3(0, -1, 0)

		var ray_query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		var result = get_world_3d().direct_space_state.intersect_ray(ray_query)

		if result:
			var compression = 1.0 - result["position"].y / wheel.global_transform.origin.y
			var force = 1200.0 * compression  # Увеличиваем силу подвески
			wheel.apply_central_force(Vector3(0, force, 0))

		wheel.linear_velocity *= 0.9  # Гасим резкие колебания

func lock_wheel_axes():
	for wheel in [wheel_bl, wheel_br]:  # Задние колёса (приводные)
		wheel.axis_lock_angular_x = true  # Запрещаем наклоняться вбок
		wheel.axis_lock_angular_y = false  # Разрешаем крутиться (двигаться)
		wheel.axis_lock_angular_z = true  # Запрещаем вращаться вокруг продольной оси

	for wheel in [wheel_fl, wheel_fr]:  # Передние колёса (рулевые)
		wheel.axis_lock_angular_x = true  # Запрещаем наклоняться вбок
		wheel.axis_lock_angular_y = false  # Разрешаем поворот рулём
		wheel.axis_lock_angular_z = true  # Запрещаем вибрацию вперёд-назад



# 📌 Поворот передних колёс
func handle_steering():
	var turn_force = steering_input * steering_speed
	wheel_fl.apply_torque(Vector3(0, turn_force, 0))
	wheel_fr.apply_torque(Vector3(0, turn_force, 0))

# 📌 Привод на задние колёса
func apply_motor_force():
	if abs(speed_input) > 0.05:
		var force = -global_transform.basis.z * (speed_input * 1500.0)  # Достаточно силы для движения
		apply_central_force(force)  # Применяем силу ко всей тележке


# 📌 Вход с клавиатуры
func _input(event):
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
		else:
			if event.keycode == KEY_W or event.keycode == KEY_S:
				speed_input = 0.0
			elif event.keycode == KEY_A or event.keycode == KEY_D:
				steering_input = 0.0
