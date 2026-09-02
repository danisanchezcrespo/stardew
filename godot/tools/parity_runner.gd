extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const EngineType = preload("res://simulation/simulation_engine.gd")

const SNAPSHOT_FORMAT_VERSION := 1
const FLOAT_SCALE := 1000000000000.0

var engine: Variant
var aliases: Dictionary = {}


func _initialize() -> void:
	var arguments := _parse_arguments(OS.get_cmdline_user_args())
	if not arguments.has("scenario") or not arguments.has("output"):
		_fail("Usage: --scenario PATH --output PATH")
		return

	var scenario_path := str(arguments.scenario)
	var scenario_data: Variant = _read_json(scenario_path)
	if scenario_data == null or typeof(scenario_data) != TYPE_DICTIONARY:
		_fail("Unable to read parity scenario: %s" % scenario_path)
		return

	var registry := RegistryType.new()
	var definitions_path := "res://scenarios/ancient_egypt/entities.json"
	if scenario_data.has("definitions"):
		definitions_path = _repository_path(str(scenario_data.definitions))
	var load_result: Error = registry.load_from_path(definitions_path)
	if load_result != OK:
		_fail("Unable to load definitions: %s" % str(registry.errors))
		return
	engine = EngineType.new(registry)

	var actions: Variant = scenario_data.get("actions", [])
	if typeof(actions) != TYPE_ARRAY:
		_fail("Scenario actions must be an array.")
		return
	for index in range(actions.size()):
		var error_message := _apply_action(actions[index])
		if not error_message.is_empty():
			_fail("Action %d failed: %s" % [index, error_message])
			return

	var scenario_name := str(scenario_data.get("name", scenario_path.get_file().get_basename()))
	var snapshot := _build_snapshot(scenario_name)
	var output_path := str(arguments.output)
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	if output == null:
		_fail("Unable to open snapshot output: %s" % output_path)
		return
	output.store_string(JSON.stringify(snapshot, "  ", false) + "\n")
	print("PASS: Godot parity runner - %s" % scenario_name)
	quit(0)


func _apply_action(action: Variant) -> String:
	if typeof(action) != TYPE_DICTIONARY:
		return "Action must be an object."
	var operation := str(action.get("op", ""))
	match operation:
		"load_save":
			var result: Error = engine.load_from_path(_repository_path(str(action.path)))
			if result != OK:
				return "Unable to load savegame: %s" % str(engine.savegames.errors)
			aliases.clear()
		"create_node":
			var node: Variant = engine.create_node(
				str(action.entity_type),
				float(action.get("x", 0.0)),
				float(action.get("y", 0.0))
			)
			if node == null:
				return "Unable to create entity type '%s'." % str(action.entity_type)
			var alias := str(action.get("as", ""))
			if not alias.is_empty():
				if aliases.has(alias):
					return "Duplicate node alias '%s'." % alias
				aliases[alias] = node.id
		"connect":
			var from_id := _resolve_node(action.get("from"))
			var to_id := _resolve_node(action.get("to"))
			if from_id <= 0 or to_id <= 0:
				return "Connection contains an unknown node reference."
			if engine.connect_nodes(from_id, to_id, str(action.edge_type)) == null:
				return "Connection %d -> %d was rejected." % [from_id, to_id]
		"set_inventory":
			var node_id := _resolve_node(action.get("node"))
			var node: Variant = engine.graph.get_node(node_id)
			if node == null:
				return "Unknown inventory node."
			var inventory: Variant = action.get("inventory", {})
			if typeof(inventory) != TYPE_DICTIONARY:
				return "Inventory must be an object."
			var converted := _numeric_map(inventory)
			if bool(action.get("merge", false)):
				node.inventory.merge(converted, true)
			else:
				node.inventory = converted
		"set_node_state":
			var node_id := _resolve_node(action.get("node"))
			var node: Variant = engine.graph.get_node(node_id)
			if node == null:
				return "Unknown state target node."
			var state_name := str(action.get("state", ""))
			if state_name not in ["UNDER_CONSTRUCTION", "READY", "RUNNING"]:
				return "Unknown node state '%s'." % state_name
			node.state = state_name
		"set_workers":
			engine.state.workers_current = float(action.amount)
		"step":
			var dt := float(action.dt)
			var count := int(action.get("count", 1))
			if dt < 0.0 or count < 0:
				return "Step dt and count must be non-negative."
			engine.step_many(dt, count)
		"round_trip_save":
			var previous_step_count: int = engine.step_count
			var previous_simulated_seconds: float = engine.simulated_seconds
			var data: Dictionary = engine.build_savegame_data()
			var result: Error = engine.load_from_dictionary(data)
			if result != OK:
				return "In-memory savegame round-trip failed: %s" % str(engine.savegames.errors)
			engine.step_count = previous_step_count
			engine.simulated_seconds = previous_simulated_seconds
			aliases.clear()
		"delete_node":
			var node_id := _resolve_node(action.get("node"))
			if engine.graph.get_node(node_id) == null:
				return "Unknown node to delete."
			engine.delete_node(node_id)
		"delete_edge":
			var edge_index := int(action.get("index", -1))
			if edge_index < 0 or edge_index >= engine.state.edges.size():
				return "Unknown edge index to delete."
			engine.delete_edge(edge_index)
		_:
			return "Unsupported parity operation '%s'." % operation
	return ""


func _build_snapshot(scenario_name: String) -> Dictionary:
	var node_ids: Array = engine.state.nodes.keys()
	node_ids.sort()
	var nodes: Array = []
	for node_id: Variant in node_ids:
		var node: Variant = engine.state.nodes[node_id]
		nodes.append(
			{
				"id": node.id,
				"entity_type": node.entity_type,
				"position": [_number(node.world_x), _number(node.world_y)],
				"state": node.state,
				"inventory": _numeric_map(node.inventory),
				"construction_progress": _numeric_map(node.construction_progress),
				"process": {
					"total_sec": _number(node.active_process_total_sec),
					"remaining_sec": _number(node.active_process_remaining_sec),
					"output_name": node.active_process_output_name,
				},
				"workers_assigned": _number(node.workers_assigned),
				"worker_efficiency": _number(node.worker_efficiency),
			}
		)

	var edges: Array = []
	for index in range(engine.state.edges.size()):
		var edge: Variant = engine.state.edges[index]
		var packet: Variant = null
		if edge.packet != null:
			packet = {
				"resource_name": edge.packet.resource_name,
				"amount": _number(edge.packet.amount),
				"progress": _number(edge.packet.progress),
			}
		edges.append(
			{
				"index": index,
				"from_id": edge.from_id,
				"to_id": edge.to_id,
				"edge_type_id": edge.edge_type_id,
				"packet": packet,
				"return_progress": (
					null if edge.return_progress == null else _number(edge.return_progress)
				),
			}
		)

	var unlock_states: Dictionary = engine.progression.get_all_unlock_states(engine.state)
	var unlock_ids: Array = unlock_states.keys()
	unlock_ids.sort()
	var sorted_unlocks: Dictionary = {}
	for entity_id: Variant in unlock_ids:
		sorted_unlocks[str(entity_id)] = unlock_states[entity_id]

	return {
		"snapshot_format_version": SNAPSHOT_FORMAT_VERSION,
		"scenario": scenario_name,
		"runner": "godot",
		"steps": engine.step_count,
		"simulated_seconds": _number(engine.simulated_seconds),
		"simulation": {
			"next_node_id": engine.state.next_node_id,
			"nodes": nodes,
			"edges": edges,
			"transport_inventory": _numeric_map(engine.state.transport_inventory),
			"settlement": {
				"workers_current": _number(engine.state.workers_current),
				"workers_max": _number(engine.state.workers_max),
				"food_available": _number(engine.state.food_available),
				"food_consumed_last_tick": _number(engine.state.food_consumed_last_tick),
				"food_support_ratio": _number(engine.state.food_support_ratio),
				"attractiveness": _number(engine.state.attractiveness),
				"worker_trend": engine.state.worker_trend,
			},
			"progression": {
				"reachable_resources": engine.progression.compute_reachable_resources(engine.state),
				"entity_unlocks": sorted_unlocks,
			},
		},
	}


func _numeric_map(values: Dictionary) -> Dictionary:
	var keys: Array = values.keys()
	keys.sort()
	var result: Dictionary = {}
	for key: Variant in keys:
		result[str(key)] = _number(float(values[key]))
	return result


func _number(value: float) -> float:
	var rounded: float = round(value * FLOAT_SCALE) / FLOAT_SCALE
	return 0.0 if rounded == 0.0 else rounded


func _resolve_node(value: Variant) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)
	return int(aliases.get(str(value), 0))


func _repository_path(value: String) -> String:
	if value.is_absolute_path():
		return value
	var project_root := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	return project_root.path_join(value).simplify_path()


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


func _parse_arguments(values: PackedStringArray) -> Dictionary:
	var result: Dictionary = {}
	var index := 0
	while index < values.size():
		var key := values[index]
		if key.begins_with("--") and index + 1 < values.size():
			result[key.trim_prefix("--")] = values[index + 1]
			index += 2
		else:
			index += 1
	return result


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
