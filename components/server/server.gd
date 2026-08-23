extends CanvasLayer

@onready var _start_signaling_server:Button = $"%Start Signaling Server"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_signaling_server.pressed.connect(_on_start_signaling_server_pressed)
	_start_signaling_server.visible = DotEnv.get_env('APP_DEBUG') == "true"


func _on_start_signaling_server_pressed():
	var started = SignalingServer.start_server()
	if started:
		_start_signaling_server.hide()
