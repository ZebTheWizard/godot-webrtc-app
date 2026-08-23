extends Control

signal pressed

@export var match_data:Dictionary

@onready var _name = $"%Name"
@onready var _uuid = $"%Uuid"
@onready var _link = $"%LinkButton"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_name.text = match_data.get('name', "Match Title")
	_uuid.text = match_data.get('id', "ab055ab6-b0ec-4cc8-a5ed-1ec9523ef0ca")
	_link.pressed.connect(func (): pressed.emit())
