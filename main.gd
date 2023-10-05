extends Node

var Chunk = preload("res://chunk/chunk.tscn")
var Block = preload("res://block/block.tscn")
const TestBlock = preload("res://block/block.glb")

const tile000 = preload("res://chunk/textures/tile000.png")
const tile001 = preload("res://chunk/textures/tile001.png")
const tile002 = preload("res://chunk/textures/tile002.png")
const tile003 = preload("res://chunk/textures/tile003.png")
const tile016 = preload("res://chunk/textures/tile016.png")
const tile022 = preload("res://chunk/textures/tile022.png")

var blockMaterial = {};

const CHUNK_SIZE = 16

const FACES_RIGHT:int = 1
const FACES_LEFT:int = 2
const FACES_BACK:int = 4
const FACES_FRONT:int = 8
const FACES_BOTTOM:int = 16
const FACES_TOP:int = 32

var horizon = 2
var deleteHorizon = 5

var chunksList = []
var chunksMap = {}

const websocket_url = "wss://node1.blockchainopenworld.com/connect"
var socket = WebSocketPeer.new()
var rng = RandomNumberGenerator.new()
var messages = []
var messagesToSend = []

func socket_start():
	var tls = TLSOptions.client_unsafe()
	socket.connect_to_url(websocket_url, tls)

func socket_process(delta):
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_CONNECTING || state == WebSocketPeer.STATE_OPEN:
		socket.poll()
	else:
		return;
	if state == WebSocketPeer.STATE_OPEN:
		for i in range(len(messagesToSend)):
			var jsonMsg = JSON.stringify(messagesToSend[i])
			socket.send_text(jsonMsg)
		messagesToSend = []
		while socket.get_available_packet_count():
			var response = socket.get_packet().get_string_from_utf8()
			print(response)
			response = JSON.parse_string(response)
			for i in range(len(messages)):
				var msg = messages[i]
				if msg.id == response.id:
					msg.response = response.data
					msg.received = true
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

func socket_send(method, data):
	var msg = {}
	msg.id = rng.randi()
	msg.data = data
	msg.method = method
	msg.response = {}
	msg.received = false
	messages.append(msg)
	messagesToSend.append(msg)
	print(JSON.stringify(msg))
	return msg;

func socket_clearMessage(msg):
	messages = messages.filter(func (m): return m.id != msg.id)

func formatKey(x, y, z):
	return ("i_%s_%s_%s" % [x, y, z]).replace("-", "n")
	
func instanceChunk(chunkX, chunkY, chunkZ):
	var chunkKey = formatKey(chunkX, chunkY, chunkZ)
	var chunk = Chunk.instantiate()
	chunk.chunkPosition = Vector3i(chunkX, chunkY, chunkZ)
	chunk.position = Vector3(CHUNK_SIZE * chunkX, CHUNK_SIZE * chunkY, CHUNK_SIZE * chunkZ)
	chunk.chunkKey = chunkKey
	chunksMap[chunkKey] = chunk
	chunksList.push_back(chunkKey)
	return chunk

func removeChunk(chunkKey):
	if chunksMap.has(chunkKey):
		var chunk = chunksMap[chunkKey]
		chunksMap.erase(chunkKey)
		chunksList = chunksList.filter(func (key): return key != chunkKey)
		chunk.queue_free()

func transformChunkPosition(position):
	var chunkPosition = Vector3i(
		int(floor(float(position.x) / Main.CHUNK_SIZE)),
		int(floor(float(position.y) / Main.CHUNK_SIZE)),
		int(floor(float(position.z) / Main.CHUNK_SIZE))
	)
	return chunkPosition

func transformChunkLocalPosition(position):
	var chunkLocalPosition = Vector3(
		position.x % CHUNK_SIZE,
		position.y % CHUNK_SIZE,
		position.z % CHUNK_SIZE
	)
	if chunkLocalPosition.x < 0:
		chunkLocalPosition.x = CHUNK_SIZE + chunkLocalPosition.x
	if chunkLocalPosition.y < 0:
		chunkLocalPosition.y = CHUNK_SIZE + chunkLocalPosition.y
	if chunkLocalPosition.z < 0:
		chunkLocalPosition.z = CHUNK_SIZE + chunkLocalPosition.z
	return chunkLocalPosition

func getChunkByBlockPosition(position):
	var chunkPosition = transformChunkPosition(position)
	var chunkKey = formatKey(chunkPosition.x, chunkPosition.y, chunkPosition.z)
	return chunksMap[chunkKey]
	
func instanceBlock(blockInfo):
	var blockKey = formatKey(blockInfo.x, blockInfo.y, blockInfo.z)
	
	var blockInstance = Block.instantiate()
	
	var faces: int = int(blockInfo.m)
	
	var material = _getMaterialBlock(blockInfo.t)
	if faces & FACES_RIGHT:
		blockInstance.get_child(5).queue_free()
	else:
		var face = blockInstance.get_child(5)
		face.material_override = material[face.name]
		
	if faces & FACES_LEFT:
		blockInstance.get_child(4).queue_free()
	else:
		var face = blockInstance.get_child(4)
		face.material_override = material[face.name]
		
	if faces & FACES_BACK:
		blockInstance.get_child(3).queue_free()
	else:
		var face = blockInstance.get_child(3)
		face.material_override = material[face.name]
		
	if faces & FACES_FRONT:
		blockInstance.get_child(2).queue_free()
	else:
		var face = blockInstance.get_child(2)
		face.material_override = material[face.name]
		
	if faces & FACES_BOTTOM:
		blockInstance.get_child(1).queue_free()
	else:
		var face = blockInstance.get_child(1)
		face.material_override = material[face.name]
		
	if faces & FACES_TOP:
		blockInstance.get_child(0).queue_free()
	else:
		var face = blockInstance.get_child(0)
		face.material_override = material[face.name]
	
	blockInstance.globalPosition = Vector3i(blockInfo.x, blockInfo.y, blockInfo.z)
	blockInstance.blockKey = blockKey
	blockInstance.type = blockInfo.t
	
	blockInstance.position = transformChunkLocalPosition(blockInstance.globalPosition)
	return blockInstance;

func _getMaterialBlock(type):
	if not blockMaterial.has(type):
		if type == 1:
			blockMaterial[type] = _getMaterialType1()
		elif type == 2:
			blockMaterial[type] = _getMaterialType2()
		elif type == 3:
			blockMaterial[type] = _getMaterialType3()
		elif type == 4:
			blockMaterial[type] = _getMaterialType4()
		elif type == 5:
			blockMaterial[type] = _getMaterialType5()
		else:
			assert(false, "invalid type %s" % type)
	return blockMaterial[type]

func _getMaterialType1():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile000
	
	var side = StandardMaterial3D.new()
	side.albedo_texture = tile003
	
	var bottom = StandardMaterial3D.new()
	bottom.albedo_texture = tile002
	
	material["top"] = top
	material["bottom"] = bottom
	material["left"] = side
	material["right"] = side
	material["front"] = side
	material["back"] = side
	return material
	
func _getMaterialType2():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile002
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material

func _getMaterialType3():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile001
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material
	
func _getMaterialType4():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile016
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material

func _getMaterialType5():
	var material = {}
	var top = StandardMaterial3D.new()
	top.albedo_texture = tile022
	
	material["top"] = top
	material["bottom"] = top
	material["left"] = top
	material["right"] = top
	material["front"] = top
	material["back"] = top
	return material
