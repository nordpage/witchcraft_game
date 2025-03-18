extends VehicleBody3D

# Настройки управления
@export var engine_force_value: float = 3000.0
@export var brake_force_value: float = 50.0
@export var steering_limit: float = 0.5
@export var steering_speed: float = 5.0

# Переменные для управления
var current_steering: float = 0.0
var current_engine_force: float = 0.0
var current_brake: float = 0.0

# Сигнал о движении для других систем
signal is_moving(state)

func _ready():
	add_to_group("cart")
	# Все остальные настройки (колес, подвески) уже сделаны в инспекторе

func _physics_process(delta):
	# Плавное управление рулем
	var steering_target = 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		steering_target = steering_limit
	elif Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		steering_target = -steering_limit

	# Интерполируем текущий угол поворота к целевому
	current_steering = lerp(current_steering, steering_target, steering_speed * delta)
	steering = current_steering

	# Управление двигателем
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		current_engine_force = engine_force_value
		current_brake = 0.0
	elif Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		current_engine_force = -engine_force_value / 2  # Меньше силы для реверса
		current_brake = 0.0
	else:
		current_engine_force = 0.0
		current_brake = brake_force_value  # Автоматическое торможение

	# Применяем силу двигателя и торможение
	engine_force = current_engine_force
	brake = current_brake

	# Отправляем сигнал о состоянии движения
	var is_cart_moving = linear_velocity.length() > 0.5
	emit_signal("is_moving", is_cart_moving)

	# Добавляем усталость ведьме при движении
	if is_cart_moving:
		var fatigue_amount = delta * 0.01 * linear_velocity.length() / 10.0
		if has_node("/root/WitchFatigue"):
			get_node("/root/WitchFatigue").add_fatigue(fatigue_amount)

# Обработка ввода с клавиатуры WASD
func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_W:
				Input.action_press("ui_up")
			elif event.keycode == KEY_S:
				Input.action_press("ui_down")
			elif event.keycode == KEY_A:
				Input.action_press("ui_left")
			elif event.keycode == KEY_D:
				Input.action_press("ui_right")
		else:  # Клавиша отпущена
			if event.keycode == KEY_W:
				Input.action_release("ui_up")
			elif event.keycode == KEY_S:
				Input.action_release("ui_down")
			elif event.keycode == KEY_A:
				Input.action_release("ui_left")
			elif event.keycode == KEY_D:
				Input.action_release("ui_right")
