extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")
const MainScene = preload("res://gameplay/main_game.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: -- <scenario path> <output png> [zoom]")
		quit(2)
		return
	ScenarioType.requested_path = str(args[0])
	ScenarioType.requested_autostart = true
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.camera.zoom = Vector2.ONE * (float(args[2]) if args.size() > 2 else 1.5)
	# Frame a representative gameplay area instead of the empty map edge.
	game.player.position = Vector2(12.0, 8.0) * game.CELL_SIZE
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(str(args[1]))
	if result != OK: push_error("Could not save screenshot: %s" % result)
	quit(0 if result == OK else 1)
