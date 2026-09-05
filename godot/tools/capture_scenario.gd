extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")
const MainScene = preload("res://gameplay/main_game.tscn")
const TimeTravelStateType = preload("res://world/time_travel/time_travel_state.gd")


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
	# Captures must never consume narrative events or mutate the player's saves.
	TimeTravelStateType.persistence_enabled = false
	TimeTravelStateType.loaded = false
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.camera.zoom = Vector2.ONE * (float(args[2]) if args.size() > 2 else 1.5)
	# Frame a representative gameplay area instead of the empty map edge.
	var capture_cell := Vector2(float(args[3]), float(args[4])) if args.size() > 4 else Vector2(12.0, 8.0)
	game.player.position = capture_cell * game.CELL_SIZE
	if args.size() > 5:
		if str(args[5]) == "pause":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			game.set_pause_open(true)
		elif str(args[5]) == "dialogue":
			game._close_splash()
			if not game.dialogue_open:
				game.dialogue_queue.append({"id":"qa_preview", "speaker":"THE TIME TRAVELER", "text":"I am a traveler through time. These portals lead to civilizations that need my help - and to fragments of a past I can no longer remember."})
				game._show_next_dialogue()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(str(args[1]))
	if result != OK: push_error("Could not save screenshot: %s" % result)
	quit(0 if result == OK else 1)
