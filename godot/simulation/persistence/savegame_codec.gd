class_name SimulationSavegameCodec
extends RefCounted

const NodeInstanceType = preload("res://simulation/state/node_instance.gd")
const EdgeInstanceType = preload("res://simulation/state/edge_instance.gd")
const PacketType = preload("res://simulation/state/transport_packet.gd")

const SAVEGAME_VERSION := 1

var errors: Array[String] = []


func build_savegame_data(engine: Variant) -> Dictionary:
	var nodes: Array = []
	for node: Variant in engine.state.nodes.values():
		nodes.append(_serialize_node(node))
	var edges: Array = []
	for edge: Variant in engine.state.edges:
		edges.append(_serialize_edge(edge))
	return {
		"version": SAVEGAME_VERSION,
		"nodes": nodes,
		"edges": edges,
		"state": _serialize_state(engine.state),
	}


func save_to_path(engine: Variant, path: String) -> Error:
	errors.clear()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error := FileAccess.get_open_error()
		errors.append("Unable to open save path '%s': error %d." % [path, open_error])
		return open_error
	file.store_string(JSON.stringify(build_savegame_data(engine), "\t", false))
	return OK


func load_from_path(engine: Variant, path: String) -> Error:
	errors.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var open_error := FileAccess.get_open_error()
		errors.append("Unable to open savegame '%s': error %d." % [path, open_error])
		return open_error
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		errors.append(
			"Invalid savegame JSON at line %d: %s"
			% [parser.get_error_line(), parser.get_error_message()]
		)
		return parse_error
	if typeof(parser.data) != TYPE_DICTIONARY:
		errors.append("Savegame root must be a JSON object.")
		return ERR_INVALID_DATA
	return load_from_dictionary(engine, parser.data)


func load_from_dictionary(engine: Variant, data: Dictionary) -> Error:
	errors.clear()
	var version := int(data.get("version", 0))
	if version != SAVEGAME_VERSION:
		errors.append("Unsupported savegame version: %d" % version)
		return ERR_FILE_UNRECOGNIZED
	if typeof(data.get("nodes", [])) != TYPE_ARRAY:
		errors.append("Savegame 'nodes' field must be an array.")
		return ERR_INVALID_DATA
	if typeof(data.get("edges", [])) != TYPE_ARRAY:
		errors.append("Savegame 'edges' field must be an array.")
		return ERR_INVALID_DATA
	if typeof(data.get("state", {})) != TYPE_DICTIONARY:
		errors.append("Savegame 'state' field must be an object.")
		return ERR_INVALID_DATA

	engine.state.nodes.clear()
	engine.state.edges.clear()
	engine.state.next_node_id = 1
	for node_data: Variant in data.get("nodes", []):
		if typeof(node_data) != TYPE_DICTIONARY:
			errors.append("Every savegame node must be an object.")
			return ERR_INVALID_DATA
		var node: Variant = _deserialize_node(node_data)
		if node == null:
			return ERR_INVALID_DATA
		engine.state.nodes[node.id] = node
		engine.state.next_node_id = maxi(engine.state.next_node_id, node.id + 1)

	for edge_data: Variant in data.get("edges", []):
		if typeof(edge_data) != TYPE_DICTIONARY:
			errors.append("Every savegame edge must be an object.")
			return ERR_INVALID_DATA
		var edge: Variant = _deserialize_edge(edge_data)
		if edge == null:
			return ERR_INVALID_DATA
		engine.state.edges.append(edge)

	_deserialize_state(engine.state, data.get("state", {}))
	engine.step_count = 0
	engine.simulated_seconds = 0.0
	return OK


func _serialize_node(node: Variant) -> Dictionary:
	return {
		"id": node.id,
		"entity_type": node.entity_type,
		"world_x": node.world_x,
		"world_y": node.world_y,
		"state": node.state,
		"inventory": node.inventory.duplicate(true),
		"construction_progress": node.construction_progress.duplicate(true),
		"active_process_total_sec": node.active_process_total_sec,
		"active_process_remaining_sec": node.active_process_remaining_sec,
		"active_process_output_name": node.active_process_output_name,
		"workers_assigned": node.workers_assigned,
		"worker_efficiency": node.worker_efficiency,
	}


func _deserialize_node(data: Dictionary) -> Variant:
	for required: String in ["id", "entity_type", "world_x", "world_y", "state"]:
		if not data.has(required):
			errors.append("Savegame node is missing required field '%s'." % required)
			return null
	var inventory: Variant = data.get("inventory", {})
	var construction_progress: Variant = data.get("construction_progress", {})
	if typeof(inventory) != TYPE_DICTIONARY or typeof(construction_progress) != TYPE_DICTIONARY:
		errors.append("Node inventory and construction progress must be objects.")
		return null
	var node := NodeInstanceType.new(
		int(data.id),
		str(data.entity_type),
		float(data.world_x),
		float(data.world_y)
	)
	node.state = str(data.state)
	node.inventory = _numeric_map(inventory)
	node.construction_progress = _numeric_map(construction_progress)
	node.active_process_total_sec = float(data.get("active_process_total_sec", 0.0))
	node.active_process_remaining_sec = float(data.get("active_process_remaining_sec", 0.0))
	node.active_process_output_name = data.get("active_process_output_name")
	node.workers_assigned = float(data.get("workers_assigned", 0.0))
	node.worker_efficiency = float(data.get("worker_efficiency", 1.0))
	return node


func _serialize_edge(edge: Variant) -> Dictionary:
	return {
		"from_id": edge.from_id,
		"to_id": edge.to_id,
		"edge_type_id": edge.edge_type_id,
		"packet": _serialize_packet(edge.packet),
		"return_progress": edge.return_progress,
	}


func _deserialize_edge(data: Dictionary) -> Variant:
	for required: String in ["from_id", "to_id", "edge_type_id"]:
		if not data.has(required):
			errors.append("Savegame edge is missing required field '%s'." % required)
			return null
	var edge := EdgeInstanceType.new(
		int(data.from_id),
		int(data.to_id),
		str(data.edge_type_id)
	)
	var packet_data: Variant = data.get("packet")
	if packet_data != null:
		if typeof(packet_data) != TYPE_DICTIONARY:
			errors.append("Edge packet must be an object or null.")
			return null
		edge.packet = _deserialize_packet(packet_data)
		if edge.packet == null:
			return null
	var return_value: Variant = data.get("return_progress")
	edge.return_progress = null if return_value == null else float(return_value)
	return edge


func _serialize_packet(packet: Variant) -> Variant:
	if packet == null:
		return null
	return {
		"resource_name": packet.resource_name,
		"amount": packet.amount,
		"progress": packet.progress,
	}


func _deserialize_packet(data: Dictionary) -> Variant:
	if not data.has("resource_name") or not data.has("amount"):
		errors.append("Transport packet is missing resource_name or amount.")
		return null
	return PacketType.new(
		str(data.resource_name),
		float(data.amount),
		float(data.get("progress", 0.0))
	)


func _serialize_state(state: Variant) -> Dictionary:
	return {
		"transport_inventory": state.transport_inventory.duplicate(true),
		"workers_current": state.workers_current,
		"workers_max": state.workers_max,
		"food_available": state.food_available,
		"food_consumed_last_tick": state.food_consumed_last_tick,
		"food_support_ratio": state.food_support_ratio,
		"attractiveness": state.attractiveness,
		"worker_trend": state.worker_trend,
	}


func _deserialize_state(state: Variant, data: Dictionary) -> void:
	var transport_inventory: Variant = data.get("transport_inventory", {})
	state.transport_inventory = (
		_numeric_map(transport_inventory)
		if typeof(transport_inventory) == TYPE_DICTIONARY
		else {}
	)
	state.workers_current = float(data.get("workers_current", 0.0))
	state.workers_max = float(data.get("workers_max", 0.0))
	state.food_available = float(data.get("food_available", 0.0))
	state.food_consumed_last_tick = float(data.get("food_consumed_last_tick", 0.0))
	state.food_support_ratio = float(data.get("food_support_ratio", 1.0))
	state.attractiveness = float(data.get("attractiveness", 0.0))
	state.worker_trend = str(data.get("worker_trend", "stable"))


func _numeric_map(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in data:
		result[str(key)] = float(data[key])
	return result
