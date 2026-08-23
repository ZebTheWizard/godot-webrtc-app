extends Page

@onready var _submit = $"%Submit"
@onready var _login = $"%Login"
@onready var _username = $"%Username"
@onready var _password = $"%Password"
@onready var _password_confirm = $"%Password Confirmation"

func _mount(data:Dictionary):
	print('signup mounted')
	bind_visibility()
	_submit.pressed.connect(_on_submit_pressed)
	_login.pressed.connect(_on_login_pressed)
	Client.connected.connect(_on_connected)
	Client.signup_success.connect(_on_signup_success)
	Client.signup_error.connect(_on_signup_error)
	
func _on_connected():
	print('connected on submit page')
	bind_visibility()
	
func _on_submit_pressed():
	Client.signup({
		'username': _username.text,
		'password': _password.text,
		'password_confirm': _password_confirm.text
	})
	
func _on_signup_success():
	navigate_to('matches')
	
func _on_signup_error(error:Dictionary):
	_username.error = error.get('username', "")
	_password.error = error.get('password', "")
	
	
func _on_login_pressed():
	navigate_to('login')
	
func bind_visibility():
	_submit.disabled = not Client.established
