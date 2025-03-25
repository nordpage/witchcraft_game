extends CharacterBody3D

# Узлы
@onready var skeleton = %Skeleton
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var camera = $WitchCameraPivot/WitchCamera
@onready var camera_pivot := $WitchCameraPivot
@onready var interaction_ray = $InteractionRay
@onready var right_hand = %Skeleton/BoneAttachment3D_RHand
@onready var hint_label := $"../CanvasLayer/InteractionHint"
var current_interactable: Node = null


# Движение
const WALK_SPEED = 4.0
const RUN_SPEED = 7.0
const ACCEL = 10.0
var current_speed := WALK_SPEED
var direction := Vector3.ZERO

# Камера/мышь
@export var mouse_sensitivity := 0.0012
var yaw := 0.0
var pitch := 0.0

# Покачивание головы
var bob_time := 0.0
@export var bob_speed := 8.0
@export var bob_amount := 0.04
var camera_base_pos: Vector3

# Инструмент
var equipped_tool: Node = null

func _ready():
	animation_tree.active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_base_pos = camera.position

func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.2, 1.2)

		rotation.y = yaw
		camera_pivot.rotation.x = pitch

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if event.keycode == KEY_TAB:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("interact"):
			try_interact()

func _physics_process(delta):
	# Бег
	current_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED

	var move_input := Vector3.ZERO
	move_input.z = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	move_input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	if move_input.length() > 0:
		direction = (-global_transform.basis.z * move_input.z) + (global_transform.basis.x * move_input.x)
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO

	velocity = velocity.lerp(direction * current_speed, delta * ACCEL)
	move_and_slide()

func _process(delta):
	handle_animation()
	handle_camera_bob(delta)
	update_interaction_hint()
	
	
func update_interaction_hint():
	interaction_ray.force_raycast_update()

	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		if target and target.has_method("get_interaction_hint"):
			hint_label.text = "[E] " + target.get_interaction_hint()
			hint_label.visible = true
			current_interactable = target
			return

		# если попали, но нет метода — сбрасываем
		hint_label.visible = false
		current_interactable = null
	else:
		hint_label.visible = false
		current_interactable = null



func handle_animation():
	var speed = velocity.length()
	animation_tree.set("parameters/blend_position", speed)

func handle_camera_bob(delta):
	var is_moving = velocity.length() > 0.1
	if is_moving:
		bob_time += delta * bob_speed
		var bob_offset = sin(bob_time * 2.0) * bob_amount
		camera.position.y = camera_base_pos.y + bob_offset
	else:
		camera.position.y = lerp(camera.position.y, camera_base_pos.y, delta * 8.0)

func try_interact():
	if current_interactable and current_interactable.has_method("interact"):
		current_interactable.interact()


func equip_tool(tool_scene: PackedScene):
	if equipped_tool:
		equipped_tool.queue_free()
	equipped_tool = tool_scene.instantiate()
	right_hand.add_child(equipped_tool)
	equipped_tool.transform.origin = Vector3.ZERO
