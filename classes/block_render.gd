extends Node

const Block = preload("res://block/block.gd")

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
	
	if blockInfo.t >= 128:
		block.get_node("mesh").visible = false
		var material = _getMaterialBlock(blockInfo.s)
		for childIndex in BLOCK_FACES:
			var faceMask = BLOCK_FACES[childIndex]
			var face = block.get_child(childIndex)
			if block.faces & faceMask:
				face.material_override = material[face.name]
				face.visible = true
			else:
				face.visible = false
	elif blockInfo.t == 1:
		block.get_node("mesh").visible = true
		for childIndex in BLOCK_FACES:
			block.get_child(childIndex).visible = false

func _getMaterialBlock(skin):
	if not blockMaterial.has(skin):
		if skin == 1:
			blockMaterial[skin] = _getMaterialType1()
		else:
			assert(false, "invalid skin %s" % skin)
	return blockMaterial[skin]

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

