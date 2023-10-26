extends CharacterBody3D

var mouseSensibility = 1200
const SPEED = 5.0
const JUMP_VELOCITY = 6

const Contants = preload("res://classes/constants.gd")

# Get the gravity from the project settings to be synced with RigidBody nodes.
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var head = $head
@onready var handRay = $head/RayCast3D
@onready var skinAnim = $skin/AnimationPlayer
@onready var blockSelection = $"../block_selection"

# Mouse Control
var mouse_sensitivity = 0.002
var is_camera_first_person = true
var fly_mode = Contants.flyMode
var start = Contants.waitLoading
var mouse_vector = Vector2.ZERO

func _ready():
	handRay.add_exception(self)
	_playAnimation("Idle")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_changeCameraMode(is_camera_first_person)

func _process(_delta):
	if Input.is_action_pressed("menu"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE && Input.is_action_pressed("mouse_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.is_action_just_pressed("change_camera"):
		_changeCameraMode(!is_camera_first_person)
	if Input.is_action_just_pressed("flying_mode"):
		fly_mode = !fly_mode
	_handAction();

func _physics_process(delta):
	# wait start
	if not start:
		return;
	# Speed Control
	var currentSpeed = SPEED
	if Input.is_action_pressed("run"):
		currentSpeed = currentSpeed * 1.5
	elif Input.is_action_pressed("crouch"):
		currentSpeed = currentSpeed * 0.5
	# Gravity Control
	if fly_mode:
		if Input.is_action_pressed("crouch"):
			velocity.y = -currentSpeed
		elif Input.is_action_pressed("jump"):
			velocity.y = currentSpeed
		else:
			velocity.y = 0
	else:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)
	_updateAnimation()
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x / mouseSensibility
		$head.rotation.x -= event.relative.y / mouseSensibility
		$head.rotation.x = clamp($head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		mouse_vector.x = $head.rotation.x
		mouse_vector.y = rotation.y

func _changeCameraMode(isFirstPerson):
	is_camera_first_person = isFirstPerson
	if is_camera_first_person:
		$crosshair.visible = true
		$skin.visible = false
		$head/third.current = false
		$head/first.current = true
	else:
		$crosshair.visible = false
		$skin.visible = true
		$head/first.current = false
		$head/third.current = true
	
func _updateAnimation():
	var animation = "Idle"
	if Input.is_action_pressed("right"):
		animation = "Walking_Right"
	elif Input.is_action_pressed("left"):
		animation = "Walking_Left"
	elif Input.is_action_pressed("back"):
		animation = "Walking_Backwards"
	elif Input.is_action_pressed("forward"):
		animation = "Walking_Front"
	if not is_on_floor():
		animation = "Jump_Idle"
	_playAnimation(animation)

func _playAnimation(animationName):
	if skinAnim.current_animation != animationName:
		var anim = skinAnim.get_animation(animationName)
		anim.loop_mode = Animation.LOOP_LINEAR
		skinAnim.play(animationName)

func _handAction():
	if not handRay.is_colliding():
		blockSelection.visible = false
		return
	var blockColider = handRay.get_collider()
	var block = blockColider.get_parent()
	blockSelection.visible = true
	blockSelection.position = Vector3(block.globalPosition)
	if Input.is_action_just_pressed("mouse_click"):
		block.chunk.mintBlock(block.globalPosition)
