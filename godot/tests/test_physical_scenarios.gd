extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var egypt := ScenarioType.new()
	var mesopotamia := ScenarioType.new()
	_expect(egypt.load_from_path("res://scenarios/physical/ancient_egypt.json") == OK, "Egypt scenario should load.", failures)
	_expect(mesopotamia.load_from_path("res://scenarios/physical/mesopotamia.json") == OK, "Mesopotamia scenario should load.", failures)
	_expect(egypt.scenario_id != mesopotamia.scenario_id, "Scenarios need stable distinct IDs.", failures)
	_expect(egypt.sand_color != mesopotamia.sand_color, "Scenario palette should be data-driven.", failures)
	_expect(egypt.water_rects != mesopotamia.water_rects, "Scenario geography should be data-driven.", failures)
	_expect(egypt.pickups[0].id != mesopotamia.pickups[0].id, "Scenario starting resources should be data-driven.", failures)
	if failures.is_empty():
		print("PASS: physical scenarios")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
