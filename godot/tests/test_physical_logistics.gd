extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	await _test_storage_machine_routes(failures)
	if failures.is_empty():
		print("PASS: physical logistics")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_storage_machine_routes(failures: Array[String]) -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game_root: Node = packed.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	var input_crate := _place(game, "storage_crate", Vector2i(7, 7))
	var output_crate := _place(game, "storage_crate", Vector2i(7, 9))
	var kiln_id := _place(game, "brick_kiln_plan", Vector2i(9, 7))
	game.spawn_villagers_for_home(input_crate, 2)
	var inbound_villager: Variant = game.villagers.values()[0]
	var outbound_villager: Variant = game.villagers.values()[1]
	game.select_villager(inbound_villager.stable_id)
	game.player.position = Vector2(7.5, 6.5) * game.CELL_SIZE
	game.player.facing = "south"
	game._update_interaction_target()
	var route_key := InputEventKey.new()
	route_key.physical_keycode = KEY_R
	route_key.pressed = true
	game._input(route_key)
	_expect(game.route_source_id == input_crate, "R input should select the adjacent completed crate as route source.", failures)
	game._process(0.0)
	_expect(game.interaction_label.text.contains("ROUTE SOURCE SET"), "Route source feedback should remain visible across frames.", failures)
	_expect(not kiln_id.is_empty(), "Kiln should be placed within player range.", failures)
	if kiln_id.is_empty():
		game_root.queue_free()
		await process_frame
		return
	var site: Variant = game.construction_by_entity_id[kiln_id]
	for item_id: String in site.requirements:
		game.inventory.add(item_id, site.receivable(item_id))
		game.select_quick_slot(_find_slot(game.inventory, item_id))
		game.deliver_selected_to_construction(kiln_id)
	game.apply_construction_work(kiln_id, 10.0)
	game.storage_by_entity_id[input_crate].add("clay", 2)
	game.select_villager(inbound_villager.stable_id)
	game.begin_villager_transport_order()
	game._handle_order_endpoint(input_crate)
	_expect(game.villager_resource_option.item_count == 1 and str(game.villager_resource_option.get_item_metadata(0)) == "clay", "A crate source picker should only offer resources that are physically present.", failures)
	game.villager_order_mode = ""
	game.pending_order_source_id = ""
	game.villager_resource_option.visible = false
	game.player.position = Vector2(8.5, 7.5) * game.CELL_SIZE
	game.player.facing = "east"
	game._input(route_key)
	_expect(game.logistics_routes.size() == 1 and game.route_source_id.is_empty(), "Second R input should create the storage-to-kiln route.", failures)
	_expect(not game.create_logistics_route(input_crate, kiln_id, inbound_villager.stable_id, "clay"), "Duplicate route should be rejected.", failures)
	var inbound: Variant = game.logistics_routes[0]
	for _step in range(120): inbound_villager.process_life(game, 0.1)
	_expect(game.storage_by_entity_id[input_crate].count("clay") == 0, "Porter should remove delivered clay from source.", failures)
	_expect(game.machines_by_entity_id[kiln_id].input_inventory.count("clay") == 2, "Porter should deliver compatible clay to kiln.", failures)
	game.machines_by_entity_id[kiln_id].staffed = true
	game.machines_by_entity_id[kiln_id].process(0.1)
	game.machines_by_entity_id[kiln_id].process(4.0)
	game.select_villager(outbound_villager.stable_id)
	game._input(route_key)
	_expect(game.route_source_id == kiln_id, "R should select kiln as output route source.", failures)
	game.player.position = Vector2(7.5, 8.5) * game.CELL_SIZE
	game.player.facing = "south"
	game._input(route_key)
	_expect(game.logistics_routes.size() == 2, "Second R should connect kiln output to storage.", failures)
	var outbound: Variant = game.logistics_routes[1]
	for _step in range(120): outbound_villager.process_life(game, 0.1)
	_expect(game.storage_by_entity_id[output_crate].count("mud_bricks") == 1, "Porter should carry finished bricks to destination storage.", failures)
	_expect(outbound.trips_completed == 1, "Successful delivery should count one physical trip.", failures)
	var water_cell: Vector2i = game.water_cells.keys()[0]
	var water_target: Variant = game._ensure_water_route_target(water_cell)
	game.spawn_villagers_for_home(input_crate, 3)
	var water_villager: Variant = game.villagers.values()[2]
	game.select_villager(water_villager.stable_id)
	game.begin_villager_transport_order()
	var water_screen: Vector2 = game.get_canvas_transform() * water_target.global_position
	_expect(game._handle_villager_world_click(water_screen) and game.villager_order_mode == "destination", "Clicking water after Assign transport should select the infinite source.", failures)
	var crate_screen: Vector2 = game.get_canvas_transform() * game.placed_targets[output_crate].global_position
	_expect(game._handle_villager_world_click(crate_screen), "Clicking a crate should complete the water transport order.", failures)
	_expect(str(water_villager.task.get("source", "")) == water_target.stable_id and str(water_villager.task.get("destination", "")) == output_crate and str(water_villager.task.get("item", "")) == "water", "The exact NPC -> water -> crate UI flow should assign the villager task.", failures)
	var water_start: Vector2 = water_villager.position
	for _step in range(10): water_villager.process_life(game, 0.1)
	_expect(water_villager.position.distance_to(water_start) > 1.0, "A newly assigned water route should start moving immediately from the villager's current position.", failures)
	water_villager.position = water_target.global_position
	water_villager.state = "to_source"
	water_villager.process_life(game, 0.1)
	_expect(water_villager.carrying_item == "water" and water_villager.carrying_amount == 3, "Water source should provide a physical carrying stack without depletion.", failures)
	game_root.queue_free()
	await process_frame

func _place(game: Node2D, item_id: String, origin: Vector2i) -> String:
	game.inventory.add(item_id, 1)
	game.select_quick_slot(_find_slot(game.inventory, item_id))
	game.begin_placement()
	game.placement_cursor = origin
	game.confirm_placement()
	return game.world_grid.occupant_at(origin)

func _find_slot(inventory: Variant, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].get("item_id") == item_id:
			return index
	return -1

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
