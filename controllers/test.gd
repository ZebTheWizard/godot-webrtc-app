extends Page


func _mount(data:Dictionary):
	pass


func _on_start_signaling_server_pressed() -> void:
	$SignalingServer.start_server()


func _on_connect_to_signaling_server_pressed() -> void:
	$Client.connect_to_signaling_server()


func _on_send_test_to_signaling_server_pressed() -> void:
	$Client.send_test_message()


func _on_send_test_to_signaling_client_pressed() -> void:
	$SignalingServer.send_test_message()


func _on_create_match_pressed() -> void:
	$Client.create_match()


func _on_home_pressed() -> void:
	navigate_to('home', {'title': 'something'})
