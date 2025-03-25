extends Area3D
@export var ground_target: NodePath
var can_exit := false
var player: Node

func _ready():
	connect("body_entered", Callable(self, "_on_enter"))

func _on_enter(body):
	if body.name == "WitchPlayer":
		player = body
		can_exit = true

func _process(delta):
	if can_exit and Input.is_action_just_pressed("interact"):
		var target = get_node(ground_target)
		player.global_position = target.global_position
		can_exit = false
