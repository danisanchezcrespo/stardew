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
		elif str(args[5]) == "happiness" and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			var home_cell := Vector2i(17, 10)
			game.player.position = Vector2(home_cell + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0
			game.inventory.add("cottage_plan", 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = home_cell; game.confirm_placement()
			var home_id: String = game.world_grid.occupant_at(home_cell); var home_site: Variant = game.construction_by_entity_id.get(home_id)
			if home_site != null:
				for item_id: String in home_site.requirements: home_site.deliver(item_id, home_site.receivable(item_id))
				game.apply_construction_work(home_id, 40.0)
			for row: Dictionary in [{"item":"rose_bed","cell":Vector2i(15,14)},{"item":"angel_fountain","cell":Vector2i(20,14)}]:
				game.player.position = Vector2(row.cell + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0
				game.inventory.add(str(row.item), 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = row.cell; game.confirm_placement()
			game._update_villager_happiness()
			if not game.villagers.is_empty(): game.select_villager(str(game.villagers.keys()[0]))
			game.player.position = capture_cell * game.CELL_SIZE
		elif str(args[5]) in ["university", "university_tree"] and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			while game.dialogue_open: game._advance_dialogue()
			var cell := Vector2i(20, 12); game.player.position = Vector2(cell + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0
			game.inventory.add("university_plan", 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = cell; game.confirm_placement()
			var instance_id: String = game.world_grid.occupant_at(cell); var site: Variant = game.construction_by_entity_id.get(instance_id)
			if site != null:
				for item_id: String in site.requirements: site.deliver(item_id, site.receivable(item_id))
				game.apply_construction_work(instance_id, 60.0); game.open_building_details(instance_id)
			if str(args[5]) == "university_tree": game.building_details_context_action()
		elif str(args[5]) in ["home_sleep", "mastery_new", "mastery_veteran"] and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			while game.dialogue_open: game._advance_dialogue()
			var item_id := "sculptor_workshop_plan"
			var cell := Vector2i(20, 12); game.player.position = Vector2(cell + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0
			var instance_id: String = game._ensure_traveller_home() if str(args[5]) == "home_sleep" else ""
			if str(args[5]) != "home_sleep":
				game.inventory.add(item_id, 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = cell; game.confirm_placement(); instance_id = game.world_grid.occupant_at(cell)
			var site: Variant = game.construction_by_entity_id.get(instance_id)
			if site != null:
				for material_id: String in site.requirements: site.deliver(material_id, site.receivable(material_id))
				game.apply_construction_work(instance_id, 60.0)
			if str(args[5]) == "home_sleep": game.open_building_details(instance_id)
			else:
				if str(args[5]) == "mastery_veteran": game.machines_by_entity_id[instance_id].batches_completed = 12
				game.open_machine(instance_id)
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
			var previews := [{"item":"chicken_coop_plan","cell":Vector2i(12,7)},{"item":"herb_garden_plan","cell":Vector2i(19,7)},{"item":"apiary_plan","cell":Vector2i(26,7)},{"item":"astronomer_tower_plan","cell":Vector2i(33,6)},{"item":"sculptor_workshop_plan","cell":Vector2i(16,14)},{"item":"garden_nursery_plan","cell":Vector2i(25,14)}]
			for row: Dictionary in previews:
				game.player.position = Vector2(row.cell + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0; game.player.facing = "south"
				game.inventory.add(str(row.item), 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = row.cell; game.confirm_placement()
				var instance_id: String = game.world_grid.occupant_at(row.cell); var site: Variant = game.construction_by_entity_id.get(instance_id)
				if site != null:
					for item_id: String in site.requirements: site.deliver(item_id, site.receivable(item_id))
					game.apply_construction_work(instance_id, 40.0)
			game.player.position = capture_cell * game.CELL_SIZE
		elif str(args[5]) == "decorations" and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			var decor := ["stone_lion","scholar_statue","knight_statue","angel_fountain","stone_sundial","carved_stag","rune_obelisk","stone_birdbath","rose_bed","bluebell_bed","sunflower_planter","lavender_planter","trimmed_topiary","flower_trellis","terracotta_herbs","cherry_tree"]
			for index in range(decor.size()):
				var cell := Vector2i(12 + (index % 4) * 6, 5 + (index / 4) * 5)
				game.player.position = Vector2(cell + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0; game.player.facing = "south"
				game.inventory.add(str(decor[index]), 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = cell; game.confirm_placement()
			game.player.position = capture_cell * game.CELL_SIZE
		elif str(args[5]) == "catalog" and game.scenario.scenario_id == "medieval":
			if game.splash_open: game._close_splash()
			if game.dialogue_open: game._advance_dialogue()
			var cell := Vector2i(23, 11); game.player.position = Vector2(cell + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0; game.player.facing = "south"
			game.inventory.add("sculptor_workshop_plan", 1); game.select_quick_slot(0); game.begin_placement(); game.placement_cursor = cell; game.confirm_placement()
			var instance_id: String = game.world_grid.occupant_at(cell); var site: Variant = game.construction_by_entity_id.get(instance_id)
			if site != null:
				for item_id: String in site.requirements: site.deliver(item_id, site.receivable(item_id))
				game.apply_construction_work(instance_id, 40.0); game.inventory.add("field_stone", 20); game.open_machine(instance_id)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(str(args[1]))
	if result != OK: push_error("Could not save screenshot: %s" % result)
	quit(0 if result == OK else 1)
