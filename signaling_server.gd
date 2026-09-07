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
	LOBBY,
	MATCH_JOIN,
	MATCH_CONNECTED,
	MATCH_LEAVE,
	MATCH_DISCONNECTED,
	MATCH_START,
	WEBRTC_OFFER,
	WEBRTC_ANSWER,
	WEBRTC_EXCHANGE
}

@export var port: int = 8001

var peer : WebSocketMultiplayerPeer
var db : DAO
var crypto : CryptoUtils
var clients: Dictionary

func _ready() -> void:
	if CommandLine.options.has('server'):
		start_server()

func _process(_delta: float) -> void:
	if not peer or not db:
		return
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
			elif msg.type == message.MATCH_JOIN:
				join_match(msg.id, msg.data)
			elif msg.type == message.MATCH_LEAVE:
				leave_match(msg.id, msg.data)
			elif msg.type == message.MATCH_LIST:
				list_matches(msg.id)
			elif msg.type == message.LOGIN:
				login(msg.id, msg.data)
			elif msg.type == message.SIGNUP:
				signup(msg.id, msg.data)
			elif msg.type == message.LOBBY:
				get_lobby(msg.id, msg.data)
			elif msg.type == message.MATCH_START:
				start_match(msg.id, msg.data)
			elif msg.type == message.WEBRTC_OFFER || msg.type == message.WEBRTC_ANSWER || msg.type == message.WEBRTC_EXCHANGE:
				send_message_to(msg.data.get('peer'), {
					'type': msg.type,
					'data': msg.data
				})
			else:
				print(msg)

func create_match(client_id, data):
	var error = {}
	var match_name = data.get('name', '').strip_edges()
	if len(match_name) < 3:
		error.name = "Match name must be at least 3 characters."
	if data.get('map') not in db.map:
		error.map = "Unknown map"
	var player = db.get_player_by_client_id(client_id)
	if not player:
		error.general = "Player %s not found." % client_id

	if not error.is_empty():
		return send_message_to(client_id, {
			'type': message.MATCH_CREATE_ERROR,
			'data': error
		})

	var _match = db.insert_match({
		'name': match_name,
		'map': data.get('map'),
		'password': crypto.HashPassword(data.get('password')),
		'host_id': player.get('id')
	})

	db.update_player_by_client_id(player.get('client_id'), {
		'is_host': true,
		'match_id': _match.get('id'),
		'client_id': client_id
	})

	send_message({
		'type': message.MATCH_LIST,
		'data': db.get_matches()
	})

	send_message_to(client_id, {
		'type': message.MATCH_CONNECTED,
		'data': GD_.omit(_match, ['password'])
	})

func join_match(client_id, data):
	var player = db.get_player_by_client_id(client_id)
	var _match = db.get_match_by_id(data.get('id'))
	if player and _match:
		db.update_player_by_client_id(client_id, {
			'match_id': _match.get('id')
		})

		send_message_to(client_id, {
			'type': message.MATCH_CONNECTED,
			'data': GD_.omit(_match, ['password'])
		})

		var players = db.get_players_by_match_id(_match.get('id'))
		for p in players:
			send_message_to(p.get('client_id'), {
				'type': message.LOBBY,
				'data': players
			})

func leave_match(client_id, _data):
	var player = db.get_player_by_client_id(client_id)
	if player:
		var players = db.get_players_by_match_id(player.get('match_id'))
		if player.get('is_host'):
			db.delete_match_by_id(player.get('match_id'))
			send_message({
				'type': message.MATCH_LIST,
				'data': db.get_matches()
			})
			db.update_player_by_client_id(client_id, {
				'is_host': false,
			})
			for p in players:
				var disconnect_data = {}
				if p.get('client_id') != client_id:
					disconnect_data.set('message', 'The host has left the match.')
				send_message_to(p.get('client_id'), {
					'type': message.MATCH_DISCONNECTED,
					'data': disconnect_data
				})
		else:
			db.update_player_by_client_id(client_id, {
				'is_host': false,
				'match_id': null,
			})

			send_message_to(client_id, {
				'type': message.MATCH_DISCONNECTED,
			})

			for p in players:
				if p.get('client_id') == client_id:
					continue
				send_message_to(p.get('client_id'), {
					'type': message.LOBBY,
					'data': players
				})


func start_match(client_id, data):
	var players:Array = db.get_players_by_match_id(data.get('id'))
	var host = players.filter(func (p): return p.get('is_host')).get(0)
	if host.get('client_id') == client_id:
		for player in players:
			var peers = players.filter(func(p): return p.get('client_id') != player.get('client_id'))
			send_message_to(player.get('client_id'), {
				'type': message.MATCH_START,
				'data': peers
			})

func list_matches(client_id):
	send_message_to(client_id, {
		'type': message.MATCH_LIST,
		'data': db.get_matches()
	})

func get_lobby(client_id, data):
	send_message_to(client_id, {
		'type': message.LOBBY,
		'data': db.get_players_by_match_id(data.get('id'))
	})

func login(client_id, data):
	var error = {}
	if client_id not in clients:
		error.general = "Invalid client_id."
	print('Login: ', data)
	var player = db.get_player_by_username(data.get('username'))
	if not player:
		error.username = 'Invalid username'
		#error.username = 'Invalid username or password'
		#error.password = 'Invalid username or password'
	else:
		print('player: ', player)
		if player.password != crypto.HashPassword(data.get('password')):
			print('password: %s %s' % [player.password, crypto.HashPassword(data.get('password'))])
			error.password = 'Invalid password'
			#error.username = 'Invalid username or password'
			#error.password = 'Invalid username or password'
	if not error.is_empty():
		return send_message_to(client_id,{
			'type': message.LOGIN_ERROR,
			'data': error
		})

	db.update_player_by_username(player.username, {
		'client_id': client_id
	})

	player = db.get_player_by_client_id(client_id)

	send_message_to(client_id,{
		'type': message.LOGIN_SUCCESS,
		'data': GD_.omit(player, ['password'])
	})

func signup(client_id, data):
	var error = {}
	if client_id not in clients:
		error.general = "Invalid client_id."
	var username = data.get('username').strip_edges()
	if len(username) < 3:
		error.username = "Username must be at least 3 characters"
	else:
		var player = db.get_player_by_username(data.get('username'))
		if player:
			error.username = "Username already exists."
	if data.get('password') != data.get('password_confirm'):
		error.password = "Passwords do not match."
	if len(data.get('password')) < 8:
		error.password = "Password must be at least 8 characters"
	if not error.is_empty():
		return send_message_to(client_id,{
			'type': message.SIGNUP_ERROR,
			'data': error
		})
	var new_player = db.insert_player({
		'username': username,
		'password': crypto.HashPassword(data.get('password')),
		'client_id': client_id
	})
	if new_player:
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
	var player = db.get_player_by_client_id(id)
	if player and player.get('match_id'):
		leave_match(id, {
			'id': player.get('match_id')
		})
	clients.erase(id)

func start_server():
	var version = get_git_version()
	peer = WebSocketMultiplayerPeer.new()
	db = DAO.new()
	crypto = CryptoUtils.new()
	clients = {}
	var server_error = peer.create_server(port, "0.0.0.0")
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	print('starting server on port: %s, version: %s' % [port, version])
	var app_key = DotEnv.get_env('APP_KEY')
	var salt = app_key if not app_key.is_empty() else crypto.GenerateSalt()
	print("APP_KEY=%s" % salt)
	return server_error == 0

func send_message_to(id:int, json:Dictionary):
	print("server to %s: %s" % [id, json])
	peer.get_peer(id).put_packet(JSON.stringify(json).to_utf8_buffer())

func send_message(json:Dictionary):
	peer.put_packet(JSON.stringify(json).to_utf8_buffer())

func send_test_message():
	send_message({
		"type": message.TEST,
		"data": "test server to client"
	})

func get_git_version() -> String:
	var config = ConfigFile.new()
	if config.load("res://version.cfg") == OK:
		return config.get_value("version", "commit", "dev-local")
	return "dev-local"

	
