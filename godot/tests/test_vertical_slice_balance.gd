extends SceneTree

const ScenarioType = preload("res://world/scenario/physical_scenario.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var scenario := ScenarioType.new()
	scenario.load_from_path("res://scenarios/physical/ancient_egypt.json")
	var totals: Dictionary = {}
	for pickup: Dictionary in scenario.pickups:
		totals[pickup.item] = int(totals.get(pickup.item, 0)) + int(pickup.amount)
	# Full campaign costs: kiln, dwelling and shrine plans plus construction.
	# Forty bricks require twenty clay through the hand recipe; food and shrine
	# together require at least eight grain. Wood costs total thirty-five.
	_expect(int(totals.get("wood", 0)) >= 35, "Fresh Egypt map needs enough wood for the critical path.", failures)
	_expect(int(totals.get("clay", 0)) >= 20, "Fresh Egypt map needs enough clay for all required bricks.", failures)
	_expect(int(totals.get("grain", 0)) >= 8, "Fresh Egypt map needs food and shrine grain.", failures)
	_expect(int(totals.get("clay", 0)) > 20, "Critical resource should include recovery margin.", failures)
	if failures.is_empty():
		print("PASS: vertical slice balance")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
