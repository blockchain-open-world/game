extends Node

const Contants = preload("res://constants.gd")

var _httpServer = HTTPRequest.new()
var _httpOpenRequest = null
var _socket = WebSocketPeer.new()
var _rng = RandomNumberGenerator.new()
var _messages = []
var _messagesToSend = []

func _http_start(scene):
	scene.add_child(_httpServer)
	var tls = TLSOptions.client_unsafe()
	_httpServer.set_tls_options(tls)
	_httpServer.request_completed.connect(_on_request_completed)

func _http_stop():
	pass

func _http_process():
	if _httpOpenRequest != null:
		return #wait request ends
	for i in range(len(_messagesToSend)):
		_httpOpenRequest = _messagesToSend[i]
		var json = JSON.stringify(_httpOpenRequest)
		var headers = ["Content-Type: application/json"]
		var url = Contants.server_url % _httpOpenRequest.method
		print(url)
		_httpServer.request(url, headers, HTTPClient.METHOD_POST, json)

		_messagesToSend = _messagesToSend.filter(func (m): return m.id != _httpOpenRequest.id)
		print("send %s" % json)

func _on_request_completed(result, response_code, headers, body):
	var json = body.get_string_from_utf8()
	print("response %s" % result)
	var response = JSON.parse_string(json)
	_httpOpenRequest.response = response.data
	_httpOpenRequest.received = true
	_httpOpenRequest = null

func _socket_start():
	var tls = TLSOptions.client_unsafe()
	_socket.max_queued_packets = 1
	_socket.encode_buffer_max_size = 1
	_socket.connect_to_url(Contants.websocket_url, tls)

func _socket_stop():
	_socket.close(0, "exec _socket_stop")

func _socket_process():
	var state = _socket.get_ready_state()
	if state == WebSocketPeer.STATE_CONNECTING || state == WebSocketPeer.STATE_OPEN:
		_socket.poll()
	else:
		return;
	if state == WebSocketPeer.STATE_OPEN:
		for i in range(len(_messagesToSend)):
			var jsonMsg = JSON.stringify(_messagesToSend[i])
			_socket.send_text(jsonMsg)
		_messagesToSend = []
		while _socket.get_available_packet_count():
			var error = _socket.get_packet_error()
			print(error)
			var response = _socket.get_packet().get_string_from_utf8()
			print(response)
			response = JSON.parse_string(response)
			for i in range(len(_messages)):
				var msg = _messages[i]
				if msg.id == response.id:
					msg.response = response.data
					msg.received = true
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _socket.get_close_code()
		var reason = _socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])

func start(scene):
	_socket_start()
	#_http_start(scene)

func process():
	_socket_process()
	#_http_process()

func stop():
	_socket_stop()
	#_http_stop()

func send(method, data):
	var msg = {}
	msg.id = _rng.randi()
	msg.data = data
	msg.method = method
	msg.response = {}
	msg.received = false
	_messages.push_back(msg)
	_messagesToSend.push_back(msg)
	return msg;

func clearMessage(msg):
	_messages = _messages.filter(func (m): return m.id != msg.id)
	_messagesToSend = _messagesToSend.filter(func (m): return m.id != msg.id)
