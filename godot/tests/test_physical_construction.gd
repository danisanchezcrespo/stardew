extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	await _test_supply_work_and_complete(failures)

	if failures.is_empty():
		print("PASS: physical construction")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_supply_work_and_complete(failures: Array[String]) -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game_root: Node = scene.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	game.inventory.add("brick_kiln_plan", 1)
	game.select_quick_slot(_find_slot(game.inventory, "brick_kiln_plan"))
	_expect(game.begin_placement(), "Brick kiln plan should enter placement mode.", failures)
	var origin: Vector2i = game.placement_cursor
	_expect(game.confirm_placement(), "Brick kiln construction site should place on valid sand.", failures)
	var instance_id: String = game.world_grid.occupant_at(origin)
	var site: Variant = game.construction_by_entity_id.get(instance_id)
	_expect(site != null and not site.complete, "Placed kiln plan should create an incomplete site.", failures)
	var target: Variant = game.placed_targets[instance_id]
	var east_side_player: Vector2 = Vector2(origin + Vector2i(2, 0)) * float(game.CELL_SIZE) + Vector2.ONE * 16.0
	_expect(target.interaction_position_for(east_side_player).distance_to(east_side_player) <= game.CELL_SIZE, "Construction should be targetable from any adjacent footprint edge.", failures)
	game.player.position = east_side_player
	game.player.facing = "west"
	game._update_interaction_target()
	_expect(game.interaction_target == target, "Interaction targeting should select construction from its east edge.", failures)
	_expect(game.world_grid.entities_by_id[instance_id].origin == origin, "Construction should retain its stable spatial identity.", failures)
	_expect(game.apply_construction_work(instance_id, 1.0) == 0.0, "Work before material delivery should be rejected.", failures)

	game.inventory.add("wood", 10)
	game.select_quick_slot(_find_slot(game.inventory, "wood"))
	_expect(game.open_building_details(instance_id), "Space flow should open construction details.", failures)
	_expect(game.construction_delivery_popup.visible and game.construction_delivery_label.text.contains("Wood x8") and game.construction_delivery_label.text.contains("Space = deliver"), "Compatible inventory should open a delivery confirmation with its exact amount.", failures)
	game.building_details_context_action()
	game.close_building_details()
	_expect(game.inventory.count("wood") == 2, "Excess delivered wood should remain with the player.", failures)
	game.inventory.add("mud_bricks", 10)
	game.select_quick_slot(_find_slot(game.inventory, "mud_bricks"))
	_expect(game.deliver_selected_to_construction(instance_id) == 8, "Site should accept exactly its required mud bricks.", failures)
	_expect(site.materials_complete(), "All delivered construction materials should unlock work.", failures)
	_expect(game.inventory.count("mud_bricks") == 2, "Excess bricks should remain with the player.", failures)
	_expect(game.world_overlay.z_index > game.player.z_index and not game.world_overlay.z_as_relative, "Context overlays should render above characters in absolute Z.", failures)
	game._update_interaction_target()
	var build_action := InputEventAction.new()
	build_action.action = "use_selected"
	build_action.pressed = true
	game._unhandled_input(build_action)
	_expect(game.building_details_open, "Space beside a construction should open the shared details panel.", failures)
	game._unhandled_input(build_action)
	_expect(game.active_player_build_id == instance_id, "Space inside construction details should start timed construction.", failures)
	var move_action := InputEventAction.new()
	move_action.action = "move_right"
	move_action.pressed = true
	game._unhandled_input(move_action)
	_expect(not game.building_details_open and game.player.movement_enabled, "Moving should close construction details without cancelling work.", failures)
	game.player.position += Vector2(400, 0)
	game._process(1.25)
	_expect(not site.complete and site.work_progress() > 0.4, "Construction should continue after the player walks away.", failures)
	game._process(5.0)
	_expect(site.complete and is_equal_approx(site.work_progress(), 1.0), "Enough local work should complete the building.", failures)
	_expect(game.placed_targets[instance_id].target_kind == "machine", "Completed site should become a machine target.", failures)
	_expect(game.world_grid.occupant_at(origin) == instance_id, "Completion must not replace the spatial entity ID.", failures)
	game_root.queue_free()
	await process_frame


func _find_slot(inventory: Variant, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].get("item_id") == item_id:
			return index
	return -1


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
