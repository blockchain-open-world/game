extends Node3D

var chunkPosition = Vector3i.ZERO
var chunkKey = ""
var isExclude = false
var blocks = {}
var mintMessages = []

func _process(delta):
	if isExclude:
		if get_child_count() > 0:
			get_child(0).free()
		else:
			free()
		return;
	for i in range(len(mintMessages)):
		var msg = mintMessages[i]
		if msg.received:
			_onMintBlock(msg.response)
			mintMessages = mintMessages.filter(func (m): return m.id != msg.id)
			Network.clearMessage(msg)
			return;

func _addBlockInstance(blockInstance):
	if isExclude:
		return;
	if blockInstance.faces & Main.FACES_RIGHT:
		blockInstance.get_child(5).visible = false
	if blockInstance.faces & Main.FACES_LEFT:
		blockInstance.get_child(4).visible = false
	if blockInstance.faces & Main.FACES_BACK:
		blockInstance.get_child(3).visible = false
	if blockInstance.faces & Main.FACES_FRONT:
		blockInstance.get_child(2).visible = false
	if blockInstance.faces & Main.FACES_BOTTOM:
		blockInstance.get_child(1).visible = false
	if blockInstance.faces & Main.FACES_TOP:
		blockInstance.get_child(0).visible = false
		
	var staticBody = StaticBody3D.new()
	var collisor = CollisionShape3D.new()
	collisor.shape = BoxShape3D.new()
	staticBody.collision_layer = 0x02;
	staticBody.collision_mask = 0;
	staticBody.add_child(collisor)
	blockInstance.add_child(staticBody)
	staticBody.position = Vector3(0.5,0.5,0.5)
		
	add_child(blockInstance)

func receiveBlocksInstance(initialBlocksInstance):
	$StaticBody3D/CollisionShape3D.disabled = true
	$MeshInstance3D.visible = false
	for i in range(len(initialBlocksInstance)):
		var blockInstance = initialBlocksInstance[i]
		blocks[blockInstance.blockKey] = blockInstance
		
		_addBlockInstance(blockInstance)

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
		chunk._addBlockInstance(blockInstance)
	block.queue_free()

func exclude():
	isExclude = true
