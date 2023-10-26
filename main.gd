extends Node

const Chunk = preload("res://chunk/chunk.tscn")
const BlockType = preload("res://block/block.gd")
const Block = preload("res://block/block.tscn")
const BlockClass = preload("res://classes/block_class.gd")
const NetworkMessage = preload("res://networking/network_message.gd")

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

func _ready():
	pass

func _exit_tree():
	pass

func _newBlock():
	blocksCount += 1
	return Block.instantiate()

func _newChunk():
	chunksCount += 1
	return Chunk.instantiate()

func _configureBlock(blockInfo: BlockClass, block: BlockType, chunk: Chunk):
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
	var block:BlockType = blocks[blockKey]
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
	var block:BlockType = null
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
