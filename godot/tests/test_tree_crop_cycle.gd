extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var packed: PackedScene = load("res://main.tscn")
	var root_node := packed.instantiate()
	root.add_child(root_node)
	await process_frame
	var game: Node2D = root_node.get_node("MainGame")
	_expect(game.crops.size() == 3, "Each map should begin with exactly three mature trees.", failures)
	var initial_tree: Variant = game.crops[0]
	_expect(initial_tree.stage == 3, "Starting trees should be harvestable.", failures)
	_expect(game.interact_with_crop(initial_tree), "A mature tree should be harvestable.", failures)
	_expect(game.inventory.count("wood") == 8 and game.inventory.count("tree_seed") == 2, "Harvest should close the loop with Wood x8 and Tree seed x2.", failures)
	game.select_quick_slot(_find_slot(game.inventory, "tree_seed"))
	game.player.position = Vector2(12.5, 15.5) * game.CELL_SIZE
	_expect(game.begin_placement(), "Selecting a tree seed should enter ghost placement.", failures)
	game.placement_cursor = Vector2i(12, 14)
	_expect(game.confirm_placement(), "A tree seed should plant on empty sand.", failures)
	var crop: Variant = game.crops[game.crops.size() - 1]
	game.inventory.add("water", 3)
	game.select_quick_slot(_find_slot(game.inventory, "water"))
	for expected_stage in range(1, 4):
		_expect(game.interact_with_crop(crop), "Each growth stage should accept one Water.", failures)
		crop.process_growth(60.0)
		_expect(crop.stage == expected_stage and not crop.watered, "Sixty seconds should advance exactly one stage and require watering again.", failures)
	var snapshot: Dictionary = game.physical_save.capture(game)
	_expect(snapshot.entities.any(func(row: Dictionary) -> bool: return row.get("definition_id") == "TREE_CROP" and row.has("crop")), "Crop stage and watering state should be saved.", failures)
	root_node.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: closed tree crop cycle"); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)

func _find_slot(inventory: Variant, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].get("item_id") == item_id: return index
	return -1

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
