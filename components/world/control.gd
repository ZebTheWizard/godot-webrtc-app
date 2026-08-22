extends Page


func _mount(data:Dictionary):
	pass


func _on_test_pressed() -> void:
	open_page('test')


func _on_home_pressed() -> void:
	open_page('home', {'title': 'thing'})
