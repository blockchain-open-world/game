extends Node

const FACES_RIGHT:int = 1
const FACES_LEFT:int = 2
const FACES_BACK:int = 4
const FACES_FRONT:int = 8
const FACES_BOTTOM:int = 16
const FACES_TOP:int = 32
const BLOCK_FACES = {
	5: FACES_RIGHT,
	4: FACES_LEFT,
	3: FACES_BACK,
	2: FACES_FRONT,
	1: FACES_BOTTOM,
	0: FACES_TOP,
}

const default = preload("res://chunk/textures/default.png")
var blockMaterial = {};

func updateBlock(blockInfo: BlockClass, block: Block):
	block.faces = int(blockInfo.m)
	
	var material = _getMaterialBlock(blockInfo.t)
	for childIndex in BLOCK_FACES:
		var faceMask = BLOCK_FACES[childIndex]
		var face = block.get_child(childIndex)
		if block.faces & faceMask:
			face.material_override = material[face.name]
			face.visible = true
		else:
			face.visible = false

func _getMaterialBlock(type):
	if not blockMaterial.has(type):
		if type == 128:
			blockMaterial[type] = _getMaterialType1()
		else:
			assert(false, "invalid type %s" % type)
	return blockMaterial[type]

func _getMaterialType1():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = default
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material

