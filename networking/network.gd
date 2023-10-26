extends Node

const Contants = preload("res://classes/constants.gd")
const NetworkMessage = preload("res://networking/network_message.gd")

const METHOD_GET_CHUNK = 1
const METHOD_MINT_BLOCK = 2
const METHOD_SHARE_POSITION = 3
const METHOD_UPDATE_MAP = 4

var _httpServer = HTTPRequest.new()
var _httpOpenRequest = null
var _socket = WebSocketPeer.new()
var _socket_last_state
var _sentMessage: NetworkMessage
var _messagesSent = []
var _rng = RandomNumberGenerator.new()
var _messages = []
var _messagesToSend = []
const _useWebsockets = true

func _http_start():
	add_child(_httpServer)
	var tls = TLSOptions.client_unsafe()
	_httpServer.set_tls_options(tls)
	_httpServer.request_completed.connect(_on_request_completed)

func _http_stop():
	pass

func _http_process():
	if _httpOpenRequest != null:
		return #wait request ends
	if len(_messagesToSend) > 0:
		_httpOpenRequest = _messagesToSend.pop_front()
		var json = JSON.stringify(_httpOpenRequest)
		var headers = ["Content-Type: application/json"]
		var url = Contants.server_url % _httpOpenRequest.method
		_httpServer.request(url, headers, HTTPClient.METHOD_POST, json)

func _on_request_completed(result, response_code, _headers, body):
	if result and response_code == 200:
		var json = body.get_string_from_utf8()
		var response = JSON.parse_string(json)
		_httpOpenRequest.response = response.data
		_httpOpenRequest.received = true
		_httpOpenRequest = null
	else:
		print("_on_request_completed result = %s" % result)

func _socket_start():
	var tls = TLSOptions.client_unsafe()
	_socket.max_queued_packets = 100
	_socket.encode_buffer_max_size = 1000000
	_socket.inbound_buffer_size = 1000000
	_socket.outbound_buffer_size = 1000000
	_socket.connect_to_url(Contants.websocket_url, tls)

func _socket_stop():
	_socket.close(0, "exec _socket_stop")

func _socket_process():
	_socket.poll()
	var state = _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		# print state
		if state != _socket_last_state:
			print("WebSocket connected")
		# resend old messages
		if _sentMessage != null:
			var now = Time.get_ticks_msec()
			if now > _sentMessage.timeout:
				_sentMessage.timeout = Time.get_ticks_msec() + Contants.timeout
				_socket.send(_sentMessage.data)
		# send new messages
		if _sentMessage == null && len(_messagesToSend) > 0:
			_sentMessage = NetworkMessage.new()
			_sentMessage.timeout = Time.get_ticks_msec() + Contants.timeout
			_sentMessage.id = int(floor(_rng.randf() * 0xFFFF))
			_sentMessage.data = PackedByteArray([0,0])
			_sentMessage.data.encode_u16(0, _sentMessage.id)
			_sentMessage.received = false
			var count = 0
			for i in range(len(_messagesToSend)):
				if count > 20:
					break
				var msg: NetworkMessage = _messagesToSend[i]
				var sendData = PackedByteArray([0,0,0,0,0,0])
				sendData.encode_u16(0, msg.method)
				sendData.encode_u32(2, msg.data.size())
				sendData.append_array(msg.data)
				_sentMessage.data.append_array(sendData)
				_messagesSent.push_back(msg)
				count+=1
			_socket.send(_sentMessage.data)
		# receive messages
		while _sentMessage != null && _socket.get_available_packet_count():
			var byteArray = _socket.get_packet();
			var index = 0;
			var messageId:int = byteArray.decode_u16(index)
			index+=2
			if messageId == _sentMessage.id:
				for i in range(len(_messagesSent)):
					var msg: NetworkMessage = _messagesSent[i]
					var size:int = byteArray.decode_u32(index)
					index+=4
					msg.response = byteArray.slice(index, index + size)
					index += size
					msg.responseIndex = 0;
					msg.received = true;
					_messagesToSend = _messagesToSend.filter(func (m): return m.id != msg.id)
					#print("msg.response %s - %s" % [i, msg.response.size()])
				_messagesSent = []
				_sentMessage = null
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _socket.get_close_code()
		var reason = _socket.get_close_reason()
		if state != _socket_last_state:
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		_socket_start()
	_socket_last_state = state

func _ready():
	if _useWebsockets:
		_socket_start()
	else:
		_http_start()

func _process(_delta):
	if _useWebsockets:
		_socket_process()
	else:
		_http_process()

func _exit_tree():
	if _useWebsockets:
		_socket_stop()
	else:
		_http_stop()

func _send(method:int, data: PackedByteArray):
	var msg:NetworkMessage = NetworkMessage.new()
	msg.id = int(floor(_rng.randf() * 0xFFFF))
	msg.method = method
	msg.data = data
	msg.received = false
	_messages.push_back(msg)
	_messagesToSend.push_back(msg)
	return msg;

func clearMessage(msg:NetworkMessage):
	_messages = _messages.filter(func (m): return m.id != msg.id)
	_messagesToSend = _messagesToSend.filter(func (m): return m.id != msg.id)

func getChunk(position: Vector3i):
	var data = PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0])
	data.encode_s32(0, position.x)
	data.encode_s32(4, position.y)
	data.encode_s32(8, position.z)
	return _send(Network.METHOD_GET_CHUNK, data)

func mintBlock(position: Vector3i):
	var data = PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0])
	data.encode_s32(0, position.x)
	data.encode_s32(4, position.y)
	data.encode_s32(8, position.z)
	return _send(Network.METHOD_MINT_BLOCK, data)

func sharePosition(playerId:int, position: Vector3):
	var data = PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
	data.encode_u32(0, playerId)
	data.encode_s32(4, (int) (position.x))
	data.encode_s32(8, (int) (position.y))
	data.encode_s32(12, (int) (position.z))
	return _send(Network.METHOD_SHARE_POSITION, data)

func updateMap(playerId:int):
	var data = PackedByteArray([0,0,0,0])
	data.encode_u32(0, playerId)
	return _send(Network.METHOD_UPDATE_MAP, data)
