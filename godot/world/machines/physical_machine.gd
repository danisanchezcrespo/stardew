class_name PhysicalMachine
extends RefCounted

var instance_id: String
var recipe_inputs: Dictionary
var recipe_outputs: Dictionary
var process_time_seconds: float
var input_inventory: Variant
var output_inventory: Variant
var remaining_seconds := 0.0
var batches_completed := 0
var staffed := true
var manually_activated := false
var recipe_catalog: Array = []
var active_recipe_index := 0
var durability := 3
var max_durability := 3
var broken := false

func _init(stable_id: String, inputs: Dictionary, outputs: Dictionary, duration: float, item_registry: Variant, inventory_slots: int = 4, recipes: Array = []) -> void:
	instance_id = stable_id
	recipe_inputs = inputs.duplicate(true)
	recipe_outputs = outputs.duplicate(true)
	process_time_seconds = maxf(duration, 0.0)
	input_inventory = PlayerInventory.new(item_registry, inventory_slots)
	output_inventory = PlayerInventory.new(item_registry, inventory_slots)
	recipe_catalog = recipes.duplicate(true)
	if not recipe_catalog.is_empty(): select_recipe(0)

func select_recipe(index: int) -> bool:
	if is_running() or index < 0 or index >= recipe_catalog.size(): return false
	active_recipe_index = index
	var selected: Dictionary = recipe_catalog[index]
	recipe_inputs = selected.get("inputs", {}).duplicate(true)
	recipe_outputs = selected.get("outputs", {}).duplicate(true)
	process_time_seconds = float(selected.get("time", process_time_seconds))
	return true

func active_recipe_label() -> String:
	if recipe_catalog.is_empty(): return ""
	return str(recipe_catalog[active_recipe_index].get("label", recipe_catalog[active_recipe_index].get("id", "")))

func accepts(item_id: String) -> bool:
	return recipe_inputs.has(item_id)

func add_input(item_id: String, amount: int) -> int:
	return input_inventory.add(item_id, amount) if accepts(item_id) else 0

func repair(item_id: String, amount: int, required_item_id: String = "wood") -> int:
	if not broken or item_id != required_item_id or amount < 2:
		return 0
	durability = max_durability
	broken = false
	return 2

func process(delta: float) -> void:
	if not staffed or broken:
		return
	if remaining_seconds > 0.0:
		remaining_seconds = maxf(0.0, remaining_seconds - maxf(delta, 0.0))
		if remaining_seconds <= 0.0:
			_finish_batch()
		return
	if not _can_start_batch():
		return
	for item_id: String in recipe_inputs:
		input_inventory.remove(item_id, int(recipe_inputs[item_id]))
	remaining_seconds = process_time_seconds
	if remaining_seconds <= 0.0:
		_finish_batch()

func progress() -> float:
	return clampf(1.0 - remaining_seconds / process_time_seconds, 0.0, 1.0) if remaining_seconds > 0.0 and process_time_seconds > 0.0 else 0.0

func is_running() -> bool:
	return remaining_seconds > 0.0

func _can_start_batch() -> bool:
	for item_id: String in recipe_inputs:
		if input_inventory.count(item_id) < int(recipe_inputs[item_id]):
			return false
	for item_id: String in recipe_outputs:
		if output_inventory.capacity_for(item_id) < int(recipe_outputs[item_id]):
			return false
	return true

func _finish_batch() -> void:
	for item_id: String in recipe_outputs:
		output_inventory.add(item_id, int(recipe_outputs[item_id]))
	batches_completed += 1
	durability = maxi(0, durability - 1)
	broken = durability == 0
	remaining_seconds = 0.0
