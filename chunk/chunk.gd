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
	$StaticBody3D/CollisionShape3D.disabled = true
	$MeshInstance3D.visible = false
	for i in range(len(initialBlocksInstance)):
		var blockInstance = initialBlocksInstance[i]
		blocks[blockInstance.blockKey] = blockInstance
		Main.blocksCount += 1
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
			Main.instanceBlock(blockInfo, oldBlock);
		else:
			var blockInstance = Main.instanceBlock(blockInfo, null);
			chunk.blocks[newBlockKey] = blockInstance
			chunk.add_child(blockInstance)
		
	remove_child(block)
	ChunkGenerator.oldBlocks.push_front(block)

func exclude():
	for k in blocks:
		var block = blocks[k]
		remove_child(block)
		ChunkGenerator.oldBlocks.push_front(block)
	blocks = {}
	chunkPosition = Vector3i.ZERO
	chunkKey = ""
	mintMessages = []
	$StaticBody3D/CollisionShape3D.disabled = false
	$MeshInstance3D.visible = true
