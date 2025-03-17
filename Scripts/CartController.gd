# CartController.gd
extends CharacterBody3D

@export var max_speed: float = 5.0
@export var rotation_speed: float = 2.0
@export var acceleration: float = 3.0
@export var deceleration: float = 5.0

# Для анимации
@onready var animation_player = $AnimationPlayer

signal is_moving(moving)

var moving: bool = false
var last_touch_position: Vector2 = Vector2.ZERO
var is_touching: bool = false

func _ready():
	# Настраиваем начальное состояние
	moving = false
	emit_signal("is_moving", moving)

func _input(event):
	# Обработка нажатия на тачпад
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_touching = event.pressed
			if is_touching:
				last_touch_position = event.position

	# Обработка перемещения пальца по тачпаду
	if event is InputEventMouseMotion and is_touching:
		# Разница между текущим и предыдущим положением курсора
		var motion = event.position - last_touch_position

		# Движение вперед/назад определяется по вертикальному движению
		if abs(motion.y) > abs(motion.x):
			# Движение вверх - вперед, вниз - назад
			var forward_amount = -sign(motion.y)
			velocity = -transform.basis.z * max_speed * forward_amount
		else:
			# Движение влево/вправо для поворота
			rotate_y(-motion.x * rotation_speed * 0.01)

		# Обновляем последнее известное положение
		last_touch_position = event.position

func _physics_process(delta):
	# Если не касаемся тачпада, постепенно замедляемся
	if !is_touching:
		velocity = velocity.lerp(Vector3.ZERO, deceleration * delta)

	# Управление анимацией
	if velocity.length() > 0.1:
		if animation_player and animation_player.has_animation("move"):
			if not animation_player.is_playing():
				animation_player.play("move")
	else:
		if animation_player and animation_player.is_playing():
			animation_player.stop()

	# Выполняем перемещение
	move_and_slide()

	# Обновляем статус движения
	var was_moving = moving
	moving = velocity.length() > 0.1

	if was_moving != moving:
		emit_signal("is_moving", moving)

	# Если движемся, увеличиваем усталость
	if moving:
		var fatigue_amount = delta * 0.01 * velocity.length() / max_speed
		WitchFatigue.add_fatigue(fatigue_amount)
