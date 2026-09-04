extends Page

var _match = load("uid://okuqgksk67gi")

@onready var _auto_refresh = $"%AutoRefresh"
@onready var _refresh = $"%Refresh"
@onready var _create = $"%Create"
@onready var _name = $"%Name"
@onready var _map = $"%Map"
@onready var _password = $"%Password"
@onready var _matches = $"%Matches"

var auto_refresh = false
var matches_buffer: Array
var matches:Array

func _mount(data:Dictionary):
	bind_visibility()
	_auto_refresh.button_pressed = false
	_auto_refresh.toggled.connect(_on_auto_refresh_change)
	_refresh.pressed.connect(_on_refresh_pressed)
	_create.pressed.connect(_on_create_pressed)
	Client.connected.connect(_on_connected)
	Client.matches.connect(_on_matches_changed)
	Client.match_create_success.connect(_on_create_success)
	Client.match_create_error.connect(_on_create_error)
	Client.match_connected.connect(_on_match_connected)
	Client.get_matches()

func refresh_matches():
	matches = matches_buffer
	for child in _matches.get_children():
		child.queue_free()

	for match_data in matches:
		var item = _match.instantiate()
		item.match_data = match_data
		item.pressed.connect(func (): Client.join_match({'id': match_data.id}))
		_matches.add_child(item)

func bind_visibility():
	_create.disabled = not Client.established

func _on_connected():
	bind_visibility()
	Client.get_matches()

func _on_create_pressed():
	Client.create_match({
		'name': _name.text,
		'map': _map.text if not _map.text.is_empty() else "DEFAULT",
		'password': _password.text,
	})

func _on_create_success():
	print('created match')

func _on_create_error(error:Dictionary):
	_name.error = error.get('name', "")
	_map.error = error.get("map", "")
	print(error)

func _on_auto_refresh_change(value:bool):
	_refresh.visible = not value
	auto_refresh = value

func _on_refresh_pressed():
	refresh_matches()

func _on_matches_changed(matches: Array):
	matches_buffer = matches
	if auto_refresh or self.matches.is_empty():
		refresh_matches()

func _on_match_connected(_match:Dictionary):
	navigate_to('lobby', _match)
