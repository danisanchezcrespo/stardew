extends SceneTree

const StateType = preload("res://world/time_travel/time_travel_state.gd")
const ScenarioType = preload("res://world/scenario/physical_scenario.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	StateType.persistence_enabled = false; StateType.loaded = false; StateType.ensure_loaded(); StateType.reset_for_tests()
	for era_id: String in ["prehistory","ancient_egypt","medieval","mars_colony"]:
		var era_dialogues: Array = StateType.dialogue_catalog.filter(func(row: Dictionary) -> bool: return str(row.era) == era_id)
		_expect(era_dialogues.size() == 10, "%s should contain ten contextual narrative moments." % era_id, failures)
	var arrival := StateType.new_dialogues("prehistory", {})
	_expect(arrival.size() == 1 and str(arrival[0].id) == "pre_arrival", "Arrival should trigger its era introduction exactly once.", failures)
	StateType.mark_dialogue_seen(str(arrival[0].id))
	_expect(StateType.new_dialogues("prehistory", {}).is_empty(), "Seen dialogue must not repeat.", failures)
	_expect(str(StateType.new_dialogues("prehistory", {"gather_stone_age":true})[0].id) == "pre_gather", "Campaign milestones should trigger contextual dialogue.", failures)
	_expect(StateType.portal_is_powered(0), "The first portal should begin powered.", failures)
	_expect(not StateType.portal_is_powered(1), "The second portal should begin dormant.", failures)
	_expect(StateType.bind_portal(0, "mars_colony"), "The player should freely choose the first era.", failures)
	_expect(not StateType.bind_portal(0, "prehistory"), "A bound portal must remain permanent.", failures)
	var completed := {"melt_ice":true,"make_oxygen":true,"grow_algae":true}
	var discovered := StateType.discover_from_campaign("mars_colony", completed)
	_expect(discovered.size() == 3, "Three campaign milestones should reveal three physical artifacts.", failures)
	for artifact_id: String in discovered: _expect(StateType.collect_artifact(artifact_id), "A revealed artifact should be recoverable.", failures)
	_expect(StateType.carried_artifacts.size() == 3, "Recovered artifacts should be carried between worlds.", failures)
	StateType.exhibit_carried()
	_expect(StateType.exhibited_artifacts.size() == 3 and StateType.portal_is_powered(1), "Three exhibits should power the second portal.", failures)
	_expect(StateType.bind_portal(1, "prehistory"), "The next portal should allow another freely selected era.", failures)
	_expect(not StateType.newly_unlocked_story_chapter().is_empty(), "Museum progress should reveal traveler backstory.", failures)
	StateType.available_artifacts["first_martian_water"] = true
	ScenarioType.requested_path = "res://scenarios/physical/mars_colony.json"; ScenarioType.requested_autostart = true
	var era_scene: PackedScene = load("res://main.tscn"); var era_root := era_scene.instantiate(); root.add_child(era_root); await process_frame
	var era_game: Node2D = era_root.get_node("MainGame")
	_expect(era_game.artifact_nodes.has("first_martian_water"), "An unlocked artifact should appear physically in its era.", failures)
	_expect(era_game.time_targets.any(func(target: Variant) -> bool: return target.target_kind == "time_portal"), "Every era should contain a physical return portal.", failures)
	era_root.queue_free(); await process_frame
	StateType.splash_seen_session = false
	ScenarioType.requested_path = "res://scenarios/physical/time_museum.json"; ScenarioType.requested_autostart = true
	var packed: PackedScene = load("res://main.tscn"); var game_root := packed.instantiate(); root.add_child(game_root); await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	_expect(game.scenario.scenario_id == "time_museum" and game.portal_nodes.size() == 4, "The game should open a physical museum with four portals.", failures)
	_expect(game.time_targets.size() >= 5, "Museum portals and archive must be physical interaction targets.", failures)
	StateType.dialogue_seen.erase("museum_intro")
	game._open_splash()
	var intro_rows := StateType.new_dialogues("time_museum", {})
	for row: Dictionary in intro_rows: game.dialogue_queue.append(row)
	_expect(game.splash_open, "A fresh application session should open on the Time Quest splash screen.", failures)
	game._close_splash()
	_expect(game.dialogue_open and game.dialogue_text.text.contains("traveler through time"), "First start should introduce the time traveler through the reusable dialogue system.", failures)
	game_root.queue_free(); await process_frame; StateType.persistence_enabled = true; StateType.loaded = false
	if failures.is_empty(): print("PASS: time travel metagame"); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
