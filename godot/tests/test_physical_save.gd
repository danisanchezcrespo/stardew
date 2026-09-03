extends SceneTree

const CodecType = preload("res://world/persistence/physical_save_codec.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var packed: PackedScene = load("res://main.tscn")
	var source_root: Node = packed.instantiate()
	root.add_child(source_root)
	await process_frame
	var source: Node2D = source_root.get_node("MainGame")
	source.player.position = Vector2(300, 220)
	source.inventory.add("storage_crate", 1)
	source.select_quick_slot(_find_slot(source.inventory, "storage_crate"))
	source.begin_placement()
	var origin: Vector2i = source.placement_cursor
	source.confirm_placement()
	var crate_id: String = source.world_grid.occupant_at(origin)
	source.storage_by_entity_id[crate_id].add("grain", 7)
	source.inventory.add("brick_kiln_plan", 1)
	source.select_quick_slot(_find_slot(source.inventory, "brick_kiln_plan"))
	source.placement_cursor = Vector2i(11, 7)
	source.confirm_placement()
	var kiln_id: String = source.world_grid.occupant_at(Vector2i(11, 7))
	var site: Variant = source.construction_by_entity_id[kiln_id]
	for item_id: String in site.requirements:
		source.inventory.add(item_id, site.receivable(item_id))
		source.select_quick_slot(_find_slot(source.inventory, item_id))
		source.deliver_selected_to_construction(kiln_id)
	source.apply_construction_work(kiln_id, 1.25)
	source.campaign.record_pickup("wood")
	var codec := CodecType.new()
	var path := "user://physical_save_test.json"
	_expect(codec.save_to_path(source, path) == OK, "Physical game should save to JSON.", failures)
	source_root.queue_free()
	await process_frame
	var restored_root: Node = packed.instantiate()
	root.add_child(restored_root)
	await process_frame
	var restored: Node2D = restored_root.get_node("MainGame")
	_expect(codec.load_from_path(restored, path) == OK, "Fresh physical world should load saved state.", failures)
	_expect(restored.player.position == Vector2(300, 220), "Player position should round-trip.", failures)
	_expect(restored.world_grid.occupant_at(origin) == crate_id, "Placed entity identity should round-trip.", failures)
	_expect(restored.storage_by_entity_id[crate_id].count("grain") == 7, "Container contents should round-trip.", failures)
	_expect(is_equal_approx(restored.construction_by_entity_id[kiln_id].work_done_seconds, 1.25), "Partial construction work should round-trip without crashing.", failures)
	_expect(not restored.construction_by_entity_id[kiln_id].complete, "Partial construction should remain incomplete after load.", failures)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	restored_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: physical save")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _find_slot(inventory: Variant, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].get("item_id") == item_id: return index
	return -1

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
