extends Page

@onready var _submit = $"%Submit"
@onready var _login = $"%Login"

func _mount(data:Dictionary):
	print('signup mounted')
	_submit.pressed.connect(_on_submit_pressed)
	_login.pressed.connect(_on_login_pressed)

func _on_submit_pressed():
	navigate_to('matches')
	
func _on_login_pressed():
	navigate_to('login')
