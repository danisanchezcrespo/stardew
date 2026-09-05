class_name PhysicalScenario
extends RefCounted

static var requested_path := ""
static var requested_autostart := false

var scenario_id := ""
var label := ""
var sand_color := Color("#cdbb7d")
var water_color := Color("#4d8fbd")
var water_rects: Array = []
var water_gaps: Array[Vector2i] = []
var path_rects: Array = []
var pickups: Array = []
var resource_sources: Array = []
var crops: Array = []
var errors: Array[String] = []
var campaign_path := "res://world/progression/ancient_egypt_campaign.json"
var save_key := "ancient_egypt"
var terminology: Dictionary = {"people": "villagers", "person": "villager", "water": "water"}
var theme: Dictionary = {}
var ground_texture_path := "res://assets/generated/terrain/sand_v2.png"
var path_texture_path := ""
var character_sheet_path := ""
var character_sheet_paths: Array[String] = []
var environmental_events: Array = []
var dependents: Array = []
var wildlife: Array = []
var items_path := "res://items/items.json"
var recipes_path := "res://crafting/recipes.json"
var placeables_path := "res://world/placeables.json"
var food_item_id := "food_ration"
var repair_item_id := "wood"
var resident_names: Array[String] = []

func load_from_path(path: String) -> Error:
	errors.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY: return ERR_INVALID_DATA
	scenario_id = str(data.get("id", ""))
	label = str(data.get("label", scenario_id))
	if scenario_id.is_empty(): return ERR_INVALID_DATA
	save_key = str(data.get("save_key", scenario_id))
	campaign_path = str(data.get("campaign_path", campaign_path))
	terminology = data.get("terminology", terminology).duplicate(true)
	theme = data.get("theme", {}).duplicate(true)
	ground_texture_path = str(data.get("ground_texture", ground_texture_path))
	path_texture_path = str(data.get("path_texture", ""))
	character_sheet_path = str(data.get("character_sheet", ""))
	character_sheet_paths.clear()
	for sheet_path: Variant in data.get("character_sheets", []): character_sheet_paths.append(str(sheet_path))
	if character_sheet_paths.is_empty() and not character_sheet_path.is_empty(): character_sheet_paths.append(character_sheet_path)
	environmental_events = data.get("environmental_events", []).duplicate(true)
	dependents = data.get("dependents", []).duplicate(true)
	wildlife = data.get("wildlife", []).duplicate(true)
	items_path = str(data.get("items_path", items_path))
	recipes_path = str(data.get("recipes_path", recipes_path))
	placeables_path = str(data.get("placeables_path", placeables_path))
	food_item_id = str(data.get("food_item_id", food_item_id))
	repair_item_id = str(data.get("repair_item_id", repair_item_id))
	resident_names.clear()
	for resident_name: Variant in data.get("resident_names", []): resident_names.append(str(resident_name))
	var palette: Dictionary = data.get("palette", {})
	sand_color = Color(str(palette.get("ground", "#cdbb7d")))
	water_color = Color(str(palette.get("water", "#4d8fbd")))
	water_rects = data.get("water_rects", []).duplicate(true)
	path_rects = data.get("path_rects", []).duplicate(true)
	water_gaps.clear()
	for pair: Array in data.get("water_gaps", []): water_gaps.append(Vector2i(int(pair[0]), int(pair[1])))
	pickups = data.get("pickups", []).duplicate(true)
	for pickup: Dictionary in pickups:
		if not pickup.has_all(["id", "item", "amount", "cell"]): return ERR_INVALID_DATA
	resource_sources = data.get("resource_sources", []).duplicate(true)
	crops = data.get("crops", []).duplicate(true)
	for source: Dictionary in resource_sources:
		if not source.has_all(["id", "item", "cell", "max", "grant", "regen_amount", "regen_seconds"]): return ERR_INVALID_DATA
	return OK
