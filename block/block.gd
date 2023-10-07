extends Node3D

class_name Block

var Chunk = preload("res://chunk/chunk.tscn")

const STATE_NEW = 0
const STATE_ENABLED = 1
const STATE_DISABLED = 2
var state = STATE_NEW

var blockKey := ""
var globalPosition := Vector3i.ZERO
var type: int = 0
var faces: int
var chunk:Chunk = null

func disable():
	state = STATE_DISABLED
	visible = false
	get_node("StaticBody3D/CollisionShape3D").disabled = true

func enable(world:Node3D):
	if state == STATE_NEW:
		_instanceBlockCollider()
		world.add_child(self)
	state = STATE_ENABLED
	visible = true
	get_node("StaticBody3D/CollisionShape3D").disabled = false

func _instanceBlockCollider():
	var staticBody = StaticBody3D.new()
	var collisor = CollisionShape3D.new()
	staticBody.name = "StaticBody3D"
	collisor.name = "CollisionShape3D"
	collisor.shape = BoxShape3D.new()
	staticBody.collision_layer = 0x02;
	staticBody.collision_mask = 0;
	staticBody.position = Vector3(0.5,0.5,0.5)
	
	staticBody.add_child(collisor)
	add_child(staticBody)
