extends Node3D

var blockKey = ""
var globalPosition = Vector3i.ZERO
var type = 0
var faces: int
var isNew = true

func disable():
	visible = false
	$StaticBody3D/CollisionShape3D.disabled = true

func enable():
	visible = true
	$StaticBody3D/CollisionShape3D.disabled = false
