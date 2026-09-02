extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	_test_ancient_egypt(failures)
	_test_legacy_defaults(failures)
	_test_invalid_edge_mode(failures)

	if failures.is_empty():
		print("PASS: definition registry")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_ancient_egypt(failures: Array[String]) -> void:
	var registry := RegistryType.new()
	var result: Error = registry.load_from_path("res://scenarios/ancient_egypt/entities.json")
	_expect(result == OK, "Ancient Egypt definitions should load: %s" % str(registry.errors), failures)
	_expect(registry.entities_by_id.size() == 35, "Expected 35 Ancient Egypt entities.", failures)
	_expect(registry.edge_types_by_id.size() == 4, "Expected 4 Ancient Egypt edge types.", failures)
	_expect(registry.get_default_edge_type_id() == "PORTER", "PORTER should be the default edge type.", failures)

	var kiln: Variant = registry.get_entity("BRICK_KILN")
	_expect(kiln != null, "BRICK_KILN should exist.", failures)
	if kiln != null:
		_expect(kiln.recipe_inputs.get("clay") == 2.0, "BRICK_KILN should consume 2 clay.", failures)
		_expect(kiln.recipe_outputs.get("mud_bricks") == 4.0, "BRICK_KILN should produce 4 bricks.", failures)
		_expect(kiln.min_worker_efficiency == 0.25, "BRICK_KILN efficiency floor should be 0.25.", failures)


func _test_legacy_defaults(failures: Array[String]) -> void:
	var registry := RegistryType.new()
	var result: Error = registry.load_from_dictionary(
		{
			"entities": [{"id": "SOURCE", "recipe_outputs": {"ore": 1}}],
			"edge_types": [{"id": "ROAD"}],
		}
	)
	_expect(result == OK, "Legacy edge_types alias should load.", failures)
	var source: Variant = registry.get_entity("SOURCE")
	var road: Variant = registry.get_edge_type("ROAD")
	_expect(source.label == "SOURCE", "Entity label should default to its ID.", failures)
	_expect(source.color == "#888888", "Entity color default should match legacy.", failures)
	_expect(road.speed == 50.0, "Edge speed default should match legacy.", failures)
	_expect(road.capacity_per_trip == 10.0, "Edge capacity default should match legacy.", failures)
	_expect(road.mode == "one_way", "Edge mode default should match legacy.", failures)


func _test_invalid_edge_mode(failures: Array[String]) -> void:
	var registry := RegistryType.new()
	var result: Error = registry.load_from_dictionary(
		{
			"entities": [],
			"edges": [{"id": "INVALID", "mode": "teleport"}],
		}
	)
	_expect(result == ERR_INVALID_DATA, "Invalid edge mode should be rejected.", failures)
	_expect(not registry.errors.is_empty(), "Invalid data should produce a diagnostic.", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
