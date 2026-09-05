extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	await _test_craft_place_and_collide(failures)
	await _test_invalid_placement_preserves_inventory(failures)

	if failures.is_empty():
		print("PASS: gameplay placement")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _create_game() -> Array:
	var scene: PackedScene = load("res://main.tscn")
	var game_root: Node = scene.instantiate()
	root.add_child(game_root)
	await process_frame
	return [game_root, game_root.get_node("MainGame")]


func _craft_crate(game: Node2D) -> int:
	game.inventory.add("wood", 10)
	var crafted: bool = game.craft_selected_recipe()
	if not crafted:
		return -1
	for index in range(game.inventory.slots.size()):
		if game.inventory.slots[index].get("item_id") == "storage_crate":
			return index
	return -1


func _test_craft_place_and_collide(failures: Array[String]) -> void:
	var nodes: Array = await _create_game()
	var game_root: Node = nodes[0]
	var game: Node2D = nodes[1]
	var crate_slot: int = _craft_crate(game)
	_expect(crate_slot >= 0, "Crafted crate should occupy an inventory slot.", failures)
	game.select_quick_slot(crate_slot)
	_expect(game.placement_mode, "Selecting a placeable item should automatically enter placement mode.", failures)
	_expect(game.player.movement_enabled, "Player should keep walking while the placement ghost is active.", failures)
	_expect(game.interaction_label.text.contains("Storage Crate") and game.interaction_label.text.contains("Space = Place"), "Placement hover should name the ghost and show the Space control.", failures)
	var starting_position: Vector2 = game.player.position
	var starting_cursor: Vector2i = game.placement_cursor
	game.player.position += Vector2.RIGHT * game.CELL_SIZE
	game.player.facing = "east"
	game._process(0.0)
	_expect(game.placement_cursor != starting_cursor and game.placement_cursor == game._player_cell() + Vector2i.RIGHT, "Placement ghost should follow player position and facing.", failures)
	game.player.position = starting_position
	game.player.facing = "south"
	game._process(0.0)
	var placed_cell: Vector2i = game.placement_cursor
	_expect(game.confirm_placement(), "Valid adjacent crate should place.", failures)
	_expect(game.inventory.count("storage_crate") == 0, "Successful placement should consume exactly one crate.", failures)
	_expect(not game.world_grid.occupant_at(placed_cell).is_empty(), "Placed crate should occupy its world cell.", failures)

	Input.action_press("move_down")
	for _index in range(10):
		await physics_frame
	Input.action_release("move_down")
	var crate_top := float(placed_cell.y * game.CELL_SIZE)
	_expect(game.player.position.y <= crate_top - 9.9, "Player should collide with the placed crate.", failures)
	game_root.queue_free()
	await process_frame


func _test_invalid_placement_preserves_inventory(failures: Array[String]) -> void:
	var nodes: Array = await _create_game()
	var game_root: Node = nodes[0]
	var game: Node2D = nodes[1]
	var crate_slot: int = _craft_crate(game)
	game.select_quick_slot(crate_slot)
	game.begin_placement()
	var water_cell := Vector2i.ZERO
	var player_cell := Vector2i.ZERO
	for candidate: Vector2i in game.water_cells:
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if game.world_grid.contains(candidate + direction) and not game.water_cells.has(candidate + direction):
				water_cell = candidate; player_cell = candidate + direction; break
		if water_cell != Vector2i.ZERO: break
	game.player.position = Vector2(player_cell) * game.CELL_SIZE + Vector2.ONE * 16.0
	game.placement_cursor = water_cell
	_expect(not game.confirm_placement(), "Water cell should reject a crate.", failures)
	_expect(game.inventory.count("storage_crate") == 1, "Rejected terrain must not consume inventory.", failures)
	game.placement_cursor = player_cell + Vector2i(10, 0)
	_expect(not game.confirm_placement(), "Remote cell should reject local placement.", failures)
	_expect(game.inventory.count("storage_crate") == 1, "Out-of-range placement must not consume inventory.", failures)
	game.placement_cursor = player_cell
	_expect(not game.confirm_placement(), "Player cell should reject placement.", failures)
	_expect(game.inventory.count("storage_crate") == 1, "Player overlap must not consume inventory.", failures)
	game_root.queue_free()
	await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
