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
	_expect(game.population_label.position.x >= 830.0 and game.population_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "World status must occupy a dedicated right-aligned top-right region.", failures)
	_expect(game.objective_label.position.x + game.objective_label.size.x < game.population_label.position.x, "The centered goal and top-right world status must never overlap.", failures)
	_expect(not game.living_energy_label.text.contains("SLEEP") and not game.living_energy_label.text.contains("JOURNAL"), "The compact top-left status must not duplicate controls already shown below.", failures)
	_expect(not InputMap.has_action("open_tech_tree") and not InputMap.has_action("sleep_day"), "Technology and sleep must not expose global shortcut actions.", failures)
	var university_id := _place_and_complete(game, "university_plan", Vector2i(20, 12))
	_expect(game.open_building_details(university_id) and game.building_context_button.visible, "The University must expose its study action in-world.", failures)
	game.building_context_button.button_down.emit()
	_expect(game.tech_open, "Entering the University must open University Studies.", failures)
	_expect(game.tech_scroll != null and game.tech_canvas.custom_minimum_size.x > game.tech_scroll.size.x, "University knowledge layers should extend through a horizontal scroll.", failures)
	var milling_card := game.tech_canvas.get_node_or_null("Card_milling") as Control
	_expect(milling_card != null and game.tech_requirement_icons.get("milling", []).size() == 1, "Each University stage should show its required discoveries as icons below the heading.", failures)
	_expect(not game.tech_unlock_buttons["milling"].visible, "The Unlock button should remain hidden until every stage requirement is fulfilled.", failures)
	game.inventory.add("wheat", 1); game.meta_progression.research_points = 20; game._update_inventory_hud(); game._refresh_tech_panel()
	_expect(game.tech_unlock_buttons["milling"].visible and game.tech_unlock_buttons["milling"].text == "UNLOCK", "A ready University stage should expose its bottom Unlock button.", failures)
	game.set_tech_open(false)
	var home_id: String = game._ensure_traveller_home()
	_expect(game.placed_targets[home_id].target_kind == "building", "Space on the Traveller's home must open a building panel, never report an unavailable machine.", failures)
	game.day_time_seconds = game.DAY_LENGTH_SECONDS * 0.6
	_expect(game.open_building_details(home_id) and game.building_context_button.text.contains("SLEEP"), "The Traveler's home must expose a Sleep button.", failures)
	_expect(game.building_workshop_button.visible and game.building_workshop_button.text.contains("WORKSHOP"), "The Traveler's home must expose its Workshop as a second explicit action.", failures)
	game.building_workshop_button.button_down.emit()
	_expect(game.crafting_open and game.crafting_title_label.text.contains("TRAVELLER'S WORKSHOP"), "Crafting must open from the workshop inside the Traveler's home.", failures)
	game.set_crafting_open(false)
	game.open_building_details(home_id)
	var active_button_style := game.building_context_button.get_theme_stylebox("normal") as StyleBoxFlat
	_expect(active_button_style != null and active_button_style.bg_color.get_luminance() > 0.55, "Active panel buttons must use the clearly light visual style.", failures)
	var wake_position: Vector2 = game.placed_targets[home_id].interaction_position()
	game.building_context_button.button_down.emit()
	_expect(is_equal_approx(game.day_time_seconds, game.MORNING_TIME_SECONDS), "Sleeping through the home must wake the world at 07:00.", failures)
	_expect(game.player.position.is_equal_approx(wake_position), "Sleeping must wake the player at the cottage's exterior use port.", failures)
	game.close_day_summary()
	var market_id := _place_and_complete(game, "market_plan", Vector2i(26, 12))
	game.meta_progression.day = 7 # Sunday
	game.day_time_seconds = game.DAY_LENGTH_SECONDS * 0.5
	_expect(not game.is_work_time() and game.is_work_time_for(market_id), "The Village Market must trade on Sunday even while ordinary workshops rest.", failures)
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
