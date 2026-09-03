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
	_expect(game.create_logistics_route(input_crate, kiln_id), "Storage-to-kiln route should be created.", failures)
	_expect(not game.create_logistics_route(input_crate, kiln_id), "Duplicate route should be rejected.", failures)
	var inbound: Variant = game.logistics_routes[0]
	game._process_logistics_route(inbound, 2.1)
	game._process_logistics_route(inbound, 2.1)
	_expect(game.storage_by_entity_id[input_crate].count("clay") == 0, "Porter should remove delivered clay from source.", failures)
	_expect(game.machines_by_entity_id[kiln_id].input_inventory.count("clay") == 2, "Porter should deliver compatible clay to kiln.", failures)
	game.machines_by_entity_id[kiln_id].process(0.1)
	game.machines_by_entity_id[kiln_id].process(4.0)
	_expect(game.create_logistics_route(kiln_id, output_crate), "Kiln-to-storage route should be created.", failures)
	var outbound: Variant = game.logistics_routes[1]
	game._process_logistics_route(outbound, 2.1)
	_expect(game.storage_by_entity_id[output_crate].count("mud_bricks") == 1, "Porter should carry finished bricks to destination storage.", failures)
	_expect(outbound.trips_completed == 1, "Successful delivery should count one physical trip.", failures)
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
