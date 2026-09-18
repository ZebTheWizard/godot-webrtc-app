extends CanvasLayer

@onready var _start_signaling_server:Button = $"%Start Signaling Server"
var is_debug: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_debug = DotEnv.get_env('APP_DEBUG') == "true"
	$"%UserPanel".hide()
	$"%Version".text = get_git_version()
	$"%Server".text = Client.server
	if CommandLine.options.has('is-server'):
		_on_start_signaling_server_pressed()
	_start_signaling_server.pressed.connect(_on_start_signaling_server_pressed)
	_start_signaling_server.visible = is_debug
	Client.login_success.connect(_on_login_success)
	

func _process(_delta: float) -> void:
	if is_debug:
		_start_signaling_server.visible = not Client.established

func _on_start_signaling_server_pressed():
	if is_debug:
		ServerRunner.start()
	

func _on_login_success(player: Dictionary):
	$"%UserPanel".show()
	$"%VersionPanel".hide()
	$"%Username".text = str(player.get('username'))
	$"%ClientID".text = str(player.get('client_id'))

func get_git_version() -> String:
	var config = ConfigFile.new()
	if config.load("res://version.cfg") == OK:
		return config.get_value("version", "commit", "dev-local")
	return "dev-local"
