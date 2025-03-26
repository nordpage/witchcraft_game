extends Area3D

@export var climb_target: NodePath  # указывает на WitchRoofPoint

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

var can_climb = false
var player_ref: Node = null

func _on_body_entered(body):
	if body.name == "WitchPlayer":
		can_climb = true
		player_ref = body

# В LadderArea.gd
func _process(delta):
	if can_climb and Input.is_action_just_pressed("interact"):  # E по умолчанию
		var target = get_node(climb_target)
		if target and player_ref:
			# Сначала зафиксируем тележку полностью
			var cart = get_node_or_null("/root/MainScene/CART")
			if cart and cart is VehicleBody3D:
				# Сохраняем текущий режим физики и скорости
				var old_freeze = cart.freeze
				var old_engine_force = cart.engine_force
				var old_brake = cart.brake
				
				# Полностью замораживаем тележку
				cart.freeze = true
				cart.engine_force = 0
				cart.brake = 100  # Применяем торможение
				
				# Телепортируем игрока
				player_ref.global_transform.origin = target.global_transform.origin
				
				# С задержкой восстанавливаем состояние тележки
				await get_tree().create_timer(0.5).timeout
				cart.freeze = old_freeze
				cart.engine_force = old_engine_force
				cart.brake = old_brake
				
				# Сбрасываем все возможные остаточные силы
				cart.linear_velocity = Vector3.ZERO
				cart.angular_velocity = Vector3.ZERO
			else:
				player_ref.global_transform.origin = target.global_transform.origin
			
			can_climb = false
