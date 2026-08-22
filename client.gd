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
signal login_success
signal login_error(error:Dictionary)
signal signup_success
signal signup_error(error:Dictionary)

var ws : WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
var rtc : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()

func _process(delta: float) -> void:
	ws.poll()
	if ws.get_available_packet_count() > 0:
		var packet = ws.get_packet()
		if packet != null:
			var msgString = packet.get_string_from_utf8()
			var msg = JSON.parse_string(msgString)
			
			if msg.type == SignalingServer.message.ID:
				establish_multiplayer_networking(msg.data.id)
				connected.emit()
			else:
				print(msg)

func create_match():
	send_ws_message({
		"type": SignalingServer.message.MATCH_CREATE
	})
	
func login(data:Dictionary):
	send_ws_message({
		'type': SignalingServer.message.LOGIN,
		'data': data,
	})

func connect_to_signaling_server():
	if ws.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_DISCONNECTED:
		ws.create_client("ws://127.0.0.1:8000")

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
	ws.put_packet(JSON.stringify(message).to_utf8_buffer())
