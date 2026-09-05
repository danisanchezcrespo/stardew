extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	await _test_home_transport_needs_and_name(failures)
	if failures.is_empty():
		print("PASS: villager life")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)


func _test_home_transport_needs_and_name(failures: Array[String]) -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game_root: Node = packed.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	var home_id := _place_and_complete(game, "dwelling_plan", Vector2i(12, 12))
	_expect(game.villagers.size() == 2, "A completed two-bed dwelling should create two physical villagers.", failures)
	var villager: Variant = game.villagers.values()[0]
	_expect(villager.home_id == home_id, "New villagers should remain linked to their home.", failures)
	_expect(game.open_building_details(home_id), "A completed home should expose building details.", failures)
	_expect(game.building_details_body.text.contains(villager.villager_name), "Home details should list its residents and needs.", failures)
	game.close_building_details()
	villager.position = Vector2(600, 300)
	game.player.position = Vector2(568, 300)
	game.player.facing = "east"
	game._update_interaction_target()
	_expect(game.interaction_target == villager, "A nearby villager should become the Space interaction target.", failures)
	var open_action := InputEventAction.new()
	open_action.action = "use_selected"
	open_action.pressed = true
	game._unhandled_input(open_action)
	_expect(game.selected_villager_id == villager.stable_id and game.villager_panel.visible, "Space should open the villager in the shared right-side panel.", failures)
	game.close_villager_panel()
	game.select_villager(villager.stable_id)
	game._rename_selected_villager("Merit")
	_expect(villager.villager_name == "Merit", "The characteristics panel should rename a villager.", failures)
	var move_destination := Vector2(760, 180)
	var screen_destination: Vector2 = game.get_canvas_transform() * move_destination
	_expect(game._handle_villager_world_click(screen_destination), "Clicking empty ground with a selected villager should issue a move order.", failures)
	for _step in range(160): game._process(0.1)
	_expect(villager.position.distance_to(move_destination) < 6.0 and villager.task.is_empty(), "A direct move order should walk to its point and finish.", failures)

	var source_id := _place(game, "storage_crate", Vector2i(15, 12))
	var destination_id := _place(game, "storage_crate", Vector2i(18, 12))
	game.storage_by_entity_id[source_id].add("clay", 5)
	_expect(game.create_logistics_route(source_id, destination_id, villager.stable_id, "clay"), "A selected villager should receive a transport order.", failures)
	villager.hunger = 0.0
	var starving_start: Vector2 = villager.position
	villager.process_life(game, 0.25)
	_expect(villager.position.distance_to(starving_start) > 0.0, "A starving villager with an assigned route should move slowly instead of deadlocking when no food exists.", failures)
	for _step in range(160): game._process(0.1)
	_expect(game.storage_by_entity_id[source_id].count("clay") == 0, "Physical trips should empty the ordered resource from the source.", failures)
	_expect(game.storage_by_entity_id[destination_id].count("clay") == 5, "The villager should physically deliver carried resources.", failures)

	villager.clear_task()
	game.storage_by_entity_id[destination_id].add("food_ration", 1)
	villager.hunger = 25.0
	for _step in range(120): game._process(0.1)
	_expect(villager.hunger > 60.0, "A hungry villager should autonomously eat a stored ration.", failures)
	_expect(game.storage_by_entity_id[destination_id].count("food_ration") == 0, "Eating should consume a physical food ration.", failures)

	game.day_time_seconds = 200.0
	villager.energy = 40.0
	for _step in range(160): game._process(0.1)
	_expect(villager.state == "sleeping" and villager.position.distance_to(villager.home_position) < 1.0, "At night a villager should return home and sleep.", failures)
	game_root.queue_free()
	await process_frame


func _place_and_complete(game: Node2D, item_id: String, origin: Vector2i) -> String:
	var instance_id := _place(game, item_id, origin)
	var site: Variant = game.construction_by_entity_id[instance_id]
	for resource_id: String in site.requirements:
		game.inventory.add(resource_id, site.receivable(resource_id))
		game.select_quick_slot(_find_slot(game.inventory, resource_id))
		game.deliver_selected_to_construction(instance_id)
	game.apply_construction_work(instance_id, 20.0)
	return instance_id


func _place(game: Node2D, item_id: String, origin: Vector2i) -> String:
	game.player.position = Vector2(origin + Vector2i(0, -1)) * game.CELL_SIZE + Vector2.ONE * 16.0
	game.player.facing = "south"
	game.inventory.add(item_id, 1)
	game.select_quick_slot(_find_slot(game.inventory, item_id))
	game.placement_cursor = origin
	game.confirm_placement()
	return game.world_grid.occupant_at(origin)


func _find_slot(inventory: Variant, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].get("item_id") == item_id: return index
	return -1


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
