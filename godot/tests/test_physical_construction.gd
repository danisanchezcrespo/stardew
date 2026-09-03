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
	_expect(game.deliver_selected_to_construction(instance_id) == 8, "Site should accept exactly its required wood.", failures)
	_expect(game.inventory.count("wood") == 2, "Excess delivered wood should remain with the player.", failures)
	game.inventory.add("mud_bricks", 10)
	game.select_quick_slot(_find_slot(game.inventory, "mud_bricks"))
	_expect(game.deliver_selected_to_construction(instance_id) == 8, "Site should accept exactly its required mud bricks.", failures)
	_expect(site.materials_complete(), "All delivered construction materials should unlock work.", failures)
	_expect(game.inventory.count("mud_bricks") == 2, "Excess bricks should remain with the player.", failures)

	_expect(is_equal_approx(game.apply_construction_work(instance_id, 1.25), 1.25), "Local work should advance by applied duration.", failures)
	_expect(not site.complete and site.work_progress() > 0.4, "Partial work should keep the site incomplete.", failures)
	game.apply_construction_work(instance_id, 5.0)
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
