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
	_expect(machine.active_recipe_label() == "Stone Lion" and machine.unlocked_recipe_count() == 2, "A new catalog workshop should begin with two designs.", failures)
	_expect(not machine.select_recipe(2), "Designs beyond the workshop's mastery must remain locked.", failures)
	machine.batches_completed = 5
	_expect(machine.mastery_level() == 2 and machine.unlocked_recipe_count() == 4 and machine.select_recipe(3), "Five completed pieces should unlock Mastery 2 and two more designs.", failures)
	_expect(machine.recipe_outputs.has("angel_fountain"), "An unlocked recipe should replace machine outputs.", failures)
	machine.add_input("field_stone", 4); machine.process(0.1)
	# The fountain needs six stone, so switch to a buildable unlocked recipe first.
	machine.select_recipe(1); machine.add_input("field_stone", 4); machine.process(0.1)
	_expect(machine.is_running() and not machine.select_recipe(0), "A running batch must keep its selected recipe.", failures)
	if failures.is_empty(): print("PASS: medieval customization"); quit(0); return
	for failure: String in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
