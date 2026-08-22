@tool
class_name UI_Button extends Control

signal pressed

@export var text: String

@onready var _button = $Button

func _ready() -> void:
	_button.pressed.connect(pressed.emit)

func _process(delta: float) -> void:
	_button.text = text
