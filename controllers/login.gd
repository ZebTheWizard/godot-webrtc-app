extends Page

@onready var _submit = $"%Submit"
@onready var _sign_up = $"%Sign up"
@onready var _username = $"%Username"
@onready var _password = $"%Password"

func _mount(data:Dictionary):
	bind_visibility()
	_submit.pressed.connect(_on_submit_pressed)
	_sign_up.pressed.connect(_on_sign_up_pressed)
	Client.connected.connect(_on_connected)
	Client.login_success.connect(_on_login_success)
	Client.login_error.connect(_on_login_error)
	
func _on_submit_pressed():
	Client.login({
		'username': _username.text,
		'password': _password.text
	})
	
func _on_connected():
	bind_visibility()
	
func _on_login_success():
	navigate_to('matches')
	
func _on_login_error(error):
	_username.error = error.get('username', '')
	_password.error = error.get('password', '')

func _on_sign_up_pressed():
	navigate_to('signup')

func bind_visibility():
	_submit.disabled = not Client.established
