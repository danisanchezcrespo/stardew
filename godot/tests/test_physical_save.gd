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
	source.campaign.record_pickup("wood")
	var codec := CodecType.new()
	var path := "user://physical_save_test.json"
	_expect(codec.save_to_path(source, path) == OK, "Physical game should save to JSON.", failures)
	var save_key := InputEventKey.new()
	save_key.physical_keycode = KEY_K
	save_key.pressed = true
	source._unhandled_input(save_key)
	_expect(FileAccess.file_exists("user://physical_save.json"), "K input should save without invoking the editor's F5 shortcut.", failures)
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
	_expect(restored.campaign.gathered_wood and restored.campaign.completed == {}, "Partial campaign progress should round-trip.", failures)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://physical_save.json"))
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
