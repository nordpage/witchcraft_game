extends RigidBody3D

@export var speed_multiplier: float = 10.0
@export var acceleration: float = 2.0
@export var firewood_consumption_rate: float = 1.0  # дров расходуется за секунду, когда тележка двигается
@onready var anim_player: AnimationPlayer = $AnimationPlayer
signal is_moving(state)

var target_speed: float = 0.0

func _ready():
	gravity_scale = 1.0  # Нормальная гравитация
	mass = 20.0  # Достаточно тяжелая для стабильности
	linear_damp = 0.3  # Уменьшаем скольжение
	angular_damp = 2.0  # Уменьшаем раскачивание
	can_sleep = true
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true  # Предотвращает проваливание на высоких скоростях
	
	# Добавляем тележку в группу для обнаружения коллизий
	add_to_group("cart")

func _on_lever_changed(value: float) -> void:
	# Если дров достаточно, рассчитываем целевую скорость.
	# Если дров нет, тележка не может разогнаться.
	if ResourceManager.get_resource("firewood") > 0:
		target_speed = value * speed_multiplier
	else:
		target_speed = 0

func _physics_process(delta: float) -> void:
	# Если дров хватает, тележка ускоряется к целевой скорости.
	if ResourceManager.get_resource("firewood") > 0:
		var new_speed = lerp(linear_velocity.x, target_speed, acceleration * delta)
		linear_velocity.x = new_speed
		var is_moving = abs(new_speed) > 0.1
		emit_signal("is_moving", is_moving)
		# Если тележка действительно движется (скорость выше порога), расходуем дрова.
		if is_moving:
			if anim_player.current_animation != "moving":
				anim_player.play("moving")
			# Здесь, для простоты, мы расходуем целое число дров. 
			# Можно доработать систему накопления расхода, если требуется более точное потребление.
			ResourceManager.remove_resource("firewood", int(firewood_consumption_rate * delta))
	else:
		if anim_player.current_animation != "idle":
			anim_player.play("idle")
		# Если дров нет, тележка постепенно замедляется до остановки.
		linear_velocity.x = lerp(linear_velocity.x, 0.0, acceleration * delta)
