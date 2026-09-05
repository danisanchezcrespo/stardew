extends SceneTree

const VillagerType = preload("res://world/population/villager.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	await _test_kiln(failures)
	if failures.is_empty():
		print("PASS: physical machine")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_kiln(failures: Array[String]) -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game_root: Node = scene.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	game.inventory.add("brick_kiln_plan", 1)
	game.select_quick_slot(_find_slot(game.inventory, "brick_kiln_plan"))
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
	var machine: Variant = game.machines_by_entity_id.get(instance_id)
	_expect(machine != null, "Completed kiln should create a physical machine runtime.", failures)
	game.interaction_target = game.placed_targets[instance_id]
	game._unhandled_input(_action("use_selected"))
	_expect(game.machine_open, "Space should open the nearby kiln status panel.", failures)
	_expect(game.machine_status_label.text.contains("Health") and game.machine_status_label.text.contains("ACCUMULATED OUTPUT"), "Machine details should expose health and accumulated product.", failures)
	game.close_machine()
	game.inventory.add("grain", 3)
	game.select_quick_slot(_find_slot(game.inventory, "grain"))
	_expect(game.deliver_selected_to_machine(instance_id) == 0, "Kiln should reject unrelated input.", failures)
	_expect(game.inventory.count("grain") == 3, "Rejected input must remain with player.", failures)
	game.inventory.add("clay", 4)
	game.select_quick_slot(_find_slot(game.inventory, "clay"))
	_expect(game.deliver_selected_to_machine(instance_id) == 4, "Kiln should accept carried clay.", failures)
	var worker := VillagerType.new()
	worker.configure("test-worker", "Worker", "", game.placed_targets[instance_id].global_position)
	game.add_child(worker)
	game.villagers[worker.stable_id] = worker
	worker.assign_work(instance_id)
	game._process(0.1)
	_expect(machine.manually_activated and machine.is_running(), "A supplied and staffed machine should start a timed batch.", failures)
	game.player.position += Vector2(500, 0)
	game._process(4.0)
	_expect(machine.output_inventory.count("mud_bricks") == 1, "Finished batch should store its output.", failures)
	var before: int = game.inventory.count("mud_bricks")
	_expect(game.withdraw_machine_output(instance_id) == 1, "Player should collect machine output locally.", failures)
	_expect(game.inventory.count("mud_bricks") == before + 1, "Collected output should enter player inventory.", failures)
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
