@icon ("res://addons/at-icons/control/file.svg")
class_name Page extends Control

var routes = {
	&"home": &"uid://bo7fwuv0ubdix",
	&"test": &"uid://bx5jespx80q7w",
	&"login": &"uid://dn4gyop62f76g",
	&"signup": &"uid://nhpfn15f23g3",
	&"matches": &"uid://somyxj455r1v",
	&"404": &"uid://cio3senb4sfjx"
}

var parent_page: Page
var mounted: bool = false
var _data: Dictionary

func _ready() -> void:
	_initialize(_data)

func _initialize(data:Dictionary={}):
	if not mounted:
		_mount(data)
	mounted = true

func _mount(data:Dictionary):
	pass
	
func navigate_to(routeName:String, data:Dictionary={}):
	var page_path = routes.get(routeName, routes.get('404'))
	var page_scene = load(page_path) as PackedScene
	if page_scene:
		var page = page_scene.instantiate()
		
		if page is Page:
			page._data = data
			page.parent_page = self.parent_page
			get_parent().add_child(page)
			queue_free()
		else:
			push_error("page %s not an instance of Page" % [routeName])
	else:
		push_error("page %s with path %s not found" % [routeName, page_path])

func open_page(routeName:String, data:Dictionary={}):
	var page_path = routes.get(routeName, routes.get('404'))
	var page_scene = load(page_path) as PackedScene
	if page_scene:
		var page = page_scene.instantiate()
		
		if page is Page:
			page._data = data
			page.parent_page = self
			get_parent().add_child(page)
		else:
			push_error("page %s not an instance of Page" % [routeName])
	else:
		push_error("page %s with path %s not found" % [routeName, page_path])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		if parent_page:
			queue_free()
