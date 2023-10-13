extends Node3D

const NetworkMessage = preload("res://classes/network_message.gd")
const OtherPlayer = preload("res://mobs/other_players.tscn")

@onready var player = $player

var playerChunkPosition = Vector3i.ZERO

var _selectedGenerateChunk:Chunk = null
var loadChunks = []
var loadCount = 0
var _rng = RandomNumberGenerator.new()

var playerId = int(floor(_rng.randf() * 65534) - 32767)
var _uptimePlayerPosition = 0
var _playerPosition: NetworkMessage = null
var _otherPlayers = []

func _ready():
	pass

func _process(delta):
	_updateMultiplayerPositions(delta)
	_checkOnlineChunks()
	_checkRemoveChunks()
	_loadChunks()
	if Input.is_action_just_pressed("action"):
		debug()

func _updateMultiplayerPositions(delta):
	if _playerPosition == null:
		_uptimePlayerPosition += delta
		if _uptimePlayerPosition < 0.5: # deplay
			return;
		_uptimePlayerPosition = 0
	
		var playerPosition = player.position
		var playerAngle = player.mouse_vector
		var data = PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0,0,0])
		data.encode_s16(0, Network.METHOD_CHANGE_POSITION)
		data.encode_s16(2, playerId)
		data.encode_s16(4, playerPosition.x * 10)
		data.encode_s16(6, playerPosition.y * 10)
		data.encode_s16(8, playerPosition.z * 10)
		data.encode_s16(10, playerAngle.x * 10)
		data.encode_s16(12, playerAngle.y * 10)
		_playerPosition = Network.send(data)
	else:
		if _playerPosition.received:
			for i in range(len(_otherPlayers)):
				_otherPlayers[i].update = false
			while _playerPosition.hasNext():
				var id = _playerPosition.getInteger()
				var position = Vector3.ZERO
				position.x = _playerPosition.getInteger() / 10.0
				position.y = _playerPosition.getInteger() / 10.0
				position.z = _playerPosition.getInteger() / 10.0
				var angle = Vector2.ZERO
				angle.x = _playerPosition.getInteger() / 10.0
				angle.y = _playerPosition.getInteger() / 10.0
				if id != playerId:
					var found = false
					for i in range(len(_otherPlayers)):
						var op:OtherPlayer = _otherPlayers[i]
						if op.id == id:
							op.currentPosition = position
							op.currentAngle = angle
							op.update = true
							found = true
					if not found:
						var op = OtherPlayer.instantiate()
						op.id = id
						op.currentPosition = position
						op.currentAngle = angle
						op.update = true
						add_child(op)
						_otherPlayers.push_back(op)
			Network.clearMessage(_playerPosition)
			_playerPosition = null
			for i in range(len(_otherPlayers)):
				var op:OtherPlayer = _otherPlayers[i]
				if not op.update:
					remove_child(op)
			_otherPlayers = _otherPlayers.filter(func (op): return op.update)
		
func _checkOnlineChunks():
	var position = player.position
	playerChunkPosition = Main.transformChunkPosition(position)
	
	$info.text = "position: %10.2f, %10.2f, %10.2f\t\t chunk: %s,%s,%s" % [position.x, position.y, position.z, playerChunkPosition.x, playerChunkPosition.y, playerChunkPosition.z]
	$info2.text = "fps:%s \t\t load chunks %s \t\t chunks: %s \t\t blocks: %s" % [Engine.get_frames_per_second(), len(loadChunks), Main.chunksCount, Main.blocksCount]
	
	for x in range(playerChunkPosition.x - Main.horizon, playerChunkPosition.x + Main.horizon + 1):
		for y in range(playerChunkPosition.y - Main.horizon, playerChunkPosition.y + Main.horizon + 1):
			for z in range(playerChunkPosition.z - Main.horizon, playerChunkPosition.z + Main.horizon + 1):
				var chunkKey = Main.formatKey(x, y, z)
				if not Main.chunks.has(chunkKey):
					Main.instanceChunk(self, x, y, z)
					loadChunks.push_back(chunkKey)

func _checkRemoveChunks():
	var removeChunks = []
	for i in range(len(Main.chunksList)):
		var chunkKey = Main.chunksList[i]
		var chunk = Main.chunks[chunkKey]
		var playerDistace = player.position.distance_to(chunk.position)
		if playerDistace > Main.deleteHorizon * Main.CHUNK_SIZE:
			Main.removeChunk(chunkKey)
			loadChunks = loadChunks.filter(func (key): return key != chunkKey)
			return

func _loadChunks():
	# check if is loading
	if _selectedGenerateChunk != null:
		if _selectedGenerateChunk.state == _selectedGenerateChunk.STATE_ENABLED:
			_selectedGenerateChunk = null
			loadCount += 1
			if loadCount == 9:
				$player.start = true
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
