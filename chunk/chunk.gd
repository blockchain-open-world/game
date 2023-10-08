extends Node3D


class_name Chunk

const LOAD_PACK = 100

const STATE_NEW = 0
const STATE_WAIT_DATA = 1
const STATE_LOAD = 2
const STATE_ENABLED = 3
const STATE_UNLOAD = 4
const STATE_DISABLED = 5
var state = STATE_NEW

var chunkPosition = Vector3i.ZERO
var chunkKey = ""
var blocks = {}
var _mintMessages = []
var _blockInfoArray = []
var _world:Node3D
var _chunkMessage = null

func _process(delta):
	if state == STATE_LOAD:
		var count = 0
		while count < LOAD_PACK:
			count += 1
			if len(_blockInfoArray) > 0:
				var blockInfo = Main.arrayToBlockInfo(_blockInfoArray)
				if blockInfo.t != 0:
					Main.instanceBlock(blockInfo)
				
		if len(_blockInfoArray) == 0:
			state = STATE_ENABLED
			$StaticBody3D/CollisionShape3D.disabled = true
			$MeshInstance3D.visible = false
	elif state == STATE_ENABLED:
		for i in range(len(_mintMessages)):
			var msg = _mintMessages[i]
			if msg.received:
				_onMintBlock(msg.response)
				_mintMessages = _mintMessages.filter(func (m): return m.id != msg.id)
				Network.clearMessage(msg)
				return;
	elif state == STATE_UNLOAD:
		var removeBlocks = []
		for k in blocks:
			if len(removeBlocks) < LOAD_PACK:
				removeBlocks.push_back(blocks[k].blockKey)
		if len(removeBlocks) == 0:
			state = STATE_DISABLED
			
			Main.oldChunks.push_back(self)
		else:
			for i in range(len(removeBlocks)):
				Main.removeBlock(removeBlocks[i])
	elif state == STATE_WAIT_DATA:
		if _chunkMessage != null:
			if _chunkMessage.received:
				_setBlockInfoArray(_chunkMessage.response)
				Network.clearMessage(_chunkMessage)
				_chunkMessage = null

func _setBlockInfoArray(blockInfoArray):
	state = STATE_LOAD
	_blockInfoArray = blockInfoArray

func mintBlock(blockPosition):
	var position = {}
	position.x = blockPosition.x
	position.y = blockPosition.y
	position.z = blockPosition.z
	var msg = Network.send("mint_block", position)
	_mintMessages.push_back(msg)

func _onMintBlock(data):
	if not data.success:
		return
	
	var blockKey = Main.formatKey(data.position.x, data.position.y, data.position.z)
	var block:Block = blocks[blockKey]
	
	while len(data.blocks) > 0:
		var blockInfo = Main.arrayToBlockInfo(data.blocks)
		var newBlockKey = Main.formatKey(blockInfo.x, blockInfo.y, blockInfo.z)
		if Main.blocks.has(newBlockKey):
			if blockInfo.t == 0:
				Main.removeBlock(newBlockKey)
			else:
				var currentblock:Block = Main.blocks[newBlockKey]
				BlockRender.updateBlock(blockInfo, currentblock)
		elif blockInfo.t != 0:
			Main.instanceBlock(blockInfo)

func startLoad():
	var position = {}
	position.x = chunkPosition.x
	position.y = chunkPosition.y
	position.z = chunkPosition.z
	_chunkMessage = Network.send("chunk", position)

func enable(world: Node3D):
	if state == STATE_NEW:
		world.add_child(self)
	state = STATE_WAIT_DATA
	
	_world = world
	blocks = {}
	_mintMessages = []
	_blockInfoArray = []
	$StaticBody3D/CollisionShape3D.disabled = false
	$MeshInstance3D.visible = false # true

func disable():
	state = STATE_UNLOAD
	$StaticBody3D/CollisionShape3D.disabled = true
	$MeshInstance3D.visible = false
