class_name SettlementProgression
extends RefCounted

const SEASONS := ["Dawn", "High Sun", "Harvest", "Long Night"]
const DAYS_PER_SEASON := 8

var day := 1
var season_index := 0
var year := 1
var research_points := 0
var unlocked_tech: Dictionary = {}
var donated_items: Dictionary = {}
var building_levels: Dictionary = {}
var catalog: Dictionary = {}


func load_catalog(path: String, scenario_id: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY: return ERR_INVALID_DATA
	catalog = data.get(scenario_id, {}).duplicate(true)
	return OK if not catalog.is_empty() else ERR_DOES_NOT_EXIST


func advance_day() -> Dictionary:
	day += 1
	research_points += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season_index = (season_index + 1) % SEASONS.size()
		if season_index == 0: year += 1
	return {"day":day, "season":season_name(), "year":year, "research":research_points}


func season_name() -> String:
	var names: Array = catalog.get("seasons", SEASONS)
	return str(names[season_index % names.size()])


func calendar_text() -> String:
	return "%s %d - Year %d" % [season_name(), day, year]


func tech_nodes() -> Array:
	return catalog.get("tech", [])


func collection_items() -> Array:
	return catalog.get("collection", [])


func tech_node(node_id: String) -> Dictionary:
	for node: Dictionary in tech_nodes():
		if str(node.get("id", "")) == node_id: return node
	return {}


func can_unlock(node_id: String) -> bool:
	var node := tech_node(node_id)
	if node.is_empty() or unlocked_tech.has(node_id): return false
	for requirement: Variant in node.get("requires", []):
		if not unlocked_tech.has(str(requirement)): return false
	return research_points >= int(node.get("cost", 1))


func unlock(node_id: String) -> bool:
	if not can_unlock(node_id): return false
	var node := tech_node(node_id)
	research_points -= int(node.get("cost", 1))
	unlocked_tech[node_id] = true
	return true


func recipe_unlocked(recipe_id: String) -> bool:
	for node: Dictionary in tech_nodes():
		if recipe_id in node.get("recipes", []): return unlocked_tech.has(str(node.id))
	return true


func donate(item_id: String) -> bool:
	if donated_items.has(item_id): return false
	for entry: Dictionary in collection_items():
		if str(entry.get("item", "")) == item_id:
			donated_items[item_id] = true
			research_points += int(entry.get("research", 1))
			return true
	return false


func collection_progress() -> Vector2i:
	return Vector2i(donated_items.size(), collection_items().size())


func building_level(instance_id: String) -> int:
	return int(building_levels.get(instance_id, 1))


func upgrade_building(instance_id: String) -> int:
	var next_level := mini(3, building_level(instance_id) + 1)
	building_levels[instance_id] = next_level
	return next_level


func snapshot() -> Dictionary:
	return {"day":day,"season":season_index,"year":year,"research":research_points,"tech":unlocked_tech.duplicate(true),"collection":donated_items.duplicate(true),"levels":building_levels.duplicate(true)}


func restore(data: Dictionary) -> void:
	day = maxi(1, int(data.get("day", 1)))
	season_index = clampi(int(data.get("season", 0)), 0, SEASONS.size() - 1)
	year = maxi(1, int(data.get("year", 1)))
	research_points = maxi(0, int(data.get("research", 0)))
	unlocked_tech = data.get("tech", {}).duplicate(true)
	donated_items = data.get("collection", {}).duplicate(true)
	building_levels = data.get("levels", {}).duplicate(true)
