extends Node3D

class_name Block

var Chunk = preload("res://chunk/chunk.tscn")

const STATE_NEW = 0
var state = STATE_NEW

var blockKey := ""
var globalPosition := Vector3i.ZERO
var type: int = 0
var faces: int
var chunk:Chunk = null

func disable():
	visible = false
	get_node("StaticBody3D/CollisionShape3D").disabled = true
	#$StaticBody3D/CollisionShape3D.disabled = true

func enable():
	visible = true
	get_node("StaticBody3D/CollisionShape3D").disabled = false
	#$StaticBody3D/CollisionShape3D.disabled = false
