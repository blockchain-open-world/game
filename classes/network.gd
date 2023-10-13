extends Node

const Contants = preload("res://classes/constants.gd")
const NetworkMessage = preload("res://classes/network_message.gd")

const METHOD_GET_CHUNK = 1
const METHOD_MINT_BLOCK = 2
const METHOD_CHANGE_POSITION = 3

var _httpServer = HTTPRequest.new()
var _httpOpenRequest = null
var _socket = WebSocketPeer.new()
var _socket_last_state
var _sentMessage: NetworkMessage
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

func _on_request_completed(result, response_code, headers, body):
	var json = body.get_string_from_utf8()
	var response = JSON.parse_string(json)
	_httpOpenRequest.response = response.data
	_httpOpenRequest.received = true
	_httpOpenRequest = null

func _socket_start():
	var tls = TLSOptions.client_unsafe()
	_socket.max_queued_packets = 1
	_socket.encode_buffer_max_size = 1
	_socket.connect_to_url(Contants.websocket_url, tls)
	_socket.set_no_delay(false)

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
				resend(_sentMessage)
				_sentMessage = null
		# send new messages
		if _sentMessage == null && len(_messagesToSend) > 0:
			_sentMessage = _messagesToSend.pop_back()
			var sendData = PackedByteArray([0,0])
			sendData.encode_s16(0, _sentMessage.id)
			sendData.append_array(_sentMessage.data)
			var error = _socket.send(sendData)
			print("send: %s" % _sentMessage.id)
		# receive messages
		while _sentMessage != null &&  _socket.get_available_packet_count():
			var error = _socket.get_packet_error()
			var byteStream = _socket.get_packet();
			var messageId:int = byteStream.decode_s16(0);
			print("received: %s - len %s" % [messageId, byteStream.size()])
			if messageId == _sentMessage.id:
				_sentMessage.response = byteStream
				_sentMessage.responseIndex = 2;
				_sentMessage.received = true
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

func _process(delta):
	if _useWebsockets:
		_socket_process()
	else:
		_http_process()

func _exit_tree():
	if _useWebsockets:
		_socket_stop()
	else:
		_http_stop()

func send(data: PackedByteArray):
	var msg:NetworkMessage = NetworkMessage.new()
	msg.timeout = Time.get_ticks_msec() + Contants.timeout
	msg.id = int(floor(_rng.randf() * 65534) - 32767)
	msg.data = data
	msg.received = false
	_messages.push_back(msg)
	_messagesToSend.push_back(msg)
	return msg;

func resend(msg:NetworkMessage):
	msg.timeout = Time.get_ticks_msec() + Contants.timeout
	_messagesToSend.push_back(msg)
	return msg;

func clearMessage(msg:NetworkMessage):
	_messages = _messages.filter(func (m): return m.id != msg.id)
	_messagesToSend = _messagesToSend.filter(func (m): return m.id != msg.id)
