@tool
class_name UI_Input extends VBoxContainer

enum InputType {
	Text,
	Password
}

@export var type: InputType = InputType.Text:
	set(value):
		type = value
		bind_type(value)
	get:
		return type

@export var label:String:
	set(value):
		label = value
		bind_label(value)
	get:
		return label
		
@export var placeholder:String:
	set(value):
		placeholder = value
		bind_placeholder(value)
	get:
		return placeholder
		
@export var error:String:
	set(value):
		error = value
		bind_error(value)
	get:
		return error
		
@export var text:String:
	set(value):
		text = value
		bind_text(value)
	get:
		return text

@onready var _label = $label
@onready var _input = $input
@onready var _error = $error
@onready var _action = $action

func _ready() -> void:
	bind_type(type)
	bind_label(label)
	bind_placeholder(placeholder)
	bind_error(error)
	bind_text(text)
	_action.pressed.connect(_on_action_pressed)
	_input.text_changed.connect(_on_text_changed)

func _on_action_pressed():
	if type == InputType.Password:
		_input.secret = not _input.secret
		if _input.secret:
			_action.text = "Reveal"
		else:
			_action.text = "Hide"

func bind_type(value):
	if is_node_ready() and _input and _action:
		_input.secret = value == InputType.Password
		_action.visible = value == InputType.Password
		_action.text = "Reveal"

func bind_label(value):
	if is_node_ready() and _label:
		_label.visible = not _is_empty(value)
		_label.text = value	
		
func bind_placeholder(value):
	if is_node_ready() and _input:
			_input.placeholder_text = value

func bind_error(value):
	if is_node_ready() and _error:
		_error.visible = not _is_empty(value)
		_error.text = value

func _on_text_changed(value):
	text = value

func bind_text(value):
	if is_node_ready() and _input and _input.text != value:
		_input.text = value

func _is_empty(str:String):
	return str.strip_edges() == "" or str == null
