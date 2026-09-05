class_name PhysicalScenario
extends RefCounted

static var requested_path := ""

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

func load_from_path(path: String) -> Error:
	errors.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY: return ERR_INVALID_DATA
	scenario_id = str(data.get("id", ""))
	label = str(data.get("label", scenario_id))
	if scenario_id.is_empty(): return ERR_INVALID_DATA
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
