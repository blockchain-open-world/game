extends Node

"""
const BlockClass = preload("res://block/block_class.gd")
const Block = preload("res://block/block.tscn")

var oldBlocks = []
var _data = null
var _initialBlocksInstance = []
var _instancied := false
var _blockIndex = 0
var _blockSize = 0

var _semaphore: Semaphore
var _mutex: Mutex
var _thread: Thread
var _exit_thread = false
var _newBlocks = []

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

func instanciateChunk(data):
	_instancied = false
	_data = data
	_blockSize = int(len(_data)/6)
	_blockIndex = 0
	_initialBlocksInstance = []

func isInstancied():
	return _instancied

func getChunk():
	var arr = _initialBlocksInstance
	_initialBlocksInstance = null
	_data = null
	return arr

func _exit_tree():
	_mutex.lock()
	_exit_thread = true
	_mutex.unlock()
	_semaphore.post()
	_thread.wait_to_finish()
asdfasdf
"""
