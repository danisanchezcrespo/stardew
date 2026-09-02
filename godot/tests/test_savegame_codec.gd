extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const EngineType = preload("res://simulation/simulation_engine.gd")
const NodeInstanceType = preload("res://simulation/state/node_instance.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var registry := RegistryType.new()
	var result: Error = registry.load_from_path("res://scenarios/ancient_egypt/entities.json")
	_expect(result == OK, "Ancient Egypt definitions must load.", failures)

	_test_load_bundled_fixtures(registry, failures)
	_test_active_state_round_trip(registry, failures)
	_test_file_round_trip(registry, failures)
	_test_version_rejection(registry, failures)
	_test_legacy_version_without_world(registry, failures)
	_test_world_round_trip(failures)
	_test_corrupt_world_is_rejected(failures)

	if failures.is_empty():
		print("PASS: savegame codec")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_load_bundled_fixtures(registry: Variant, failures: Array[String]) -> void:
	var cases := {
		"res://scenarios/ancient_egypt/fixtures/egypt.json": [29, 4, 32],
		"res://scenarios/ancient_egypt/fixtures/eg2.json": [56, 19, 79],
	}
	for path: String in cases:
		var expected: Array = cases[path]
		var engine := EngineType.new(registry)
		var result: Error = engine.load_from_path(path)
		_expect(result == OK, "Fixture should load: %s" % path, failures)
		_expect(engine.state.nodes.size() == expected[0], "Fixture node count should match: %s" % path, failures)
		_expect(engine.state.edges.size() == expected[1], "Fixture edge count should match: %s" % path, failures)
		_expect(engine.state.next_node_id == expected[2], "next_node_id should rebuild: %s" % path, failures)


func _test_active_state_round_trip(registry: Variant, failures: Array[String]) -> void:
	var source_engine := EngineType.new(registry)
	var nile: Variant = source_engine.create_node("NILE_RIVER", 0.0, 0.0)
	var farm: Variant = source_engine.create_node("GRAIN_FARM", 45.0, 0.0)
	farm.state = NodeInstanceType.STATE_READY
	farm.inventory = {"water": 2.0}
	source_engine.connect_nodes(nile.id, farm.id, "PORTER")
	source_engine.step(0.1)
	source_engine.step(0.1)
	var data := source_engine.build_savegame_data()

	var loaded_engine := EngineType.new(registry)
	var result: Error = loaded_engine.load_from_dictionary(data)
	_expect(result == OK, "In-memory savegame should load.", failures)
	_expect(loaded_engine.state.nodes.size() == 2, "Round-trip should preserve nodes.", failures)
	_expect(loaded_engine.state.edges.size() == 1, "Round-trip should preserve edges.", failures)
	var loaded_farm: Variant = loaded_engine.graph.get_node(farm.id)
	var loaded_edge: Variant = loaded_engine.state.edges[0]
	_expect(loaded_farm.active_process_remaining_sec == farm.active_process_remaining_sec, "Round-trip should preserve active process time.", failures)
	_expect(loaded_edge.packet != null, "In-flight packet should be preserved.", failures)
	if loaded_edge.packet != null:
		var source_edge: Variant = source_engine.state.edges[0]
		_expect(loaded_edge.packet.resource_name == source_edge.packet.resource_name, "Packet resource should survive round-trip.", failures)
		_expect(loaded_edge.packet.amount == source_edge.packet.amount, "Packet amount should survive round-trip.", failures)
		_expect(loaded_edge.packet.progress == source_edge.packet.progress, "Packet progress should survive round-trip.", failures)
	_expect(loaded_edge.return_progress == null, "Null return progress should be preserved.", failures)
	_expect(loaded_engine.state.next_node_id == 3, "Round-trip should restore next node ID.", failures)
	_expect(loaded_engine.step_count == 0, "Runtime step counter should reset on load.", failures)


func _test_file_round_trip(registry: Variant, failures: Array[String]) -> void:
	var source_engine := EngineType.new(registry)
	source_engine.create_node("NILE_RIVER", 12.0, 34.0)
	var path := "res://.godot/savegame-codec-test.json"
	var save_result: Error = source_engine.save_to_path(path)
	_expect(save_result == OK, "Savegame should write to user storage.", failures)
	var loaded_engine := EngineType.new(registry)
	var load_result: Error = loaded_engine.load_from_path(path)
	_expect(load_result == OK, "Written savegame should load.", failures)
	var loaded: Variant = loaded_engine.graph.get_node(1)
	_expect(loaded != null and loaded.world_x == 12.0 and loaded.world_y == 34.0, "File round-trip should preserve coordinates.", failures)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_version_rejection(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	engine.create_node("NILE_RIVER", 0.0, 0.0)
	var result: Error = engine.load_from_dictionary({"version": 999, "nodes": [], "edges": [], "state": {}})
	_expect(result == ERR_FILE_UNRECOGNIZED, "Unknown savegame version should be rejected.", failures)
	_expect(engine.state.nodes.size() == 1, "Rejected version should not clear current simulation.", failures)


func _test_legacy_version_without_world(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	engine.configure_world(Vector2i(2, 2))
	var result: Error = engine.load_from_dictionary({"version": 1, "nodes": [], "edges": [], "state": {}})
	_expect(result == OK, "Version 1 simulation-only savegames should remain loadable.", failures)
	_expect(engine.world_grid == null, "Legacy savegame should load without inventing a physical world.", failures)


func _test_world_round_trip(failures: Array[String]) -> void:
	var registry: Variant = _spatial_registry(failures)
	var source := EngineType.new(registry)
	var world: Variant = source.configure_world(Vector2i(6, 4), "sand")
	world.set_terrain(Vector2i(0, 0), "water")
	var chest: Variant = registry.get_entity("CHEST")
	var result: Variant = world.place("chest-7", "CHEST", chest.spatial_footprint, Vector2i(2, 1), 2, chest.allowed_terrain)
	_expect(result.valid, "World fixture entity should place before saving.", failures)
	var data: Dictionary = source.build_savegame_data()
	_expect(data.version == 2 and data.has("world"), "New savegames should include versioned world data.", failures)

	var loaded := EngineType.new(registry)
	var load_result: Error = loaded.load_from_dictionary(data)
	_expect(load_result == OK, "Physical world should load: %s" % str(loaded.savegames.errors), failures)
	_expect(loaded.world_grid != null and loaded.world_grid.size == Vector2i(6, 4), "World dimensions should survive round-trip.", failures)
	if loaded.world_grid != null:
		_expect(loaded.world_grid.terrain_at(Vector2i(0, 0)) == "water", "Terrain override should survive round-trip.", failures)
		_expect(loaded.world_grid.occupant_at(Vector2i(2, 1)) == "chest-7", "Occupancy should rebuild from entities.", failures)
		var restored: Variant = loaded.world_grid.entities_by_id.get("chest-7")
		_expect(restored != null and restored.rotation == 2, "Stable ID and rotation should survive round-trip.", failures)

	var path := "res://.godot/physical-world-savegame-test.json"
	var save_result: Error = source.save_to_path(path)
	var loaded_from_file := EngineType.new(registry)
	var file_result: Error = loaded_from_file.load_from_path(path)
	_expect(save_result == OK and file_result == OK, "Physical world JSON file should round-trip: %s" % str(loaded_from_file.savegames.errors), failures)
	_expect(loaded_from_file.world_grid != null and loaded_from_file.world_grid.occupant_at(Vector2i(2, 1)) == "chest-7", "JSON parsing should preserve integer placement coordinates.", failures)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_corrupt_world_is_rejected(failures: Array[String]) -> void:
	var registry: Variant = _spatial_registry(failures)
	var engine := EngineType.new(registry)
	var original_world: Variant = engine.configure_world(Vector2i(3, 3), "sand")
	var data := {
		"version": 2,
		"nodes": [],
		"edges": [],
		"state": {},
		"world": {
			"size": [3, 3],
			"default_terrain": "sand",
			"terrain": [],
			"entities": [
				{"instance_id": "a", "definition_id": "CHEST", "origin": [0, 0], "rotation": 0},
				{"instance_id": "b", "definition_id": "CHEST", "origin": [1, 0], "rotation": 0},
			],
		},
	}
	var result: Error = engine.load_from_dictionary(data)
	_expect(result == ERR_INVALID_DATA, "Overlapping restored entities should reject the savegame.", failures)
	_expect(engine.world_grid == original_world, "Rejected world must not replace current world state.", failures)
	_expect(not engine.savegames.errors.is_empty(), "Corrupt world should provide a diagnostic.", failures)


func _spatial_registry(failures: Array[String]) -> Variant:
	var registry := RegistryType.new()
	var result: Error = registry.load_from_dictionary(
		{
			"entities": [{
				"id": "CHEST",
				"spatial": {
					"footprint": [[0, 0], [1, 0]],
					"rotations": [0, 2],
					"allowed_terrain": ["sand"],
					"ports": {"use": [0, 1]},
				},
			}],
			"edges": [],
		}
	)
	_expect(result == OK, "Spatial savegame registry should load: %s" % str(registry.errors), failures)
	return registry


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
