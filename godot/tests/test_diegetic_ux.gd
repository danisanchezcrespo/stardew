extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")
const MainScene = preload("res://gameplay/main_game.tscn")
const TimeTravelStateType = preload("res://world/time_travel/time_travel_state.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	ScenarioType.requested_path = "res://scenarios/physical/medieval.json"
	ScenarioType.requested_autostart = true
	TimeTravelStateType.persistence_enabled = false
	var game: Node2D = MainScene.instantiate(); root.add_child(game)
	await process_frame; await process_frame
	if game.splash_open: game._close_splash()
	while game.dialogue_open: game._advance_dialogue()
	_expect(not InputMap.has_action("open_tech_tree") and not InputMap.has_action("sleep_day"), "Technology and sleep must not expose global shortcut actions.", failures)
	var university_id := _place_and_complete(game, "university_plan", Vector2i(20, 12))
	_expect(game.open_building_details(university_id) and game.building_context_button.visible, "The University must expose its study action in-world.", failures)
	game.building_details_context_action()
	_expect(game.tech_open, "Entering the University must open University Studies.", failures)
	game.set_tech_open(false)
	var home_id := _place_and_complete(game, "traveler_cottage_plan", Vector2i(10, 12))
	game.day_time_seconds = game.DAY_LENGTH_SECONDS * 0.6
	_expect(game.open_building_details(home_id) and game.building_context_button.text.contains("SLEEP"), "The Traveler's home must expose a Sleep button.", failures)
	game.building_details_context_action()
	_expect(is_equal_approx(game.day_time_seconds, game.MORNING_TIME_SECONDS), "Sleeping through the home must wake the world at 07:00.", failures)
	game.queue_free(); await process_frame
	if failures.is_empty(): print("PASS: diegetic UX"); quit(0); return
	for failure: String in failures: push_error(failure)
	quit(1)

func _place_and_complete(game: Node2D, item_id: String, origin: Vector2i) -> String:
	game.player.position = Vector2(origin + Vector2i(0,-1)) * game.CELL_SIZE + Vector2.ONE * 16.0
	game.player.facing = "south"; game.inventory.add(item_id, 1); game.select_quick_slot(_find_slot(game.inventory, item_id)); game.placement_cursor = origin; game.confirm_placement()
	var instance_id: String = game.world_grid.occupant_at(origin)
	var site: Variant = game.construction_by_entity_id[instance_id]
	for resource_id: String in site.requirements: site.deliver(resource_id, site.receivable(resource_id))
	game.apply_construction_work(instance_id, 60.0)
	return instance_id

func _find_slot(inventory: Variant, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if inventory.slots[index].get("item_id") == item_id: return index
	return -1

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
