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
		elif str(args[5]) == "living":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			game.set_living_open(true)
		elif str(args[5]) == "night":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			game.day_time_seconds = game.DAY_LENGTH_SECONDS * 0.86
			game._update_living_light()
		elif str(args[5]) == "decor":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			game.inventory.add("village_lantern", 1); game.select_quick_slot(0); game.begin_placement(); game.confirm_placement()
		elif str(args[5]) == "machine" and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			game.inventory.add("windmill_plan", 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = Vector2i(19, 10); game.confirm_placement()
			var machine_id: String = game.world_grid.occupant_at(Vector2i(19, 10)); var site: Variant = game.construction_by_entity_id.get(machine_id)
			if site != null:
				for item_id: String in site.requirements: game.inventory.add(item_id, site.receivable(item_id)); site.deliver(item_id, site.receivable(item_id))
				game.apply_construction_work(machine_id, 30.0); game.inventory.add("wheat", 7); game.open_machine(machine_id)
		elif str(args[5]) == "calendar" and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			game.campaign.completed_entities["KEEP"] = true; game._begin_timeline_day(false); game.set_calendar_open(true)
		elif str(args[5]) == "winter" and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			game.meta_progression.season_index = 3; game.meta_progression.day = 6; game._begin_timeline_day(false); game._update_living_light()
		elif str(args[5]) == "rain" and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			game.meta_progression.season_index = 1; game.meta_progression.day = 6; game._begin_timeline_day(false); game._update_living_light()
		elif str(args[5]) == "novelty" and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			var previews := [{"item":"chicken_coop_plan","cell":Vector2i(15,8)},{"item":"herb_garden_plan","cell":Vector2i(21,8)},{"item":"apiary_plan","cell":Vector2i(27,8)},{"item":"astronomer_tower_plan","cell":Vector2i(34,7)}]
			for row: Dictionary in previews:
				game.player.position = Vector2(row.cell + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0; game.player.facing = "south"
				game.inventory.add(str(row.item), 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = row.cell; game.confirm_placement()
				var instance_id: String = game.world_grid.occupant_at(row.cell); var site: Variant = game.construction_by_entity_id.get(instance_id)
				if site != null:
					for item_id: String in site.requirements: site.deliver(item_id, site.receivable(item_id))
					game.apply_construction_work(instance_id, 40.0)
			game.player.position = capture_cell * game.CELL_SIZE
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(str(args[1]))
	if result != OK: push_error("Could not save screenshot: %s" % result)
	quit(0 if result == OK else 1)
