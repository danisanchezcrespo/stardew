class_name EgyptCampaign
extends RefCounted

const DEFAULT_PATH := "res://world/progression/ancient_egypt_campaign.json"

var objectives: Array[Dictionary] = []
var completed: Dictionary = {}
var gathered_items: Dictionary = {}
var crafted_recipes: Dictionary = {}
var placed_entities: Dictionary = {}
var completed_entities: Dictionary = {}
var gathered_wood := false # Backward-compatible save fields.
var gathered_clay := false


func _init() -> void:
	load_from_path(DEFAULT_PATH)


func load_from_path(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("objectives")) != TYPE_ARRAY: return ERR_INVALID_DATA
	objectives.clear()
	for row: Variant in data.objectives:
		if typeof(row) != TYPE_DICTIONARY or not row.has_all(["id", "label", "type"]): return ERR_INVALID_DATA
		objectives.append(row.duplicate(true))
	return OK


func record_pickup(item_id: String) -> void:
	gathered_items[item_id] = true
	gathered_wood = gathered_items.has("wood")
	gathered_clay = gathered_items.has("clay")
	_refresh_event_objectives()


func record_craft(recipe_id: String) -> void:
	crafted_recipes[recipe_id] = true
	_refresh_event_objectives()


func record_placement(entity_id: String) -> void:
	placed_entities[entity_id] = true
	_refresh_event_objectives()


func record_completion(entity_id: String) -> void:
	completed_entities[entity_id] = true
	_refresh_event_objectives()


func refresh(machines: Dictionary, routes: Array, world_grid: Variant = null, villagers: Dictionary = {}) -> void:
	_refresh_event_objectives()
	for objective: Dictionary in objectives:
		if completed.has(str(objective.id)): continue
		match str(objective.type):
			"route_count":
				if routes.size() >= int(objective.get("count", 1)): completed[str(objective.id)] = true
			"population":
				if villagers.size() >= int(objective.get("count", 1)): completed[str(objective.id)] = true
			"produce":
				for instance_id: String in machines:
					var machine: Variant = machines[instance_id]
					if int(machine.batches_completed) <= 0: continue
					var output_id := str(objective.get("item", ""))
					if not output_id.is_empty() and machine.recipe_outputs.has(output_id): completed[str(objective.id)] = true
					var entity_id := str(objective.get("entity", ""))
					if not entity_id.is_empty() and world_grid != null:
						var placed: Variant = world_grid.entities_by_id.get(instance_id)
						if placed != null and placed.definition_id == entity_id: completed[str(objective.id)] = true


func _refresh_event_objectives() -> void:
	for objective: Dictionary in objectives:
		var objective_id := str(objective.id)
		if completed.has(objective_id): continue
		match str(objective.type):
			"gather":
				var ready := true
				for item_id: Variant in objective.get("items", []): ready = ready and gathered_items.has(str(item_id))
				if ready: completed[objective_id] = true
			"craft":
				if crafted_recipes.has(str(objective.get("recipe", ""))): completed[objective_id] = true
			"place":
				if placed_entities.has(str(objective.get("entity", ""))): completed[objective_id] = true
			"complete":
				if completed_entities.has(str(objective.get("entity", ""))): completed[objective_id] = true


func current_objective() -> Dictionary:
	for objective: Dictionary in objectives:
		if not completed.has(str(objective.id)): return objective
	return {}


func current_text() -> String:
	var objective := current_objective()
	if objective.is_empty(): return "DYNASTY ESTABLISHED  All %d chapters complete" % objectives.size()
	var chapter := objectives.find(objective) + 1
	return "CHAPTER %02d/%02d  %s\n%s" % [chapter, objectives.size(), str(objective.label), current_hint()]


func current_hint() -> String:
	var objective := current_objective()
	if objective.is_empty(): return "The Nile settlement can now sustain itself."
	if objective.has("hint"): return str(objective.hint)
	match str(objective.type):
		"gather": return "Explore nearby resource piles and press Space."
		"craft": return "Open Crafting with C; unavailable ingredients are marked red."
		"place": return "Craft its plan, then follow the placement ghost and press Space."
		"complete": return "Deliver the materials, then press Space once to begin construction."
		"produce": return "Supply the matching workshop; production continues while you explore."
		"population": return "Each completed house welcomes two settlers."
		"route_count": return "Select a villager, assign transport, then choose source and destination."
	return "Grow the settlement one deliberate step at a time."


func is_unlocked(objective_id: String) -> bool:
	return objective_id.is_empty() or completed.has(objective_id)


func is_complete() -> bool:
	return completed.size() >= objectives.size()
