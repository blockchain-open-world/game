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
var deleteHorizon = 3
var blocksCount = 0

var oldChunks = []
var oldBlocks = []
var chunks = {}
var blocks = {}

var _semaphore: Semaphore
var _mutex: Mutex
var _thread: Thread
var _exit_thread = false
var _newBlocks = []
var _newChunks = []

func _ready():
	_semaphore = Semaphore.new()
	_mutex = Mutex.new()
	_thread = Thread.new()
	_thread.start(_thread_function)

func _thread_function():
	while true:
		_semaphore.wait()

		var newBlocksLen = 0
		var exit_thread = false
		
		_mutex.lock()
		exit_thread = _exit_thread
		newBlocksLen = len(_newBlocks)
		_mutex.unlock()
		
		if exit_thread:
			return;
		
		if newBlocksLen < 500:
			var arr = []
			for i in range(200):
				var b = Block.instantiate()
				arr.push_front(b)
			
			_mutex.lock()
			_newBlocks.append_array(arr)
			_mutex.unlock()

func _process(delta):
	if _data != null:
		var count = 0
		while count < 256:
			count+=1;
			if _blockIndex < _blockSize:
				var blockInstance = null
				if len(oldBlocks) > 0:
					blockInstance = oldBlocks.pop_back()
					
				if blockInstance == null:
					_mutex.lock()
					if len(_newBlocks) > 0:
						blockInstance = _newBlocks.pop_back()
						Main.instanceBlockCollider(blockInstance)
					if len(_newBlocks) < 500:
						_semaphore.post()
					_mutex.unlock()
				
				if blockInstance == null:
					return
					
				var blockInfo = BlockClass.new()
				blockInfo.x = _data[_blockIndex * 6 + 0]
				blockInfo.y = _data[_blockIndex * 6 + 1]
				blockInfo.z = _data[_blockIndex * 6 + 2]
				blockInfo.t = _data[_blockIndex * 6 + 3]
				blockInfo.c = _data[_blockIndex * 6 + 4]
				blockInfo.m = _data[_blockIndex * 6 + 5]
				_blockIndex += 1
				
				blockInstance = Main.instanceBlock(blockInfo, blockInstance);
					
				if(blockInstance == null):
					print("###### ERROR - %s" % JSON.stringify(blockInfo))
				_initialBlocksInstance.push_front(blockInstance)
			else:
				_instancied = true

func _exit_tree():
	_mutex.lock()
	_exit_thread = true
	_mutex.unlock()
	_semaphore.post()
	_thread.wait_to_finish()

func _newBlock():
	return Block.instantiate()

func _newChunk():
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
	block.enable()
	return block;

func _configureChunk(position: Vector3i, chunk: Chunk):
	var chunkKey = formatKey(position.x, position.y, position.z)
	chunk.enable()
	chunk.chunkPosition = position
	chunk.position = Vector3(CHUNK_SIZE * position.x, CHUNK_SIZE * position.y, CHUNK_SIZE * position.z)
	chunk.chunkKey = chunkKey
	chunk[chunkKey] = chunk
	chunk.enable()
	return chunk

func _removeBlock(blockKey):
	




func formatKey(x, y, z):
	return ("i_%s_%s_%s" % [x, y, z]).replace("-", "n")
	
func instanceChunk(chunkX, chunkY, chunkZ):
	var chunkKey = formatKey(chunkX, chunkY, chunkZ)
	var chunk = null
	if len(oldChunks) > 0:
		chunk = oldChunks.pop_back()
	if chunk == null:
		chunk = Chunk.instantiate()
	chunk.enable()
	chunk.chunkPosition = Vector3i(chunkX, chunkY, chunkZ)
	chunk.position = Vector3(CHUNK_SIZE * chunkX, CHUNK_SIZE * chunkY, CHUNK_SIZE * chunkZ)
	chunk.chunkKey = chunkKey
	chunksMap[chunkKey] = chunk
	chunksList.push_back(chunkKey)
	return chunk

func removeChunk(chunkKey):
	if chunksMap.has(chunkKey):
		var chunk = chunksMap[chunkKey]
		chunksMap.erase(chunkKey)
		chunksList = chunksList.filter(func (key): return key != chunkKey)
		chunk.disable()
		oldChunks.push_front(chunk)

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
	return chunksMap[chunkKey]
	
func instanceBlock(blockInfo, blockInstance):
	var blockKey = formatKey(blockInfo.x, blockInfo.y, blockInfo.z)
	
	if blockInstance == null:
		blockInstance = Block.instantiate()
	
	var faces: int = int(blockInfo.m)
	blockInstance.faces = faces
	
	var material = _getMaterialBlock(blockInfo.t)
	for childIndex in BLOCK_FACES:
		var faceMask = BLOCK_FACES[childIndex]
		var face = blockInstance.get_child(childIndex)
		if blockInstance.faces & faceMask:
			face.visible = false
		else:
			face.material_override = material[face.name]
			face.visible = true
			
	blockInstance.blockKey = blockKey
	blockInstance.type = blockInfo.t
	
	blockInstance.globalPosition = Vector3i(blockInfo.x, blockInfo.y, blockInfo.z)
	blockInstance.position = Vector3i(blockInfo.x, blockInfo.y, blockInfo.z)
	#blockInstance.position = transformChunkLocalPosition(blockInstance.globalPosition)
	return blockInstance;

func instanceBlockCollider(blockInstance):
	var staticBody = StaticBody3D.new()
	var collisor = CollisionShape3D.new()
	staticBody.name = "StaticBody3D"
	collisor.name = "CollisionShape3D"
	collisor.shape = BoxShape3D.new()
	staticBody.collision_layer = 0x02;
	staticBody.collision_mask = 0;
	staticBody.position = Vector3(0.5,0.5,0.5)
	
	staticBody.add_child(collisor)
	blockInstance.add_child(staticBody)

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
