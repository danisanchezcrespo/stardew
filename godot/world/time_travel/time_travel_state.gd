class_name TimeTravelState
extends RefCounted

const SAVE_PATH := "user://time_traveler_meta.json"
const CATALOG_PATH := "res://world/time_travel/artifacts.json"
const DIALOGUE_PATH := "res://world/time_travel/dialogues.json"
const DIALOGUE_SAVE_VERSION := 2
const PORTAL_THRESHOLDS := [0, 3, 8, 15]
const ERA_PATHS := {
	"prehistory":"res://scenarios/physical/prehistory.json",
	"ancient_egypt":"res://scenarios/physical/ancient_egypt.json",
	"medieval":"res://scenarios/physical/medieval.json",
	"mars_colony":"res://scenarios/physical/mars_colony.json"
}

static var portal_bindings: Array[String] = ["", "", "", ""]
static var available_artifacts: Dictionary = {}
static var collected_artifacts: Dictionary = {}
static var carried_artifacts: Array[String] = []
static var exhibited_artifacts: Dictionary = {}
static var story_chapters_seen: Dictionary = {}
static var dialogue_seen: Dictionary = {}
static var loaded := false
static var catalog: Dictionary = {}
static var dialogue_catalog: Array = []
static var splash_seen_session := false
static var persistence_enabled := true


static func ensure_loaded() -> void:
	if loaded: return
	loaded = true
	_load_catalog()
	_load_dialogues()
	load_meta()


static func _load_catalog() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null: return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY: catalog = parsed


static func _load_dialogues() -> void:
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	if file == null: return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY: dialogue_catalog = parsed.get("dialogues", []).duplicate(true)


static func new_dialogues(era_id: String, completed: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in dialogue_catalog:
		var dialogue_id := str(row.get("id", "")); var trigger := str(row.get("trigger", ""))
		if str(row.get("era", "")) != era_id or dialogue_seen.has(dialogue_id): continue
		if trigger == "arrival" or completed.has(trigger):
			result.append(row.duplicate(true)); break
	return result


static func mark_dialogue_seen(dialogue_id: String) -> void:
	if dialogue_id.is_empty() or dialogue_seen.has(dialogue_id): return
	dialogue_seen[dialogue_id] = true
	save_meta()


static func artifact(id: String) -> Dictionary:
	for row: Dictionary in catalog.get("artifacts", []):
		if str(row.get("id", "")) == id: return row
	return {}


static func artifacts_for_era(era_id: String) -> Array:
	return catalog.get("artifacts", []).filter(func(row: Dictionary) -> bool: return str(row.get("era", "")) == era_id)


static func discover_from_campaign(era_id: String, completed: Dictionary) -> Array[String]:
	var discovered: Array[String] = []
	for row: Dictionary in artifacts_for_era(era_id):
		var id := str(row.id)
		if completed.has(str(row.objective)) and not available_artifacts.has(id) and not collected_artifacts.has(id):
			available_artifacts[id] = true
			discovered.append(id)
	if not discovered.is_empty(): save_meta()
	return discovered


static func collect_artifact(id: String) -> bool:
	if not available_artifacts.has(id) or collected_artifacts.has(id): return false
	collected_artifacts[id] = true
	available_artifacts.erase(id)
	if id not in carried_artifacts: carried_artifacts.append(id)
	save_meta()
	return true


static func exhibit_carried() -> Array[String]:
	var placed := carried_artifacts.duplicate()
	for id: String in carried_artifacts: exhibited_artifacts[id] = true
	carried_artifacts.clear()
	save_meta()
	return placed


static func portal_is_powered(slot: int) -> bool:
	return slot >= 0 and slot < PORTAL_THRESHOLDS.size() and exhibited_artifacts.size() >= int(PORTAL_THRESHOLDS[slot])


static func bind_portal(slot: int, era_id: String) -> bool:
	if not portal_is_powered(slot) or not portal_bindings[slot].is_empty() or not ERA_PATHS.has(era_id) or era_id in portal_bindings: return false
	portal_bindings[slot] = era_id
	save_meta()
	return true


static func unbound_eras() -> Array[String]:
	var result: Array[String] = []
	for era_id: String in ERA_PATHS:
		if era_id not in portal_bindings: result.append(era_id)
	return result


static func newly_unlocked_story_chapter() -> Dictionary:
	var total := exhibited_artifacts.size()
	var chapters: Array = catalog.get("story", [])
	for index in range(chapters.size()):
		var row: Dictionary = chapters[index]
		if total >= int(row.get("requires", 0)) and not story_chapters_seen.has(str(index)):
			story_chapters_seen[str(index)] = true
			save_meta()
			return row
	return {}


static func save_meta() -> Error:
	if not persistence_enabled: return OK
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version":1,"dialogue_version":DIALOGUE_SAVE_VERSION,"portals":portal_bindings,"available":available_artifacts,"collected":collected_artifacts,"carried":carried_artifacts,"exhibited":exhibited_artifacts,"story":story_chapters_seen,"dialogues":dialogue_seen}))
	return OK


static func load_meta() -> Error:
	if not persistence_enabled: return OK
	if not FileAccess.file_exists(SAVE_PATH): return OK
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY: return ERR_INVALID_DATA
	portal_bindings.clear()
	for value: Variant in data.get("portals", ["", "", "", ""]): portal_bindings.append(str(value))
	while portal_bindings.size() < 4: portal_bindings.append("")
	available_artifacts = data.get("available", {}).duplicate(true)
	collected_artifacts = data.get("collected", {}).duplicate(true)
	carried_artifacts.clear()
	for value: Variant in data.get("carried", []): carried_artifacts.append(str(value))
	exhibited_artifacts = data.get("exhibited", {}).duplicate(true)
	story_chapters_seen = data.get("story", {}).duplicate(true)
	# Dialogue v1 could mark lines as seen during capture/queueing before they
	# were ever presented. Replay the narrative once after upgrading that save.
	dialogue_seen = data.get("dialogues", {}).duplicate(true) if int(data.get("dialogue_version", 0)) == DIALOGUE_SAVE_VERSION else {}
	return OK


static func reset_for_tests() -> void:
	portal_bindings = ["", "", "", ""]
	available_artifacts.clear(); collected_artifacts.clear(); carried_artifacts.clear(); exhibited_artifacts.clear(); story_chapters_seen.clear(); dialogue_seen.clear()
