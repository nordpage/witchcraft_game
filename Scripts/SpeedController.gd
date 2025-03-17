# CartSliderController.gd
extends Control

@export var cart_path: NodePath  # Путь к узлу тележки
@export var max_speed: float = 5.0  # Максимальная скорость
@export var turn_speed: float = 2.0  # Скорость поворота
@export var acceleration_force: float = 20.0  # Сила ускорения
@export var turn_force: float = 30.0  # Сила поворота

@onready var cart = get_node_or_null(cart_path)
@onready var speed_slider = $SpeedSlider  # VSlider для скорости
@onready var turn_slider = $TurnSlider    # HSlider для поворота

func _ready():
	# Настраиваем слайдеры
	if speed_slider:
		# Настраиваем диапазон от -1 до 1 (назад-стоп-вперед)
		speed_slider.min_value = -1.0
		speed_slider.max_value = 1.0
		speed_slider.value = 0.0
		
		# Настраиваем внешний вид скорости
		speed_slider.step = 0.1  # Шаги по 0.1
		
		# Подключаем сигнал изменения
		speed_slider.connect("value_changed", Callable(self, "_on_speed_changed"))
		# НЕ устанавливаем автовозврат в центр для SpeedSlider
	
	if turn_slider:
		# Настраиваем диапазон от -1 до 1 (влево-прямо-вправо)
		turn_slider.min_value = -1.0
		turn_slider.max_value = 1.0
		turn_slider.value = 0.0
		
		# Настраиваем внешний вид поворота
		turn_slider.step = 0.1  # Шаги по 0.1
		
		# Подключаем сигнал изменения
		turn_slider.connect("value_changed", Callable(self, "_on_turn_changed"))
		# Настраиваем автовозврат в центр только для слайдера поворота
		turn_slider.connect("drag_ended", Callable(self, "_on_turn_drag_ended"))

func _on_speed_changed(value):
	# Обработчик изменения скорости
	if value == 0.0:
		# Останавливаем анимацию, если скорость равна нулю
		var animation_player = cart.get_node_or_null("AnimationPlayer")
		if animation_player and animation_player.is_playing():
			animation_player.stop()

func _on_turn_changed(value):
	# Обработчик изменения поворота
	pass

func _on_turn_drag_ended(value_changed):
	# Возвращаем слайдер поворота в центр при отпускании
	turn_slider.value = 0.0

func _physics_process(delta):
	if cart:
		# Направление вперед по оси X
		var forward_dir = cart.transform.basis.x  # Используем X вместо -Z
		
		# УПРАВЛЕНИЕ ДВИЖЕНИЕМ ВПЕРЕД/НАЗАД (speed_slider)
		var forward_force = forward_dir * (speed_slider.value * max_speed * acceleration_force)
		cart.apply_central_force(forward_force)
		
		# УПРАВЛЕНИЕ ПОВОРОТОМ (turn_slider)
		if cart.linear_velocity.length() > 0.5:  # Поворачиваем только если движемся
			# Используем поворот вокруг оси Y
			var torque = Vector3(0, -turn_slider.value * turn_speed * turn_force, 0)
			cart.apply_torque(torque)
		
		# Обновляем анимацию
		var animation_player = cart.get_node_or_null("AnimationPlayer")
		if animation_player:
			var current_speed = cart.linear_velocity.length()
			if current_speed > 0.5 and speed_slider.value != 0.0:
				if animation_player.has_animation("moving") and not animation_player.is_playing():
					animation_player.play("moving")
			elif current_speed < 0.1 or speed_slider.value == 0.0:
				if animation_player.is_playing():
					animation_player.stop()
		
		# Добавляем усталость при движении
		if cart.linear_velocity.length() > 0.5:
			var fatigue_amount = delta * 0.01 * cart.linear_velocity.length() / max_speed
			WitchFatigue.add_fatigue(fatigue_amount)
