extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	ScenarioType.requested_path = "res://scenarios/physical/ancient_egypt.json"
	ScenarioType.requested_autostart = true
	var packed: PackedScene = load("res://main.tscn")
	var game_root: Node = packed.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	var home_id := _place_and_complete(game, "dwelling_plan", Vector2i(10, 15))
	var coop_id := _place_and_complete(game, "chicken_coop_plan", Vector2i(15, 15))
	var chicken: Variant = game.dependents.values()[0]
	var keeper: Variant = game.villagers.values()[0]
	keeper.assign_work(coop_id)
	keeper.state = "working"
	chicken.age_seconds = chicken.mature_seconds
	chicken.hunger = 100.0
	chicken.thirst = 100.0
	chicken.product_elapsed = chicken.product_interval
	chicken.process_life(game, 0.1)
	_expect(chicken.stored_product == 1, "A mature fed chicken with an assigned keeper should lay an egg.", failures)
	game.selected_slot = 0
	game.inventory.slots[0] = {}
	game.interact_with_dependent(chicken)
	_expect(not chicken.harvest_armed, "Interacting without bronze tools must not arm domestic slaughter.", failures)
	game.dependents.erase(chicken.stable_id)
	chicken.queue_free()
	game.inventory.add("grain", 5)
	_expect(game._raise_chicken(coop_id), "A killed chicken should be replaceable from its coop for Grain x5.", failures)
	_expect(game._dependent_count(coop_id, "chicken") == 1 and game.inventory.count("grain") == 0, "Raising a chicken should consume five grain and spawn one young chicken.", failures)
	_expect(not home_id.is_empty(), "Test dwelling should complete.", failures)
	game_root.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: animal husbandry"); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)


func _place_and_complete(game: Node2D, item_id: String, origin: Vector2i) -> String:
	game.player.position = Vector2(origin + Vector2i(0, -1)) * game.CELL_SIZE + Vector2.ONE * 16.0
	game.player.facing = "south"
	game.inventory.add(item_id, 1)
	game.select_quick_slot(_find_slot(game.inventory, item_id))
	game.placement_cursor = origin
	game.confirm_placement()
	var instance_id: String = game.world_grid.occupant_at(origin)
	var site: Variant = game.construction_by_entity_id[instance_id]
	for resource_id: String in site.requirements:
		game.inventory.add(resource_id, site.receivable(resource_id))
		game.select_quick_slot(_find_slot(game.inventory, resource_id))
		game.deliver_selected_to_construction(instance_id)
	game.apply_construction_work(instance_id, 30.0)
	return instance_id


func _find_slot(inventory: Variant, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].get("item_id") == item_id: return index
	return -1


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
