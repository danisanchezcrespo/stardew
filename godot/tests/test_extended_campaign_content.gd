extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")
const ItemRegistryType = preload("res://items/item_registry.gd")
const RecipeRegistryType = preload("res://crafting/recipe_registry.gd")
const PlacementRegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const CampaignType = preload("res://world/progression/egypt_campaign.gd")
const InputDefaultsType = preload("res://input/input_defaults.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	InputDefaultsType.ensure_actions()
	var items := ItemRegistryType.new()
	_expect(items.load_from_path("res://items/items.json") == OK, "Extended item registry should load.", failures)
	var recipes := RecipeRegistryType.new()
	_expect(recipes.load_from_path("res://crafting/recipes.json", items) == OK, "Extended recipes should load.", failures)
	var placeables := PlacementRegistryType.new()
	_expect(placeables.load_from_path("res://world/placeables.json") == OK, "Extended buildings should load.", failures)
	for item_id: String in ["limestone", "stone_blocks", "copper_ore", "copper_ingot", "flax", "linen", "papyrus_reeds", "papyrus_sheet", "bronze_tools"]:
		_expect(items.get_item(item_id) != null, "Missing industry item %s." % item_id, failures)
	for entity_id: String in ["QUARRY", "COPPER_MINE", "COPPER_SMELTER", "WEAVER", "PAPYRUS_WORKSHOP"]:
		_expect(placeables.get_entity(entity_id) != null, "Missing industry building %s." % entity_id, failures)
	var campaign := CampaignType.new()
	_expect(campaign.objectives.size() >= 30, "The main campaign should contain at least thirty chapters.", failures)
	_expect(recipes.get_recipe("shrine_plan").unlock_after == "make_papyrus", "The monument must cap the papyrus chain.", failures)
	var scenario := ScenarioType.new()
	_expect(scenario.load_from_path("res://scenarios/physical/ancient_egypt.json") == OK, "Expanded Nile scenario should load.", failures)
	_expect(not scenario.path_rects.is_empty(), "The authored map should include navigation paths.", failures)
	_expect(scenario.resource_sources.size() >= 5, "The late campaign needs flax and papyrus sources.", failures)
	for path: String in ["res://assets/generated/buildings/egypt_industry_buildings.png", "res://assets/generated/items/egypt_industry_item_icons.png", "res://assets/generated/character/egyptian_man_lateral_sheet.png", "res://assets/audio/build_complete.wav"]:
		_expect(ResourceLoader.exists(path), "Missing imported content asset %s." % path, failures)
	_expect(InputMap.has_action("open_logistics"), "A dedicated logistics action should exist.", failures)
	if failures.is_empty():
		print("PASS: extended campaign content")
		quit(0)
		return
	for failure: String in failures: push_error(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
