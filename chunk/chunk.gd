extends Node3D

var chunkPosition = Vector3i.ZERO
var chunkKey = ""
var blocks = {}
var mintMessages = []
var isNew = true
var isLoaded = false
var isStarted = false

var _initialBlocksInstance = []

func _process(delta):
	
	if len(_initialBlocksInstance) > 0:
		var count = 0
		while count < 100:
			count += 1
			if len(_initialBlocksInstance) > 0:
				var blockInstance = _initialBlocksInstance.pop_front()
				blocks[blockInstance.blockKey] = blockInstance
				addBlock(blockInstance)
		if len(_initialBlocksInstance) == 0:
			$StaticBody3D/CollisionShape3D.disabled = true
			$MeshInstance3D.visible = false
			isLoaded = true
		
	for i in range(len(mintMessages)):
		var msg = mintMessages[i]
		if msg.received:
			_onMintBlock(msg.response)
			mintMessages = mintMessages.filter(func (m): return m.id != msg.id)
			Network.clearMessage(msg)
			return;

func addBlock(block):
	blocks[block.blockKey] = block
	Main.blocksCount += 1
	block.enable()
	block.chunk = self
	if block.isNew:
		get_parent().add_child(block)
		block.isNew = false

func removeBlock(block):
	blocks.erase(block)
	Main.blocksCount -= 1
	block.disable()
	ChunkGenerator.oldBlocks.push_front(block)

func receiveBlocksInstance(initialBlocksInstance):
	isLoaded = false
	isStarted = true
	_initialBlocksInstance = initialBlocksInstance

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
	
	for i in range(len(data.blocks)):
		var blockInfo = data.blocks[i]
		var newBlockKey = Main.formatKey(blockInfo.x, blockInfo.y, blockInfo.z)
		var chunk = Main.getChunkByBlockPosition(blockInfo)
		if chunk.blocks.has(newBlockKey):
			var oldBlock = chunk.blocks[newBlockKey]
			Main.instanceBlock(blockInfo, oldBlock);
		else:
			var blockInstance = Main.instanceBlock(blockInfo, null);
			Main.instanceBlockCollider(blockInstance)
			chunk.blocks[newBlockKey] = blockInstance
			chunk.addBlock(blockInstance)
	removeBlock(block)

func enable():
	for k in blocks:
		var block = blocks[k]
		removeBlock(block)
	blocks = {}
	chunkPosition = Vector3i.ZERO
	chunkKey = ""
	mintMessages = []
	isLoaded = false
	isStarted = false
	$StaticBody3D/CollisionShape3D.disabled = false
	$MeshInstance3D.visible = true

func disable():
	for k in blocks:
		var block = blocks[k]
		removeBlock(block)
	blocks = {}
	chunkPosition = Vector3i.ZERO
	chunkKey = ""
	mintMessages = []
	$StaticBody3D/CollisionShape3D.disabled = true
	$MeshInstance3D.visible = false
