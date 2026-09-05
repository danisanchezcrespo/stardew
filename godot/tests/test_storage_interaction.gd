extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	await _test_place_open_transfer_and_reopen(failures)

	if failures.is_empty():
		print("PASS: storage interaction")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_place_open_transfer_and_reopen(failures: Array[String]) -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game_root: Node = scene.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")

	game.inventory.add("wood", 10)
	_expect(game.craft_selected_recipe(), "Storage test should craft a crate.", failures)
	var crate_slot := _find_slot(game.inventory, "storage_crate")
	game.select_quick_slot(crate_slot)
	game.begin_placement()
	var crate_origin: Vector2i = game.placement_cursor
	_expect(game.confirm_placement(), "Storage test should place the crate.", failures)
	var instance_id: String = game.world_grid.occupant_at(crate_origin)
	_expect(game.storage_by_entity_id.has(instance_id), "Placed storage definition should create an independent container.", failures)

	game._update_interaction_target()
	_expect(game.interaction_target != null and game.interaction_target.target_kind == "storage", "Crate use point should become the nearby contextual target.", failures)
	game.collect_target()
	_expect(game.storage_open and not game.player.movement_enabled and game.storage_panel.visible, "Interacting should open local storage and stop movement.", failures)

	game.inventory.add("clay", 37)
	game.select_quick_slot(_find_slot(game.inventory, "clay"))
	_expect(game.storage_focus_side == 0, "Storage should open focused on player inventory.", failures)
	game._unhandled_input(_action("move_right"))
	_expect(game.storage_focus_side == 1, "Right should focus the crate inventory.", failures)
	game._unhandled_input(_action("move_left"))
	_expect(game.storage_focus_side == 0, "Left should focus the player inventory.", failures)
	game._unhandled_input(_action("use_selected"))
	_expect(game.inventory.count("clay") == 0, "Space should move the complete selected stack out of player inventory.", failures)
	_expect(game.storage_by_entity_id[instance_id].count("clay") == 37, "Deposited items should belong to that crate.", failures)

	game.close_storage()
	_expect(not game.storage_open and game.player.movement_enabled, "Closing storage should restore player movement.", failures)
	var crate_screen_position: Vector2 = game.get_canvas_transform() * game.placed_targets[instance_id].global_position
	_expect(game._handle_villager_world_click(crate_screen_position), "Clicking a placed object should be consumed without opening a second interaction path.", failures)
	_expect(not game.building_details_open and not game.storage_open, "World objects should open only through Space, never click.", failures)
	_expect(game.open_storage(instance_id), "Placed crate should reopen with its contents intact.", failures)
	game.set_storage_focus(1)
	_expect(game.storage_contents_label.text.begins_with(">") and game.storage_crate_rows[game.selected_storage_slot].color == Color("#6b3e20"), "Right-side focus should be visible on the crate column and selected row.", failures)
	game._unhandled_input(_action("use_selected"))
	_expect(game.inventory.count("clay") == 37, "Space should return the selected crate stack to player inventory.", failures)
	_expect(game.storage_by_entity_id[instance_id].count("clay") == 0, "Withdrawal should remove items from the crate.", failures)

	game.storage_by_entity_id[instance_id].add("wood", 400)
	game.inventory.add("wood", 20)
	game.select_quick_slot(_find_slot(game.inventory, "wood"))
	var before: int = game.inventory.count("wood")
	_expect(game.deposit_selected_stack() == 0, "Full crate should reject a deposit.", failures)
	_expect(game.inventory.count("wood") == before, "Rejected deposit must preserve player items.", failures)

	game.close_storage()
	game.inventory.add("storage_crate", 1)
	game.select_quick_slot(_find_slot(game.inventory, "storage_crate"))
	game.begin_placement()
	game.move_placement_cursor(Vector2i.RIGHT)
	_expect(game.confirm_placement(), "A second crate should place in a different cell.", failures)
	_expect(game.storage_by_entity_id.size() == 2, "Every placed crate should own a separate container.", failures)
	var second_id := ""
	for candidate_id: String in game.storage_by_entity_id:
		if candidate_id != instance_id:
			second_id = candidate_id
	game.storage_by_entity_id[instance_id].add("grain", 5)
	_expect(game.storage_by_entity_id[second_id].count("grain") == 0, "Contents of one crate must not leak into another.", failures)
	game_root.queue_free()
	await process_frame


func _find_slot(inventory: Variant, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].get("item_id") == item_id:
			return index
	return -1


func _action(name: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
