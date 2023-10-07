extends Node3D

@onready var player = $player

var playerChunkPosition = Vector3i.ZERO

var _selectedGenerateChunk:Chunk = null
var _chunkMessage = null
var loadChunks = []

func _ready():
	pass

func _process(delta):
	_checkOnlineChunks()
	_checkRemoveChunks()
	_loadChunks()
	if Input.is_action_just_pressed("action"):
		debug()

func _checkOnlineChunks():
	var position = player.position
	playerChunkPosition = Main.transformChunkPosition(position)
	
	$info.text = "position: %10.2f, %10.2f, %10.2f\t\t chunk: %s,%s,%s" % [position.x, position.y, position.z, playerChunkPosition.x, playerChunkPosition.y, playerChunkPosition.z]
	$info2.text = "fps:%s \t\t load chunks %s \t\t blocks: %s" % [Engine.get_frames_per_second(), 0, Main.blocksCount]
	
	for x in range(playerChunkPosition.x - Main.horizon, playerChunkPosition.x + Main.horizon + 1):
		for y in range(playerChunkPosition.y - Main.horizon, playerChunkPosition.y + Main.horizon + 1):
			for z in range(playerChunkPosition.z - Main.horizon, playerChunkPosition.z + Main.horizon + 1):
				var chunkKey = Main.formatKey(x, y, z)
				if not Main.chunks.has(chunkKey):
					Main.instanceChunk(self, x, y, z)
					loadChunks.push_back(chunkKey)

func _checkRemoveChunks():
	pass
	#var removeChunks = []
	#for i in range(len(Main.chunksList)):
	#	var key = Main.chunksList[i]
	#	var chunk = Main.chunks[key]
	#	var playerDistace = Vector3(playerChunkPosition).distance_to(Vector3(chunk.chunkPosition))
	#	if playerDistace > Main.deleteHorizon:
	#		Main.removeChunk(key)
	#		print("removeChunk %s - %s" % [key, playerDistace])
	#		return

func _loadChunks():
	# check if is loading
	if _selectedGenerateChunk != null:
		if _selectedGenerateChunk.state == _selectedGenerateChunk.STATE_ENABLED:
			print("finish load chunk %s" % _selectedGenerateChunk.chunkKey)
			_selectedGenerateChunk = null
		return
		
	if len(loadChunks) > 0:
		# Select next chunk
		var bestChunkIndex = 0
		var bestChunk: Chunk = null
		var bestDistance = 0
		for i in range(len(loadChunks)):
			var chunkKey = loadChunks[i]
			var chunk = Main.chunks[chunkKey]
			var distance = Vector3(playerChunkPosition).distance_squared_to(Vector3(chunk.chunkPosition))
			if (distance < bestDistance || i == 0):
				bestChunkIndex = i
				bestChunk = chunk
				bestDistance = distance
		if bestChunk != null:
			bestChunk.startLoad()
			print("startLoad chunk %s" % bestChunk.chunkKey)
			_selectedGenerateChunk = bestChunk
			loadChunks = loadChunks.filter(func (key): return key != bestChunk.chunkKey)

func debug():
	print("debug")
	
	print(ProjectSettings.globalize_path("res://cone.obj"))
	print(ProjectSettings.globalize_path("user://cone.obj"))
	
	var success = ProjectSettings.load_resource_pack("./../assets/fox.zip", false)
	print(success)
	if success:
		var filename = "res://skins";
		dir_contents(filename)
		loadModel("pfox.gltf")

func dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func loadModel(filename):
		filename = "res://skins/%s" % filename;
		print(FileAccess.file_exists(filename))
		var scene = load(filename)
		print(scene)
		var obj: Node3D = scene.instantiate()
		print(obj)
		obj.position = Vector3(1,1,1)
		add_child(obj)
		for i in range(obj.get_child_count()):
			var anim = obj.get_child(i)
			if anim as AnimationPlayer:
				var animAttack = anim.get_animation("Attack")
				animAttack.loop_mode = Animation.LOOP_LINEAR
				anim.play("Attack")

func _exit_tree():
	pass
