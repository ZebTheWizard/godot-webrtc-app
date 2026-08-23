extends Node

# TODO:
# - Manage matches
#   - Assign first peer in match as the host/offerer
#   - Assign remaining peers as clients/answerers
# - Forward SDP offer
# - Forward SDP answer
# - Exchange ICE Candidates

enum message {
	TEST, # test messages
	ID, # ws peer id
	LOGIN,
	LOGIN_SUCCESS,
	LOGIN_ERROR,
	SIGNUP,
	SIGNUP_SUCCESS,
	SIGNUP_ERROR,
	MATCH_CREATE,
	MATCH_CREATE_SUCCESS,
	MATCH_CREATE_ERROR,
	MATCH_LIST,
	MATCH_JOIN,
	MATCH_CONNECTED,
	MATCH_DISCONNECTED,
	MATCH_INFO,
	WEBRTC_OFFER,
	WEBRTC_ANSWER,
	WEBRTC_EXCHANGE
}

@export var port: int = 8000

var peer : WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
var db : DAO = DAO.new()
var crypto : CryptoUtils = CryptoUtils.new()
var clients: Dictionary = {}

func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args():
		start_server()

func _process(delta: float) -> void:
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var msgString = packet.get_string_from_utf8()
			var msg = JSON.parse_string(msgString)
			
			if msg is not Dictionary:
				return
				
			msg.set('type', msg.get('type'))
			msg.set('id', msg.get('id', 0) as int)
			msg.set('data', msg.get('data', {}))
			
			if msg.type == message.MATCH_CREATE:
				create_match(msg.id, msg.data)
			elif msg.type == message.MATCH_LIST:
				list_matches(msg.id)
			elif msg.type == message.LOGIN:
				login(msg.id, msg.data)
			elif msg.type == message.SIGNUP:
				signup(msg.id, msg.data)
			else:
				print(msg)

func create_match(client_id, data):
	var error = {}
	var name = data.get('name', '').strip_edges()
	if len(name) < 3:
		error.name = "Match name must be at least 3 characters."
	if data.get('map') not in db.map:
		error.map = "Unknown map"
	
	if not error.is_empty():
		return send_message_to(client_id, {
			'type': message.MATCH_CREATE_ERROR,
			'data': error
		})
	
	var _match = db.insert_match({
		'name': name,
		'map': data.map,
		'password': crypto.HashPassword(data.password)
	})
	
	send_message({
		'type': message.MATCH_LIST,
		'data': db.get_matches()
	})
	
func list_matches(client_id):
	send_message_to(client_id, {
		'type': message.MATCH_LIST,
		'data': db.get_matches()
	})
	
func login(client_id, data):
	var error = {}
	if client_id not in clients:
		error.general = "Invalid client_id."
	var player = db.get_player_by_username(data.username)
	if not player:
		error.username = 'Invalid username or password'
		error.password = 'Invalid username or password'
	else:
		if player.password != crypto.HashPassword(data.password):
			error.username = 'Invalid username or password'
			error.password = 'Invalid username or password'
	if not error.is_empty():
		return send_message_to(client_id,{
			'type': message.LOGIN_ERROR,
			'data': error
		})
	
	send_message_to(client_id,{
		'type': message.LOGIN_SUCCESS
	})
	
func signup(client_id, data):
	var error = {}
	if client_id not in clients:
		error.general = "Invalid client_id."
	var username = data.username.strip_edges()
	if len(username) < 3:
		error.username = "Username must be at least 3 characters"
	else:
		var player = db.get_player_by_username(data.username)
		if player:
			error.username = "Username already exists."
	if data.password != data.password_confirm:
		error.password = "Passwords do not match."
	if len(data.password) < 8:
		error.password = "Password must be at least 8 characters"
	if not error.is_empty():
		return send_message_to(client_id,{
			'type': message.SIGNUP_ERROR,
			'data': error
		})
	db.insert_player({
		'username': username,
		'password': crypto.HashPassword(data.password),
		'client_id': client_id
	})
	send_message_to(client_id, {
		'type': message.SIGNUP_SUCCESS
	})

func _on_peer_connected(id):
	print('peer connected: %s' % id)
	clients.set(id as int, id)
	send_message_to(id, {
		"type": message.ID,
		"data": {
			"id": id
		}
	})
	
func _on_peer_disconnected(id):
	clients.erase(id)
	pass

func start_server():
	var server_error = peer.create_server(port)
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	print('starting server')
	var app_key = DotEnv.get_env('APP_KEY')
	var salt = app_key if not app_key.is_empty() else crypto.GenerateSalt()
	print("APP_KEY=%s" % salt)
	return server_error == 0

func send_message_to(id:int, message:Dictionary):
	peer.get_peer(id).put_packet(JSON.stringify(message).to_utf8_buffer())

func send_message(message:Dictionary):
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func send_test_message():
	send_message({
		"type": message.TEST,
		"data": "test server to client"
	})
