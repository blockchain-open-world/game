extends Node3D

var chunkPosition = Vector3i.ZERO
var chunkKey = ""

var blocks = {}
var mintMessages = []

func _process(delta):
	for i in range(len(mintMessages)):
		var msg = mintMessages[i]
		if msg.received:
			_onMintBlock(msg.response)
			mintMessages = mintMessages.filter(func (m): return m.id != msg.id)
			Network.clearMessage(msg)
			return;

func receiveBlocksInstance(initialBlocksInstance):
	for i in range(len(initialBlocksInstance)):
		var blockInstance = initialBlocksInstance[i]
		blocks[blockInstance.blockKey] = blockInstance
		
		#if blockInstance.faces & Main.FACES_RIGHT:
		#	blockInstance.get_child(5).queue_free()
		#if blockInstance.faces & Main.FACES_LEFT:
		#	blockInstance.get_child(4).queue_free()
		#if blockInstance.faces & Main.FACES_BACK:
		#	blockInstance.get_child(3).queue_free()
		#if blockInstance.faces & Main.FACES_FRONT:
		#	blockInstance.get_child(2).queue_free()
		#if blockInstance.faces & Main.FACES_BOTTOM:
		#	blockInstance.get_child(1).queue_free()
		#if blockInstance.faces & Main.FACES_TOP:
		#	blockInstance.get_child(0).queue_free()
		
		var staticBody = StaticBody3D.new()
		var collisor = CollisionShape3D.new()
		collisor.shape = BoxShape3D.new()
		staticBody.collision_layer = 0x02;
		staticBody.collision_mask = 0;
		staticBody.add_child(collisor)
		blockInstance.add_child(staticBody)
		staticBody.position = Vector3(0.5,0.5,0.5)
		
		add_child(blockInstance)

func mintBlock(blockPosition):
	var position = {}
	position.x = blockPosition.x
	position.y = blockPosition.y
	position.z = blockPosition.z
	var msg = Network.send("mint_block", position)
	mintMessages.push_back(msg)

func _onMintBlock(data):
	if not data.success:
		return
	
	var blockKey = Main.formatKey(data.minedBlock.x, data.minedBlock.y, data.minedBlock.z)
	var block = blocks[blockKey]
	blocks.erase(block)
	
	for i in range(len(data.blocks)):
		var blockInfo = data.blocks[i]
		var newBlockKey = Main.formatKey(blockInfo.x, blockInfo.y, blockInfo.z)
		var chunk = Main.getChunkByBlockPosition(blockInfo)
		if chunk.blocks.has(newBlockKey):
			var oldBlock = chunk.blocks[newBlockKey]
			oldBlock.queue_free()
		var blockInstance = Main.instanceBlock(blockInfo);
		chunk.blocks[newBlockKey] = blockInstance
		chunk.add_child(blockInstance)
	block.queue_free()
