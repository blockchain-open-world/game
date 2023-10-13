extends Node

const Chunk = preload("res://chunk/chunk.tscn")
const Block = preload("res://block/block.tscn")
const BlockClass = preload("res://classes/block_class.gd")
const NetworkMessage = preload("res://classes/network_message.gd")

const CHUNK_SIZE = 16

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
	
	BlockRender.updateBlock(blockInfo, block)
	
	block.blockKey = blockKey
	block.type = blockInfo.t
	block.globalPosition = Vector3i(blockInfo.x, blockInfo.y, blockInfo.z)
	block.position = Vector3(blockInfo.x, blockInfo.y, blockInfo.z)
	
	blocks[blockKey] = block
	chunk.blocks[blockKey] = block
	block.chunk = chunk
	block.enable()
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
	if len(oldChunks) > 0:
		chunk = oldChunks.pop_back()
	else:
		chunk = _newChunk()
	_configureChunk(chunkPosition, chunk, world)
	return chunk

func instanceBlock(blockInfo: BlockClass):
	var chunkPosition = transformChunkPosition(Vector3(blockInfo.x, blockInfo.y, blockInfo.z))
	var chunkKey = formatKey(chunkPosition.x, chunkPosition.y, chunkPosition.z)
	if not chunks.has(chunkKey):
		return null;
	var chunk:Chunk = chunks[chunkKey]
	var block:Block = null
	if len(oldBlocks) > 0:
		block = oldBlocks.pop_back()
	else:
		block = _newBlock()
	_configureBlock(blockInfo, block, chunk)
	return block

func arrayToBlockInfo(msg: NetworkMessage):
	var blockInfo = BlockClass.new()
	blockInfo.x = msg.getInteger()
	blockInfo.y = msg.getInteger()
	blockInfo.z = msg.getInteger()
	blockInfo.t = msg.getInteger()
	blockInfo.s = msg.getInteger()
	blockInfo.m = msg.getInteger()
	return blockInfo

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
