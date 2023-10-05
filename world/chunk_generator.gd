class_name ChunkGenerator

var _data = null
var _initialBlocksInstance = []
var _instancied := false
var _mutex: Mutex
var _semaphore: Semaphore
var _thread: Thread
var _exit_thread := false

func start():
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_exit_thread = false
	_thread = Thread.new()
	_thread.start(_thread_function)

func _thread_function():
	while true:
		_semaphore.wait()
		
		_mutex.lock()
		var data = _data
		var should_exit = _exit_thread
		_mutex.unlock()
		
		if should_exit:
			break
		
		var arr = []
		for i in range(len(data)):
			var blockInfo = data[i]
			var blockInstance = Main.instanceBlock(blockInfo);
			if(blockInstance == null):
				print("###### ERROR - %s" % JSON.stringify(blockInfo))
			#assert(blockInstance == null, "###### ERROR - %s" % JSON.stringify(blockInfo))
			arr.push_front(blockInstance)
			
		_mutex.lock()
		_instancied = true
		_initialBlocksInstance = arr
		_mutex.unlock()

func instanciateChunk(data):
	_mutex.lock()
	_instancied = false
	_initialBlocksInstance = []
	_data = data
	_mutex.unlock()
	
	_semaphore.post()

func isInstancied():
	_mutex.lock()
	var is_instancied = _instancied
	_mutex.unlock()
	
	return is_instancied

func getChunk():
	_mutex.lock()
	var arr = _initialBlocksInstance
	_mutex.unlock()
	
	return arr

func exit():
	_mutex.lock()
	_exit_thread = true
	_mutex.unlock()
	
	_semaphore.post()
	_thread.wait_to_finish()
