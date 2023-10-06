extends Node3D

var blockKey = ""
var globalPosition = Vector3i.ZERO
var type = 0
var faces: int
var isNew = true
var chunk = null

func disable():
	visible = false
	get_node("StaticBody3D/CollisionShape3D").disabled = true
	#$StaticBody3D/CollisionShape3D.disabled = true

func enable():
	visible = true
	get_node("StaticBody3D/CollisionShape3D").disabled = false
	#$StaticBody3D/CollisionShape3D.disabled = false
