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
			
			if msg.type == message.MATCH_CREATE:
				create_match()
			elif msg.type == message.LOGIN:
				print(msg)
				login(msg.data)
			else:
				print(msg)

func create_match():
	var _match = db.insert_match()
	print(_match)
	
func login(data):
	print('trying to login. username %s, password %s' % [data.username, data.password])

func _on_peer_connected(id):
	print('peer connected: %s' % id)
	send_message({
		"type": message.ID,
		"data": {
			"id": id
		}
	})
	
func _on_peer_disconnected(id):
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

func send_message(message:Dictionary):
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func send_test_message():
	send_message({
		"type": message.TEST,
		"data": "test server to client"
	})
