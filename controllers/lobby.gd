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
	print('mounting lobby: %s' % data.get('id'))
	_start.pressed.connect(_on_start_pressed)
	_leave.pressed.connect(_on_leave_pressed)
	Client.get_lobby(data.get('id'))
	Client.lobby.connect(_on_lobby_ready)
	
func refresh_players():
	players = players_buffer
	print('refresh players', players)
	for child in _players.get_children():
		child.queue_free()
		
	for player in players:
		var item = _player.instantiate()
		item.player = player
		_players.add_child(item)
	
func _on_lobby_ready(players:Array):
	players_buffer = players
	if auto_refresh or self.players.is_empty():
		refresh_players()
		
func _on_start_pressed():
	print('start pressed')
	
func _on_leave_pressed():
	print('leave pressed')
	Client.leave_match({
		'id': match_data.get('id')
	})
