class_name ChunkGenerator

const BlockClass = preload("res://block/block_class.gd")

var _data = null
var _initialBlocksInstance = null
var _instancied := false

func start():
	pass

func process():
	if _data != null && _initialBlocksInstance == null:
		var blockSize = int(len(_data)/6)
		_initialBlocksInstance = []
		for i in range(blockSize):
			var blockIndex = i * 6
			var blockInfo = BlockClass.new()
			blockInfo.x = _data[blockIndex + 0]
			blockInfo.y = _data[blockIndex + 1]
			blockInfo.z = _data[blockIndex + 2]
			blockInfo.t = _data[blockIndex + 3]
			blockInfo.c = _data[blockIndex + 4]
			blockInfo.m = _data[blockIndex + 5]
			
			var blockInstance = Main.instanceBlock(blockInfo);
			if(blockInstance == null):
				print("###### ERROR - %s" % JSON.stringify(blockInfo))
			_initialBlocksInstance.push_front(blockInstance)
			
		_instancied = true

func instanciateChunk(data):
	_instancied = false
	_initialBlocksInstance = null
	_data = data

func isInstancied():
	return _instancied

func getChunk():
	var arr = _initialBlocksInstance
	_initialBlocksInstance = null
	_data = null
	return arr

func exit():
	pass
