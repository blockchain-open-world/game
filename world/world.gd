extends Node3D

const NetworkMessage = preload("res:///networking/network_message.gd")
const OtherPlayer = preload("res://mobs/other_players.tscn")
const BlockType = preload("res://block/block.gd")

@onready var player = $player

var playerChunkPosition = Vector3i.ZERO

var _selectedGenerateChunk:Chunk = null
var loadChunks = []
var loadCount = 0
var _rng = RandomNumberGenerator.new()

var playerId = int(floor(_rng.randf() * 0xFFFFFFFF))
var _sharePositionMessage: NetworkMessage = null
var _sharePositionUptime:float = 11.0
const DELAY_SHARE_POSITION = 10

var _updateMapMessage: NetworkMessage = null
var _updateMapUptime:float = 0
const DELAY_UPDATE_MAP = 1

# multiplayer feature
@onready var client = $Client
var _lobbyPlayers = []

func _ready():
	client.lobby_joined.connect(self._lobby_joined)
	client.lobby_sealed.connect(self._lobby_sealed)
	client.connected.connect(self._connected)
	client.disconnected.connect(self._disconnected)
	
	multiplayer.connected_to_server.connect(self._mp_server_connected)
	multiplayer.connection_failed.connect(self._mp_server_disconnect)
	multiplayer.server_disconnected.connect(self._mp_server_disconnect)
	multiplayer.peer_connected.connect(self._mp_peer_connected)
	multiplayer.peer_disconnected.connect(self._mp_peer_disconnected)
	
	client.start("main", true)

func _process(delta):
	_updatePlayers(delta)
	_multiplayerProcess(delta)
	_updateMap(delta)
	_checkOnlineChunks()
	_checkRemoveChunks()
	_loadChunks()
	#if Input.is_action_just_pressed("action"):
		#client.start("main", true)
		#updatePosition.rpc(player.position, player.mouse_vector)
		#debug()

func _updateMap(delta):
	_updateMapUptime += delta
	if _updateMapUptime < DELAY_UPDATE_MAP:
		return;
	_updateMapUptime = 0
	
	if _updateMapMessage == null:
		_updateMapMessage = Network.updateMap(playerId)
	elif _updateMapMessage.received:
		while _updateMapMessage.hasNext():
			var blockInfo = Main.arrayToBlockInfo(_updateMapMessage)
			var newBlockKey = Main.formatKey(blockInfo.x, blockInfo.y, blockInfo.z)
			if Main.blocks.has(newBlockKey):
				if blockInfo.t == 0:
					Main.removeBlock(newBlockKey)
				else:
					var currentblock:BlockType = Main.blocks[newBlockKey]
					BlockRender.updateBlock(blockInfo, currentblock)
			elif blockInfo.t != 0:
				Main.instanceBlock(blockInfo)
		Network.clearMessage(_updateMapMessage)
		_updateMapMessage = null

func _updatePlayers(delta):
	_sharePositionUptime += delta
	if _sharePositionUptime < DELAY_SHARE_POSITION:
		return;
	_sharePositionUptime = 0
	if _sharePositionMessage == null:
		var playerPosition = player.position
		_sharePositionMessage = Network.sharePosition(playerId, playerPosition)
	else:
		if _sharePositionMessage.received:
			Network.clearMessage(_sharePositionMessage)
			_sharePositionMessage = null

func _checkOnlineChunks():
	var playerPosition = player.position
	playerChunkPosition = Main.transformChunkPosition(playerPosition)
	
	$info.text = "position: %10.2f, %10.2f, %10.2f\t\t chunk: %s,%s,%s" % [playerPosition.x, playerPosition.y, playerPosition.z, playerChunkPosition.x, playerChunkPosition.y, playerChunkPosition.z]
	$info2.text = "fps:%s \t\t network %s \t\t loading chunks %s \t\t chunks: %s \t\t blocks: %s" % [Engine.get_frames_per_second(), len(Network._messagesToSend), len(loadChunks), Main.chunksCount, Main.blocksCount]
	
	for x in range(playerChunkPosition.x - Main.horizon, playerChunkPosition.x + Main.horizon + 1):
		for y in range(playerChunkPosition.y - Main.horizon, playerChunkPosition.y + Main.horizon + 1):
			for z in range(playerChunkPosition.z - Main.horizon, playerChunkPosition.z + Main.horizon + 1):
				var chunkKey = Main.formatKey(x, y, z)
				if not Main.chunks.has(chunkKey):
					Main.instanceChunk(self, x, y, z)
					loadChunks.push_back(chunkKey)

func _checkRemoveChunks():
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
	$player.start = true
	if len(loadChunks) > 0:
		# Select next chunk
		var bestChunk: Chunk = null
		var bestDistance = 0
		for i in range(len(loadChunks)):
			var chunkKey = loadChunks[i]
			var chunk = Main.chunks[chunkKey]
			var distance = Vector3(playerChunkPosition).distance_squared_to(Vector3(chunk.chunkPosition))
			if (distance < bestDistance || i == 0):
				bestChunk = chunk
				bestDistance = distance
		if bestChunk != null:
			bestChunk.startLoad()
			_selectedGenerateChunk = bestChunk
			loadChunks = loadChunks.filter(func (key): return key != bestChunk.chunkKey)

func _multiplayerProcess(_delta):
	updatePosition.rpc(player.position, player.mouse_vector)
	
	var timeout = Time.get_ticks_msec() - 1000
	for i in range(len(_lobbyPlayers)):
		var op:OtherPlayer = _lobbyPlayers[i]
		if op.update < timeout:
			remove_child(op)
			
	_lobbyPlayers = _lobbyPlayers.filter(func (op): return op.update >= timeout)

@rpc("any_peer", "call_local")
func updatePosition(playerPosition:Vector3, angle:Vector2):
	var id = multiplayer.get_remote_sender_id()
	if id != multiplayer.get_unique_id():
		var found = false
		for i in range(len(_lobbyPlayers)):
			var op:OtherPlayer = _lobbyPlayers[i]
			if op.id == id:
				op.currentPosition = playerPosition
				op.currentAngle = angle
				op.update = Time.get_ticks_msec()
				found = true
		if not found:
			var op = OtherPlayer.instantiate()
			op.id = id
			op.currentPosition = playerPosition
			op.currentAngle = angle
			op.update = Time.get_ticks_msec()
			add_child(op)
			_lobbyPlayers.push_back(op)

func _connected(id, success):
	print("[Signaling] Server connected with ID: %d - %s" % [id, success])

func _disconnected():
	print("[Signaling] Server disconnected: %d - %s" % [client.code, client.reason])

func _lobby_joined(lobby):
	print("[Signaling] Joined lobby %s" % lobby)

func _lobby_sealed():
	print("[Signaling] Lobby has been sealed")

func _mp_server_connected():
	print("[Multiplayer] Server connected (I am %d)" % client.rtc_mp.get_unique_id())

func _mp_server_disconnect():
	print("[Multiplayer] Server disconnected (I am %d)" % client.rtc_mp.get_unique_id())

func _mp_peer_connected(id: int):
	print("[Multiplayer] Peer %d connected" % id)

func _mp_peer_disconnected(id: int):
	print("[Multiplayer] Peer %d disconnected" % id)

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
