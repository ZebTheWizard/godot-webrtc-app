extends Node

signal connected
signal error(error:Dictionary)
signal login_success(player:Dictionary)
signal signup_success
signal matches(matches:Array)
signal match_create_success
signal match_connected(_match:Dictionary)
signal match_disconnected(data:Dictionary)
signal lobby(players:Dictionary)
signal webrtc_established

var ws : WebSocketPeer = WebSocketPeer.new()
var rtc : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var established: bool = false
var id = 0
var rtc_id = 0
var match_id
var server

func _ready() -> void:
	if CommandLine.options.has('server'):
		set_process(false)
	var debug = DotEnv.get_env("APP_DEBUG")
	server = "ws://127.0.0.1:8000" if debug else "wss://wss.snowbuilds.com"

func _process(_delta: float) -> void:
	connect_to_signaling_server()
	ws.poll()
	rtc.poll()
	if ws.get_available_packet_count() > 0:
		var packet = ws.get_packet()
		if packet != null:
			var msgString = packet.get_string_from_utf8()
			var msg = JSON.parse_string(msgString)

			if msg is not Dictionary:
				return
				
			msg.set('type', msg.get('type'))
			msg.set('data', msg.get('data', {}))
			
			if msg.type == Enum.message.ID:
				id = msg.data.id
				established = true
				print('Client %s connected to server' % id)
				if CommandLine.options.has('username'):
					login({
						'username': CommandLine.options.get('username'),
						'password': CommandLine.options.get('password')
					})
				connected.emit()
			elif msg.type == Enum.message.ERROR:
				error.emit(msg.data)
			elif msg.type == Enum.message.LOGIN_SUCCESS:
				login_success.emit(msg.data)
			elif msg.type == Enum.message.SIGNUP_SUCCESS:
				signup_success.emit()
			elif msg.type == Enum.message.MATCH_CREATE_SUCCESS:
				match_create_success.emit()
			elif msg.type == Enum.message.MATCH_LIST:
				matches.emit(msg.data)
			elif msg.type == Enum.message.MATCH_CONNECTED:
				match_id = msg.data.get("id")
				rtc_id = 1 if id == msg.data.get('host_client_id') else id
				establish_multiplayer_networking(rtc_id)
				match_connected.emit(msg.data)
			elif msg.type == Enum.message.MATCH_DISCONNECTED:
				match_id = null
				match_disconnected.emit(msg.data)
			elif msg.type == Enum.message.LOBBY:
				lobby.emit(msg.data)
			elif msg.type == Enum.message.MATCH_START:
				_on_match_start(msg.data)
			elif msg.type == Enum.message.WEBRTC_EXCHANGE:
				if rtc.has_peer(msg.data.get('origin')):
					print("Got WebRTC Candididate: peer: %s, rtc_id: %s" % [msg.data.get('origin'), rtc_id])
					rtc.get_peer(msg.data.get('origin')).connection.add_ice_candidate(msg.data.get('mid'), msg.data.get('index'), msg.data.get('sdp'))
			elif msg.type == Enum.message.WEBRTC_OFFER:
				if rtc.has_peer(msg.data.get('origin')):
					rtc.get_peer(msg.data.get('origin')).connection.set_remote_description("offer", msg.data.get('rtcData'))
			elif msg.type == Enum.message.WEBRTC_ANSWER:
				if rtc.has_peer(msg.data.get('origin')):
					rtc.get_peer(msg.data.get('origin')).connection.set_remote_description("answer", msg.data.get('rtcData'))
			
			else:
				print(msg)

func create_match(data:Dictionary):
	send_ws_message({
		"type": Enum.message.MATCH_CREATE,
		'data': data
	})
	
func join_match(data:Dictionary):
	send_ws_message({
		'type': Enum.message.MATCH_JOIN,
		'data': data
	})
	
func leave_match(data:Dictionary):
	send_ws_message({
		'type': Enum.message.MATCH_LEAVE,
		'data': data
	})
	
func get_matches():
	send_ws_message({
		"type": Enum.message.MATCH_LIST,
	})
	
func get_lobby(lobby_id):
	send_ws_message({
		"type": Enum.message.LOBBY,
		'data': {
			'id': lobby_id
		}
	})
	
func login(data:Dictionary):
	send_ws_message({
		'type': Enum.message.LOGIN,
		'data': data,
	})
	
func signup(data:Dictionary):
	send_ws_message({
		'type': Enum.message.SIGNUP,
		'data': data,
	})

func connect_to_signaling_server():
	if ws.get_ready_state() == WebSocketPeer.State.STATE_CLOSED:
		established = false
		ws.connect_to_url(server)

func establish_multiplayer_networking(client_id):
	rtc.create_mesh(client_id)
	multiplayer.multiplayer_peer = rtc
	multiplayer.peer_connected.connect(_on_rtc_connected)
	multiplayer.peer_disconnected.connect(_on_rtc_disconnected)
	
func connect_to_rtc_peers():
	send_ws_message({
		'type': Enum.message.MATCH_START,
		'data': {
			'id': match_id
		}
	})
	
	
func _on_match_start(peers):	
	for peer in peers:
		var peer_rtc_id = 1 if peer.get('is_host') else peer.get('client_id')
		create_peer(peer_rtc_id, peer.get('is_host'))
		
func create_peer(client_id, peer_is_host):
	var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	
	peer.session_description_created.connect(_on_rtc_offer_created.bind(client_id))
	peer.ice_candidate_created.connect(_on_rtc_ice_candidate_created.bind(client_id))
	rtc.add_peer(peer, client_id)

	if not peer_is_host:
		peer.create_offer()
	
func _on_rtc_offer_created(type, data, client_id):
	if !rtc.has_peer(client_id):
		return
		
	rtc.get_peer(client_id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendRtcOffer(client_id, data)
	else:
		sendRtcAnswer(client_id, data)

func sendRtcOffer(client_id, data):
	send_ws_message({
		"type": Enum.message.WEBRTC_OFFER,
		"data": {
			"peer": client_id,
			"origin": self.rtc_id,
			"rtcData": data,
			"match_id": match_id,
		}
	})

func sendRtcAnswer(client_id, data):
	send_ws_message({
		"type": Enum.message.WEBRTC_ANSWER,
		"data": {
			"peer": client_id,
			"origin": self.rtc_id,
			"rtcData": data,
			"match_id": match_id,
		}
	})

func _on_rtc_ice_candidate_created(midName, indexName, sdpName, client_id):
	send_ws_message({
		"type": Enum.message.WEBRTC_EXCHANGE,
		"data": {
			"peer": client_id,
			"origin": self.rtc_id,
			"mid": midName,
			"index": indexName,
			"sdp": sdpName,
			"match_id": match_id,
		}
	})

func _on_rtc_connected(_peer_id):
	if not multiplayer.is_server():
		return
	if _are_all_peers_connected():
		webrtc_established.emit()

func _on_rtc_disconnected(_peer_id):
	pass
	
func _are_all_peers_connected() -> bool:
	var peers = rtc.get_peers()
	
	if peers.is_empty():
		return false
		
	for peer_id in peers:
		var connection = peers[peer_id].connection
		if connection.get_connection_state() != WebRTCPeerConnection.STATE_CONNECTED:
			return false
			
	return true

	
func send_ws_message(message: Dictionary):
	message.set('id', id)
	ws.put_packet(JSON.stringify(message).to_utf8_buffer())
