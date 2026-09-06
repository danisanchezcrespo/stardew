extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")
const MainScene = preload("res://gameplay/main_game.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var paths := [
		"res://scenarios/physical/prehistory.json",
		"res://scenarios/physical/ancient_egypt.json",
		"res://scenarios/physical/medieval.json",
		"res://scenarios/physical/mars_colony.json",
	]
	for path: String in paths:
		ScenarioType.requested_path = path
		ScenarioType.requested_autostart = true
		var game := MainScene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		if game.scenario.scenario_id.is_empty():
			push_error("Runtime failed to initialize %s" % path)
			quit(1)
			return
		var homes: Array = game.world_grid.entities_by_id.values().filter(func(entity: Variant) -> bool: return str(entity.definition_id) == "TRAVELER_HOME")
		if homes.size() != 1 or game.time_targets.filter(func(target: Variant) -> bool: return target.target_kind == "time_portal").is_empty():
			push_error("Every era must begin with exactly one Traveller home and a return portal: %s" % path)
			quit(1)
			return
		if game.scenario.scenario_id == "prehistory":
			var mammoth: Variant = game.dependents.values()[0]
			game.inventory.add("spear", 1)
			for slot_index in range(game.inventory.slots.size()):
				if str(game.inventory.slots[slot_index].get("item_id", "")) == "spear": game.selected_slot = slot_index
			game.interact_with_dependent(mammoth)
			game.interact_with_dependent(mammoth)
			if game.inventory.count("mammoth_meat") <= 0 or game.inventory.count("hide") <= 0:
				push_error("A selected spear must complete a mammoth hunt")
				quit(1)
				return
			var hunted_snapshot: Dictionary = game.physical_save.capture(game)
			if game.physical_save.restore(game, hunted_snapshot) != OK or game.dependents.size() != 2:
				push_error("Saving and loading must not respawn a hunted mammoth")
				quit(1)
				return
		game.queue_free()
		await process_frame
	print("PASS: four era runtime")
	quit(0)
