extends Node

var Chunk = preload("res://chunk/chunk.tscn")
var Block = preload("res://block/block.tscn")
var BlockClass = preload("res://block/block_class.gd")

const tile000 = preload("res://chunk/textures/tile000.png")
const tile031 = preload("res://chunk/textures/tile031.png")
const tile002 = preload("res://chunk/textures/tile002.png")
const tile003 = preload("res://chunk/textures/tile003.png")
const tile016 = preload("res://chunk/textures/tile024.png")
const tile022 = preload("res://chunk/textures/tile024.png")
var blockMaterial = {};

const CHUNK_SIZE = 16

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

var horizon = 1
var deleteHorizon = 4
var blocksCount = 0
var chunksCount = 0

var oldChunks = []
var oldBlocks = []
var chunks = {}
var chunksList = []
var blocks = {}

var _semaphore: Semaphore
var _mutex: Mutex
var _thread: Thread
var _exit_thread = false
var _newBlocks = []
var _newChunks = []

func _ready():
	pass
#	_semaphore = Semaphore.new()
#	_mutex = Mutex.new()
#	_thread = Thread.new()
	#_thread.start(_thread_function)

#func _thread_function():
#	while true:
#		_semaphore.wait()
#
#		var newBlocksLen = 0
#		var exit_thread = false
#		
#		_mutex.lock()
#		exit_thread = _exit_thread
#		newBlocksLen = len(_newBlocks)
#		_mutex.unlock()
#		
#		if exit_thread:
#			return;
#		
#		if newBlocksLen < 500:
#			var arr = []
#			for i in range(200):
#				var b = Block.instantiate()
#				arr.push_front(b)
#			
#			_mutex.lock()
#			_newBlocks.append_array(arr)
#			_mutex.unlock()
#
#func _process(delta):
#	if len(_newBlocks) < 500:
#		_newBlocks.push_back(_newBlock())
#	if len(_newChunks) < 50:
#		_newChunks.push_back(_newChunk())
	
func _exit_tree():
	pass
	#_mutex.lock()
	#_exit_thread = true
	#_mutex.unlock()
	#_semaphore.post()
	#_thread.wait_to_finish()

func _newBlock():
	blocksCount += 1
	return Block.instantiate()

func _newChunk():
	chunksCount += 1
	return Chunk.instantiate()

func _configureBlock(blockInfo: BlockClass, block: Block, chunk: Chunk):
	var blockKey = formatKey(blockInfo.x, blockInfo.y, blockInfo.z)
	
	var faces: int = int(blockInfo.m)
	block.faces = faces
	
	var material = _getMaterialBlock(blockInfo.t)
	for childIndex in BLOCK_FACES:
		var faceMask = BLOCK_FACES[childIndex]
		var face = block.get_child(childIndex)
		if block.faces & faceMask:
			face.visible = false
		else:
			face.material_override = material[face.name]
			face.visible = true
			
	block.blockKey = blockKey
	block.type = blockInfo.t
	block.globalPosition = Vector3i(blockInfo.x, blockInfo.y, blockInfo.z)
	block.position = Vector3(blockInfo.x, blockInfo.y, blockInfo.z)
	
	blocks[blockKey] = block
	chunk.blocks[blockKey] = block
	block.chunk = chunk
	block.enable(chunk._world)
	return block;

func _configureChunk(position: Vector3i, chunk: Chunk, world: Node3D):
	var chunkKey = formatKey(position.x, position.y, position.z)
	chunk.chunkPosition = position
	chunk.position = Vector3(CHUNK_SIZE * position.x, CHUNK_SIZE * position.y, CHUNK_SIZE * position.z)
	chunk.chunkKey = chunkKey
	chunks[chunkKey] = chunk
	chunksList.push_back(chunkKey)
	chunk.enable(world)
	return chunk

func removeBlock(blockKey):
	var block:Block = blocks[blockKey]
	blocks.erase(blockKey)
	block.chunk.blocks.erase(blockKey)
	block.disable()
	oldBlocks.push_back(block)

func removeChunk(chunkKey):
	var chunk:Chunk = chunks[chunkKey]
	chunks.erase(chunk.chunkKey)
	chunksList = chunksList.filter(func (key): return key != chunk.chunkKey)
	chunk.disable()

func instanceChunk(world, x, y, z):
	var chunkPosition = Vector3i(x, y, z)
	
	var chunk:Chunk = null
	#if len(oldChunks) > 0:
	#	chunk = oldChunks.pop_back()
	#else:
	#	chunk = _newChunk()
	chunk = _newChunk()
	_configureChunk(chunkPosition, chunk, world)
	return chunk

func instanceBlock(blockInfo: BlockClass, chunk: Chunk):
	var block:Block = null
	#if len(oldBlocks) > 0:
	#	block = oldBlocks.pop_back()
	#else:
	#	block = _newBlock()
	block = _newBlock()
	_configureBlock(blockInfo, block, chunk)
	return block

func formatKey(x, y, z):
	return ("i_%s_%s_%s" % [x, y, z]).replace("-", "n")

func transformChunkPosition(position):
	var chunkPosition = Vector3i(
		int(floor(float(position.x) / Main.CHUNK_SIZE)),
		int(floor(float(position.y) / Main.CHUNK_SIZE)),
		int(floor(float(position.z) / Main.CHUNK_SIZE))
	)
	return chunkPosition

func transformChunkLocalPosition(position):
	var chunkLocalPosition = Vector3(
		position.x % CHUNK_SIZE,
		position.y % CHUNK_SIZE,
		position.z % CHUNK_SIZE
	)
	if chunkLocalPosition.x < 0:
		chunkLocalPosition.x = CHUNK_SIZE + chunkLocalPosition.x
	if chunkLocalPosition.y < 0:
		chunkLocalPosition.y = CHUNK_SIZE + chunkLocalPosition.y
	if chunkLocalPosition.z < 0:
		chunkLocalPosition.z = CHUNK_SIZE + chunkLocalPosition.z
	return chunkLocalPosition

func getChunkByBlockPosition(position):
	var chunkPosition = transformChunkPosition(position)
	var chunkKey = formatKey(chunkPosition.x, chunkPosition.y, chunkPosition.z)
	return chunks[chunkKey]

func _getMaterialBlock(type):
	if not blockMaterial.has(type):
		if type == 1:
			blockMaterial[type] = _getMaterialType1()
		elif type == 2:
			blockMaterial[type] = _getMaterialType2()
		elif type == 3:
			blockMaterial[type] = _getMaterialType3()
		elif type == 4:
			blockMaterial[type] = _getMaterialType4()
		elif type == 5:
			blockMaterial[type] = _getMaterialType5()
		else:
			assert(false, "invalid type %s" % type)
	return blockMaterial[type]

func _getMaterialType1():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile000
	
	var side = StandardMaterial3D.new()
	side.albedo_texture = tile003
	
	var bottom = StandardMaterial3D.new()
	bottom.albedo_texture = tile002
	
	material["top"] = top
	material["bottom"] = bottom
	material["left"] = side
	material["right"] = side
	material["front"] = side
	material["back"] = side
	return material
	
func _getMaterialType2():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile002
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material

func _getMaterialType3():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile031
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material
	
func _getMaterialType4():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile016
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material

func _getMaterialType5():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile022
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material
