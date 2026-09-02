class_name SimulationDefinitionRegistry
extends RefCounted

const EntityDefinitionType = preload("res://simulation/definitions/entity_definition.gd")
const EdgeTypeDefinitionType = preload("res://simulation/definitions/edge_type_definition.gd")

var entities_by_id: Dictionary = {}
var entity_order: Array[String] = []
var edge_types_by_id: Dictionary = {}
var edge_type_order: Array[String] = []
var errors: Array[String] = []


func clear() -> void:
	entities_by_id.clear()
	entity_order.clear()
	edge_types_by_id.clear()
	edge_type_order.clear()
	errors.clear()


func load_from_path(path: String) -> Error:
	clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Unable to open definition file '%s': error %d." % [path, FileAccess.get_open_error()])
		return FileAccess.get_open_error()

	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		errors.append(
			"Invalid JSON in '%s' at line %d: %s"
			% [path, parser.get_error_line(), parser.get_error_message()]
		)
		return parse_error

	if typeof(parser.data) != TYPE_DICTIONARY:
		errors.append("Definition root must be a JSON object.")
		return ERR_INVALID_DATA

	return load_from_dictionary(parser.data)


func load_from_dictionary(data: Dictionary) -> Error:
	clear()
	var entities_value: Variant = data.get("entities", [])
	if typeof(entities_value) != TYPE_ARRAY:
		errors.append("The 'entities' field must be an array.")
		return ERR_INVALID_DATA

	var edges_value: Variant
	if data.has("edges"):
		edges_value = data["edges"]
	else:
		edges_value = data.get("edge_types", [])
	if typeof(edges_value) != TYPE_ARRAY:
		errors.append("The 'edges' field must be an array.")
		return ERR_INVALID_DATA

	for index in range(entities_value.size()):
		var item: Variant = entities_value[index]
		if typeof(item) != TYPE_DICTIONARY:
			errors.append("Entity at index %d must be an object." % index)
			return ERR_INVALID_DATA
		var result: Variant = _parse_entity(item, index)
		if result == null:
			return ERR_INVALID_DATA
		entities_by_id[result.entity_id] = result
		entity_order.append(result.entity_id)

	for index in range(edges_value.size()):
		var item: Variant = edges_value[index]
		if typeof(item) != TYPE_DICTIONARY:
			errors.append("Edge type at index %d must be an object." % index)
			return ERR_INVALID_DATA
		var result: Variant = _parse_edge_type(item, index)
		if result == null:
			return ERR_INVALID_DATA
		edge_types_by_id[result.edge_type_id] = result
		edge_type_order.append(result.edge_type_id)

	return OK


func get_entity(entity_id: String) -> Variant:
	return entities_by_id.get(entity_id)


func get_edge_type(edge_type_id: String) -> Variant:
	return edge_types_by_id.get(edge_type_id)


func get_default_edge_type_id() -> String:
	return edge_type_order[0] if not edge_type_order.is_empty() else ""


func _parse_entity(item: Dictionary, index: int) -> Variant:
	if not item.has("id"):
		errors.append("Entity at index %d is missing required field 'id'." % index)
		return null

	var definition := EntityDefinitionType.new()
	definition.entity_id = str(item["id"])
	definition.label = str(item.get("label", definition.entity_id))
	definition.color = str(item.get("color", "#888888"))

	definition.construction_cost = _numeric_map(item.get("construction_cost", {}), definition.entity_id, "construction_cost")
	definition.initial_amounts = _numeric_map(item.get("initial_amounts", {}), definition.entity_id, "initial_amounts")
	definition.max_amounts = _numeric_map(item.get("max_amounts", {}), definition.entity_id, "max_amounts")
	definition.recipe_inputs = _numeric_map(item.get("recipe_inputs", {}), definition.entity_id, "recipe_inputs")
	definition.recipe_outputs = _numeric_map(item.get("recipe_outputs", {}), definition.entity_id, "recipe_outputs")
	definition.shared_resource_modifiers = _numeric_map(
		item.get("shared_resource_modifiers", {}),
		definition.entity_id,
		"shared_resource_modifiers"
	)
	if not errors.is_empty():
		return null

	definition.source_rate_per_sec = float(item.get("source_rate_per_sec", 0.0))
	definition.process_time_sec = float(item.get("process_time_sec", 0.0))
	definition.workers_required = float(item.get("workers_required", 0.0))
	definition.worker_priority = int(item.get("worker_priority", 0))
	definition.min_worker_efficiency = float(item.get("min_worker_efficiency", 0.0))
	return definition


func _parse_edge_type(item: Dictionary, index: int) -> Variant:
	if not item.has("id"):
		errors.append("Edge type at index %d is missing required field 'id'." % index)
		return null

	var definition := EdgeTypeDefinitionType.new()
	definition.edge_type_id = str(item["id"])
	definition.label = str(item.get("label", definition.edge_type_id))
	definition.color = str(item.get("color", "#FFD966"))
	definition.speed = float(item.get("speed", 50.0))
	definition.capacity_per_trip = float(item.get("capacity_per_trip", 10.0))
	definition.mode = str(item.get("mode", "one_way"))
	definition.transport_resource = str(item.get("transport_resource", ""))
	definition.units_per_edge = float(item.get("units_per_edge", 1.0))
	definition.initial_pool_units = float(item.get("initial_pool_units", 0.0))

	if definition.mode != "one_way" and definition.mode != "ping_pong":
		errors.append(
			"Invalid mode '%s' for edge type '%s'."
			% [definition.mode, definition.edge_type_id]
		)
		return null
	if definition.units_per_edge <= 0.0:
		errors.append("units_per_edge must be positive for edge type '%s'." % definition.edge_type_id)
		return null
	return definition


func _numeric_map(value: Variant, owner_id: String, field_name: String) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("Field '%s' on '%s' must be an object." % [field_name, owner_id])
		return {}
	var converted: Dictionary = {}
	for key: Variant in value:
		var number: Variant = value[key]
		if typeof(number) != TYPE_INT and typeof(number) != TYPE_FLOAT:
			errors.append(
				"Value '%s.%s.%s' must be numeric." % [owner_id, field_name, str(key)]
			)
			return {}
		converted[str(key)] = float(number)
	return converted
