extends SceneTree

const WorkforceType = preload("res://world/population/physical_workforce.gd")
const MachineType = preload("res://world/machines/physical_machine.gd")
const ItemRegistryType = preload("res://items/item_registry.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var workforce := WorkforceType.new()
	workforce.register_job("low", 1, 10)
	workforce.register_job("high", 1, 90)
	_expect(workforce.assigned_to("high") == 1, "Scarce worker should take highest-priority job.", failures)
	_expect(workforce.assigned_to("low") == 0, "Lower-priority job should remain unstaffed.", failures)
	var registry := ItemRegistryType.new()
	registry.load_from_path("res://items/items.json")
	var machine := MachineType.new("low", {"clay": 1}, {"mud_bricks": 1}, 1.0, registry)
	machine.add_input("clay", 1)
	machine.staffed = workforce.assigned_to("low") > 0
	machine.process(2.0)
	_expect(machine.input_inventory.count("clay") == 1, "Unstaffed machine must not consume input.", failures)
	workforce.set_population(2)
	machine.staffed = workforce.assigned_to("low") > 0
	machine.process(0.1)
	machine.process(1.0)
	_expect(machine.output_inventory.count("mud_bricks") == 1, "New population should staff and enable waiting job.", failures)
	_expect(workforce.employment_summary().contains("2 employed"), "Workforce summary should expose assignments.", failures)
	await _test_dwelling_growth(failures)
	if failures.is_empty():
		print("PASS: physical workforce")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_dwelling_growth(failures: Array[String]) -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game_root: Node = packed.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	game.inventory.add("dwelling_plan", 1)
	game.select_quick_slot(_find_slot(game.inventory, "dwelling_plan"))
	game.begin_placement()
	var origin: Vector2i = game.placement_cursor
	game.confirm_placement()
	var instance_id: String = game.world_grid.occupant_at(origin)
	var site: Variant = game.construction_by_entity_id[instance_id]
	for item_id: String in site.requirements:
		game.inventory.add(item_id, site.receivable(item_id))
		game.select_quick_slot(_find_slot(game.inventory, item_id))
		game.deliver_selected_to_construction(instance_id)
	game.apply_construction_work(instance_id, 10.0)
	_expect(game.workforce.population == 3, "Completed dwelling should add two population capacity.", failures)
	_expect(game.placed_targets[instance_id].target_kind == "building", "Dwelling should become a building, not a machine.", failures)
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
