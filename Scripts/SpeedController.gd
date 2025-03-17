# SpeedController.gd - прикрепите к 2D элементу в вашем UI
extends Control

@export var cart_path: NodePath  # Путь к узлу тележки
@export var max_speed: float = 5.0  # Максимальная скорость
@export var turn_speed: float = 2.0  # Скорость поворота
@export var acceleration: float = 3.0  # Ускорение
@export var deceleration: float = 5.0  # Торможение

@onready var cart = get_node_or_null(cart_path)

var is_dragging: bool = false
var slider_value: float = 0.0  # От -1 до 1
var drag_start_pos: Vector2
var drag_current_offset: Vector2
var slider_height: float 

# Визуальные компоненты - добавьте их как дочерние узлы в редакторе
@onready var slider_background = $SliderBackground
@onready var slider_handle = $SliderHandle
@onready var slider_marker = $CenterMarker

signal speed_changed(value)

func _ready():
	slider_height = size.y - slider_handle.size.y
	# Центрируем маркер по вертикали, если он есть
	if slider_marker:
		slider_marker.position.y = size.y / 2 - slider_marker.size.y / 2
	
	# Инициализируем положение ручки слайдера в центре (нулевая скорость)
	reset_slider()

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Начинаем перетаскивание
			is_dragging = true
			drag_start_pos = event.position
			# Если кликнули не на ручку, сразу перемещаем её к позиции клика
			if slider_handle:
				var target_y = clamp(event.position.y - slider_handle.size.y / 2, 0, slider_height)
				slider_handle.position.y = target_y
				update_slider_value()
		else:
			# Заканчиваем перетаскивание и возвращаем ручку в центр
			is_dragging = false
			reset_slider()
	
	if event is InputEventMouseMotion and is_dragging:
		# Перемещаем ручку слайдера
		if slider_handle:
			var target_y = clamp(event.position.y - slider_handle.size.y / 2, 0, slider_height)
			slider_handle.position.y = target_y
			update_slider_value()

func update_slider_value():
	# Преобразуем положение ручки в значение слайдера от -1 до 1
	# Верх = -1 (полный вперед), центр = 0 (стоп), низ = 1 (полный назад)
	var normalized_pos = slider_handle.position.y / slider_height
	slider_value = (normalized_pos * 2 - 1) * -1  # Инвертируем, чтобы вверх был "вперед"
	
	emit_signal("speed_changed", slider_value)

func reset_slider():
	if slider_handle:
		# Возвращаем ручку в центральное положение (нулевая скорость)
		slider_handle.position.y = slider_height / 2
		slider_value = 0.0
		emit_signal("speed_changed", slider_value)

func _process(delta):
	if cart:
		# Применяем изменение скорости к тележке
		var target_speed = max_speed * slider_value
		var current_speed = cart.velocity.length() * sign(cart.velocity.dot(-cart.transform.basis.z))
		var new_speed = lerp(current_speed, target_speed, 
							acceleration * delta if abs(target_speed) > abs(current_speed) 
							else deceleration * delta)
		
		# Устанавливаем скорость тележки
		cart.velocity = -cart.transform.basis.z * new_speed
		
		# Обновляем анимацию, если она есть
		var animation_player = cart.get_node_or_null("AnimationPlayer")
		if animation_player:
			if abs(new_speed) > 0.1:
				if animation_player.has_animation("move") and not animation_player.is_playing():
					animation_player.play("move")
			else:
				if animation_player.is_playing():
					animation_player.stop()
		
		# Увеличиваем усталость при движении
		if abs(new_speed) > 0.1:
			var fatigue_amount = delta * 0.01 * abs(new_speed) / max_speed
			WitchFatigue.add_fatigue(fatigue_amount)
