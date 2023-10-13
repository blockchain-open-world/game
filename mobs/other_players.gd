extends Node3D

class_name OtherPlayer

var id:int = 0
var update = false
var currentAngle = Vector2.ZERO
var currentPosition = Vector3.ZERO
const FOLLOW_SPEED = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.lerp(currentPosition, delta * FOLLOW_SPEED)
	$head.rotation.x = lerp($head.rotation.x, clamp(currentAngle.x, deg_to_rad(-90), deg_to_rad(90)), delta * FOLLOW_SPEED)
	rotation.y = lerp(rotation.y, currentAngle.y, delta * FOLLOW_SPEED)
	pass
