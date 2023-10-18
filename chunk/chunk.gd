extends Node3D

class_name Chunk

const Block = preload("res://block/block.gd")
const NetworkMessage = preload("res://networking/network_message.gd")

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
var _world:Node3D
var _chunkMessage: NetworkMessage

func _process(delta):
	if state == STATE_LOAD:
		var count = 0
		while count < LOAD_PACK:
			count += 1
			if _chunkMessage.hasNext():
				var blockInfo = Main.arrayToBlockInfo(_chunkMessage)
				if blockInfo.t != 0:
					Main.instanceBlock(blockInfo)
				
		if not _chunkMessage.hasNext():
			state = STATE_ENABLED
			$StaticBody3D/CollisionShape3D.disabled = true
			$MeshInstance3D.visible = false
	elif state == STATE_ENABLED:
		for i in range(len(_mintMessages)):
			var msg = _mintMessages[i]
			if msg.received:
				_onMintBlock(msg)
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
				state = STATE_LOAD
				Network.clearMessage(_chunkMessage)

func mintBlock(blockPosition):
	var msg = Network.mintBlock(blockPosition)
	_mintMessages.push_back(msg)

func _onMintBlock(msg: NetworkMessage):
	var success:int = msg.getUShort()
	
func startLoad():
	_chunkMessage = Network.getChunk(chunkPosition)

func enable(world: Node3D):
	if state == STATE_NEW:
		world.add_child(self)
	state = STATE_WAIT_DATA
	
	_world = world
	blocks = {}
	_mintMessages = []
	_chunkMessage = null
	$StaticBody3D/CollisionShape3D.disabled = false
	$MeshInstance3D.visible = true

func disable():
	state = STATE_UNLOAD
	$StaticBody3D/CollisionShape3D.disabled = true
	$MeshInstance3D.visible = false
