extends Page

@onready var _players = $"%Players"
@onready var _start = $"%Start"
@onready var _leave = $"%Leave"

var players_buffer
var players
var auto_refresh = true
var _player = load("uid://7qjqg48o0rfq")
var match_data

func _mount(data:Dictionary):
	match_data = data
	_start.pressed.connect(_on_start_pressed)
	_leave.pressed.connect(_on_leave_pressed)
	Client.get_lobby(data.get('id'))
	Client.lobby.connect(_on_lobby_ready)
	Client.match_disconnected.connect(_on_match_disconnect)
	Client.webrtc_established.connect(_on_webrtc_established)

func refresh_players():
	players = players_buffer
	for child in _players.get_children():
		child.queue_free()

	for player in players:
		var item = _player.instantiate()
		item.player = player
		_players.add_child(item)

func _on_match_disconnect(data:Dictionary):
	navigate_to('matches')
	if data.has('message'):
		print('MATCH DISCONNECT: ', data)


func _on_lobby_ready(new_players:Array):
	players_buffer = new_players
	if auto_refresh or players.is_empty():
		refresh_players()

func _on_webrtc_established():
	start_game.rpc()
	
@rpc('authority', 'call_local', 'reliable')
func start_game():
	print('match should be starting for: ', multiplayer.get_unique_id(), ' message from: ', multiplayer.get_remote_sender_id())
	navigate_to('test')

func _on_start_pressed():
	Client.connect_to_rtc_peers()

func _on_leave_pressed():
	Client.leave_match({
		'id': match_data.get('id')
	})
