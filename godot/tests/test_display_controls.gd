extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var packed: PackedScene = load("res://main.tscn")
	var game_root: Node = packed.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	_expect(InputMap.has_action("zoom_in") and InputMap.has_action("zoom_out"), "Mouse-wheel zoom actions should exist.", failures)
	_expect(InputMap.has_action("toggle_fullscreen"), "Fullscreen toggle action should exist.", failures)
	_expect(is_equal_approx(game.camera.zoom.x, 1.0), "Camera should begin at readable 1x zoom.", failures)
	var wheel_up := InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	game._unhandled_input(wheel_up)
	_expect(is_equal_approx(game.camera.zoom.x, 1.25), "Mouse wheel up should choose the next discrete zoom level.", failures)
	game.adjust_camera_zoom(20)
	_expect(is_equal_approx(game.camera.zoom.x, 2.0), "Zoom in should clamp at 2x.", failures)
	game.adjust_camera_zoom(-20)
	_expect(is_equal_approx(game.camera.zoom.x, 0.75), "Zoom out should clamp at 0.75x.", failures)
	game.set_scenario_select_open(false)
	game.set_pause_open(true)
	var menu_labels: Array[String] = []
	for child: Node in game.pause_panel.get_children():
		if child is Button: menu_labels.append((child as Button).text)
	_expect(menu_labels == ["NEW GAME", "CONTINUE", "SAVE", "LOAD", "QUIT"], "Pause menu should expose only the five requested actions in order.", failures)
	game_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: display controls")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
