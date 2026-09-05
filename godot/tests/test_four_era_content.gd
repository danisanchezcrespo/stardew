extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")
const ItemRegistryType = preload("res://items/item_registry.gd")
const RecipeRegistryType = preload("res://crafting/recipe_registry.gd")
const PlacementRegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var ids: Dictionary = {}
	var saves: Dictionary = {}
	var paths := [
		"res://scenarios/physical/prehistory.json",
		"res://scenarios/physical/ancient_egypt.json",
		"res://scenarios/physical/medieval.json",
		"res://scenarios/physical/mars_colony.json",
	]
	for path: String in paths:
		var scenario := ScenarioType.new()
		_expect(scenario.load_from_path(path) == OK, "%s must load" % path, failures)
		if scenario.scenario_id.is_empty(): continue
		_expect(not ids.has(scenario.scenario_id), "Scenario IDs must be unique", failures)
		_expect(not saves.has(scenario.save_key), "Save slots must be unique", failures)
		ids[scenario.scenario_id] = true
		saves[scenario.save_key] = true
		var items := ItemRegistryType.new()
		_expect(items.load_from_path(scenario.items_path) == OK, "%s items must load" % scenario.scenario_id, failures)
		var recipes := RecipeRegistryType.new()
		_expect(recipes.load_from_path(scenario.recipes_path, items) == OK, "%s recipes must load" % scenario.scenario_id, failures)
		var placeables := PlacementRegistryType.new()
		_expect(placeables.load_from_path(scenario.placeables_path) == OK, "%s buildings must load" % scenario.scenario_id, failures)
		_expect(FileAccess.file_exists(scenario.campaign_path), "%s campaign must exist" % scenario.scenario_id, failures)
		_expect(ResourceLoader.exists(scenario.ground_texture_path), "%s ground must exist" % scenario.scenario_id, failures)
		_expect(ResourceLoader.exists(scenario.character_sheet_path) or scenario.character_sheet_path.is_empty(), "%s character must exist" % scenario.scenario_id, failures)
	var prehistory := ScenarioType.new()
	prehistory.load_from_path(paths[0])
	_expect(prehistory.wildlife.size() >= 3, "Prehistory needs a huntable herd", failures)
	_expect(str(prehistory.dependents[0].get("required_tool", "")) == "spear", "Mammoth hunting must require a spear", failures)
	if failures.is_empty():
		print("PASS: four era content")
		quit(0)
		return
	for failure: String in failures: push_error(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
