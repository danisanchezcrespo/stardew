extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const ItemRegistryType = preload("res://items/item_registry.gd")
const MachineType = preload("res://world/machines/physical_machine.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var registry := RegistryType.new()
	_expect(registry.load_from_path("res://scenarios/medieval/placeables.json") == OK, "Medieval placeables should load.", failures)
	var sculptor: Variant = registry.get_entity("SCULPTOR_WORKSHOP")
	var nursery: Variant = registry.get_entity("GARDEN_NURSERY")
	_expect(sculptor != null and sculptor.machine_recipes.size() == 8, "The sculptor should offer eight statues.", failures)
	_expect(nursery != null and nursery.machine_recipes.size() == 8, "The nursery should offer eight garden pieces.", failures)
	var decoration_count := 0
	for entity_id: String in registry.entity_order:
		if entity_id.begins_with("DECOR_"): decoration_count += 1
	_expect(decoration_count >= 19, "The medieval catalog should contain the existing and sixteen new decorations.", failures)
	var items := ItemRegistryType.new(); items.load_from_path("res://scenarios/medieval/items.json")
	var machine := MachineType.new("sculptor", sculptor.recipe_inputs, sculptor.recipe_outputs, sculptor.process_time_sec, items, 4, sculptor.machine_recipes)
	_expect(machine.active_recipe_label() == "Stone Lion" and machine.select_recipe(7), "Catalog machines should select a recipe.", failures)
	_expect(machine.recipe_outputs.has("stone_birdbath"), "Selected recipe should replace machine outputs.", failures)
	machine.add_input("field_stone", 4); machine.process(0.1)
	_expect(machine.is_running() and not machine.select_recipe(0), "A running batch must keep its selected recipe.", failures)
	if failures.is_empty(): print("PASS: medieval customization"); quit(0); return
	for failure: String in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
