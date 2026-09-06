extends SceneTree

const DirectorType = preload("res://world/progression/timeline_director.gd")
const ProgressionType = preload("res://world/progression/settlement_progression.gd")
const InventoryType = preload("res://player/player_inventory.gd")
const RegistryType = preload("res://items/item_registry.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var calendar := ProgressionType.new(); calendar.load_catalog("res://world/progression/progression_catalog.json", "medieval")
	var director := DirectorType.new(); _expect(director.configure("medieval", "res://world/progression/medieval_timeline.json") == OK, "Timeline catalog should load.", failures)
	var context := {"keep_built":true,"prosperity":0,"community":0,"beauty":0,"friendship":0,"exploration":0,"loaves":0}
	var first: Array[Dictionary] = director.begin_day(calendar, context)
	_expect(director.weekly_choices.size() == 3 and director.seasonal_choices.size() > 0, "A completed Keep should open nested weekly and seasonal choices.", failures)
	_expect(director.choose_weekly(0, context), "Player should be able to select a weekly ambition.", failures)
	context[director.active_weekly.metric] = int(director.active_weekly.target)
	_expect(not director.update(context).is_empty(), "Weekly ambitions should resolve from tracked world metrics.", failures)
	var registry := RegistryType.new(); registry.load_from_path("res://scenarios/medieval/items.json")
	var inventory := InventoryType.new(registry, 30)
	_expect(director.choose_project(0), "Player should be able to select a seasonal project.", failures)
	for item_id: String in director.active_project.cost: inventory.add(item_id, int(director.active_project.cost[item_id]))
	_expect(director.contribute_project(inventory).has("completed"), "Seasonal projects should accept persistent material contributions and complete.", failures)
	var event_ids: Array[String] = []
	for unused in range(1, 113):
		calendar.advance_day()
		for event: Dictionary in director.begin_day(calendar, context): event_ids.append(str(event.id))
	_expect("henwife_arrives" in event_ids and director.recipe_unlocked("chicken_coop_plan"), "Week Two should deliver and unlock husbandry content.", failures)
	_expect("ruin_door_opens" in event_ids and "winter_eclipse" in event_ids and "year_two_guest" in event_ids, "The authored year should deliver map, seasonal, and Year Two novelty.", failures)
	_expect(not director.pending_choice.is_empty() and not director.choose_event(0).is_empty(), "Major events should support remembered player choices.", failures)
	var restored := DirectorType.new(); restored.configure("medieval", "res://world/progression/medieval_timeline.json"); restored.restore(director.snapshot())
	_expect(restored.fired.size() == director.fired.size() and restored.completed_projects.size() == 1, "Timeline state and village memory should survive save/load.", failures)
	if failures.is_empty(): print("PASS: first living year timeline"); quit(0); return
	for failure: String in failures: push_error(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
