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

func _process(delta):
	if can_climb and Input.is_action_just_pressed("interact"):  # E по умолчанию
		var target = get_node(climb_target)
		if target and player_ref:
			player_ref.global_transform.origin = target.global_transform.origin
			can_climb = false
