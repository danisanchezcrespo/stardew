extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const EngineType = preload("res://simulation/simulation_engine.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var registry := RegistryType.new()
	var result: Error = registry.load_from_path("res://scenarios/ancient_egypt/entities.json")
	_expect(result == OK, "Ancient Egypt definitions must load.", failures)

	_test_empty_world(registry, failures)
	_test_fixed_point_chain(registry, failures)
	_test_unfinished_nodes_count(registry, failures)

	if failures.is_empty():
		print("PASS: progression system")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_empty_world(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	var reachable: Array[String] = engine.progression.compute_reachable_resources(engine.state)
	_expect(reachable.is_empty(), "Empty world should have no reachable resources.", failures)
	_expect(engine.progression.is_entity_unlocked(engine.state, "NILE_RIVER"), "Requirement-free source should be unlocked.", failures)
	_expect(not engine.progression.is_entity_unlocked(engine.state, "BRICK_KILN"), "Kiln should be locked without wood reachability.", failures)


func _test_fixed_point_chain(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	engine.create_node("DELTA_FOREST", 0.0, 0.0)
	engine.create_node("CLAY_PIT", 0.0, 0.0)
	engine.create_node("NILE_RIVER", 0.0, 0.0)
	engine.create_node("BRICK_KILN", 0.0, 0.0)
	var reachable: Array[String] = engine.progression.compute_reachable_resources(engine.state)
	_expect(reachable.has("wood") and reachable.has("clay") and reachable.has("water"), "Placed sources should make raw resources reachable.", failures)
	_expect(reachable.has("mud_bricks"), "Fixed point should include output of reachable kiln chain.", failures)
	_expect(engine.progression.is_entity_unlocked(engine.state, "WORKERS_HUTS"), "Reachable wood and bricks should unlock huts.", failures)


func _test_unfinished_nodes_count(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	engine.create_node("DELTA_FOREST", 0.0, 0.0)
	engine.create_node("CLAY_PIT", 0.0, 0.0)
	engine.create_node("NILE_RIVER", 0.0, 0.0)
	var unfinished: Variant = engine.create_node("BRICK_KILN", 0.0, 0.0)
	_expect(unfinished.state == "UNDER_CONSTRUCTION", "Fixture kiln should be unfinished.", failures)
	var reachable: Array[String] = engine.progression.compute_reachable_resources(engine.state)
	_expect(reachable.has("mud_bricks"), "Legacy unlocks should count unfinished placed types.", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
