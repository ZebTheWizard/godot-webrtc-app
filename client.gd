extends Node

# TODO:
# - Create WebRTCMultiplayerPeer
# - Create peer mesh using id from signaling server
# - Link godot's multiplayer api to webrtc
# - Setup WebRTC peer connection
#   - Intialize ice servers
#   - Setup event listeners
#   - Add peer
#   - If host: make offer
#   - If peer: make answer?

signal connected
signal login_success(player:Dictionary)
signal login_error(error:Dictionary)
signal signup_success
signal signup_error(error:Dictionary)
signal matches(matches:Array)
signal match_create_success
signal match_create_error(error:Dictionary)
signal match_connected(_match:Dictionary)
signal match_disconnected(data:Dictionary)
signal lobby(players:Dictionary)

var ws : WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
var rtc : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var established: bool = false
var id = 0

func _ready() -> void:
	if CommandLine.options.has('server'):
		set_process(false)

func _process(delta: float) -> void:
	connect_to_signaling_server()
	ws.poll()
	if ws.get_available_packet_count() > 0:
		var packet = ws.get_packet()
		if packet != null:
			var msgString = packet.get_string_from_utf8()
			var msg = JSON.parse_string(msgString)
			
			if msg is not Dictionary:
				return
				
			msg.set('type', msg.get('type'))
			msg.set('data', msg.get('data', {}))
			
			if msg.type == SignalingServer.message.ID:
				establish_multiplayer_networking(msg.data.id)
				id = msg.data.id
				established = true
				print('client connected to server:', CommandLine.arguments, CommandLine.options)
				if CommandLine.options.has('username'):
					print('needs to login from cli')
					login({
						'username': CommandLine.options.get('username'),
						'password': CommandLine.options.get('password')
					})
				connected.emit()
			elif msg.type == SignalingServer.message.LOGIN_SUCCESS:
				login_success.emit(msg.data)
			elif msg.type == SignalingServer.message.LOGIN_ERROR:
				login_error.emit(msg.data)
			elif msg.type == SignalingServer.message.SIGNUP_SUCCESS:
				signup_success.emit()
			elif msg.type == SignalingServer.message.SIGNUP_ERROR:
				signup_error.emit(msg.data)
			elif msg.type == SignalingServer.message.MATCH_CREATE_SUCCESS:
				match_create_success.emit()
			elif msg.type == SignalingServer.message.MATCH_CREATE_ERROR:
				match_create_error.emit(msg.data)
			elif msg.type == SignalingServer.message.MATCH_LIST:
				matches.emit(msg.data)
			elif msg.type == SignalingServer.message.MATCH_CONNECTED:
				match_connected.emit(msg.data)
			elif msg.type == SignalingServer.message.MATCH_DISCONNECTED:
				match_disconnected.emit(msg.data)
			elif msg.type == SignalingServer.message.LOBBY:
				lobby.emit(msg.data)
			else:
				print(msg)

func create_match(data:Dictionary):
	send_ws_message({
		"type": SignalingServer.message.MATCH_CREATE,
		'data': data
	})
	
func join_match(data:Dictionary):
	send_ws_message({
		'type': SignalingServer.message.MATCH_JOIN,
		'data': data
	})
	
func leave_match(data:Dictionary):
	send_ws_message({
		'type': SignalingServer.message.MATCH_LEAVE,
		'data': data
	})
	
func get_matches():
	send_ws_message({
		"type": SignalingServer.message.MATCH_LIST,
	})
	
func get_lobby(id):
	send_ws_message({
		"type": SignalingServer.message.LOBBY,
		'data': {
			'id': id
		}
	})
	
func login(data:Dictionary):
	send_ws_message({
		'type': SignalingServer.message.LOGIN,
		'data': data,
	})
	
func signup(data:Dictionary):
	send_ws_message({
		'type': SignalingServer.message.SIGNUP,
		'data': data,
	})

func connect_to_signaling_server():
	var server = DotEnv.get_env("APP_SERVER")
	if not server:
		server = "ws://127.0.0.1:8001"
	if ws.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_DISCONNECTED:
		ws.create_client(server)

func establish_multiplayer_networking(id):
	rtc.create_mesh(id)
	multiplayer.multiplayer_peer = rtc
	print('established multiplayer network strategy')
	
func send_test_message():
	send_ws_message({
		"type": SignalingServer.message.TEST,
		"data": "test client to server"
	})
	
func send_ws_message(message: Dictionary):
	message.set('id', id)
	print('client sending:', message)
	ws.put_packet(JSON.stringify(message).to_utf8_buffer())
