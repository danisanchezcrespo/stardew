class_name SimulationProgressionSystem
extends RefCounted

var registry: Variant


func _init(definition_registry: Variant) -> void:
	registry = definition_registry


func get_required_resources(entity_type: String) -> Dictionary:
	var definition: Variant = registry.get_entity(entity_type)
	var required: Dictionary = {}
	if definition == null:
		return required
	for resource_name: Variant in definition.construction_cost:
		required[str(resource_name)] = true
	for resource_name: Variant in definition.recipe_inputs:
		required[str(resource_name)] = true
	return required


func get_output_resources(entity_type: String) -> Dictionary:
	var definition: Variant = registry.get_entity(entity_type)
	var outputs: Dictionary = {}
	if definition == null:
		return outputs
	for resource_name: Variant in definition.recipe_outputs:
		outputs[str(resource_name)] = true
	return outputs


func compute_reachable_resources(simulation_state: Variant) -> Array[String]:
	var placed_entity_types: Array[String] = []
	for node: Variant in simulation_state.nodes.values():
		placed_entity_types.append(node.entity_type)

	var reachable: Dictionary = {}
	var changed := true
	while changed:
		changed = false
		for entity_type: String in placed_entity_types:
			var required := get_required_resources(entity_type)
			if not _is_subset(required, reachable):
				continue
			for resource_name: String in get_output_resources(entity_type):
				if not reachable.has(resource_name):
					reachable[resource_name] = true
					changed = true

	var result: Array[String] = []
	for resource_name: Variant in reachable:
		result.append(str(resource_name))
	result.sort()
	return result


func is_entity_unlocked(simulation_state: Variant, entity_type: String) -> bool:
	var reachable := _string_array_as_set(compute_reachable_resources(simulation_state))
	return _is_subset(get_required_resources(entity_type), reachable)


func get_missing_requirements(
	simulation_state: Variant,
	entity_type: String
) -> Array[String]:
	var reachable := _string_array_as_set(compute_reachable_resources(simulation_state))
	var missing: Array[String] = []
	for resource_name: Variant in get_required_resources(entity_type):
		var resource_id := str(resource_name)
		if not reachable.has(resource_id):
			missing.append(resource_id)
	missing.sort()
	return missing


func get_all_unlock_states(simulation_state: Variant) -> Dictionary:
	var reachable := _string_array_as_set(compute_reachable_resources(simulation_state))
	var result: Dictionary = {}
	for entity_type: String in registry.entity_order:
		var missing: Array[String] = []
		for resource_name: Variant in get_required_resources(entity_type):
			var resource_id := str(resource_name)
			if not reachable.has(resource_id):
				missing.append(resource_id)
		missing.sort()
		result[entity_type] = {
			"unlocked": missing.is_empty(),
			"missing": missing,
		}
	return result


func _is_subset(required: Dictionary, available: Dictionary) -> bool:
	for resource_name: Variant in required:
		if not available.has(str(resource_name)):
			return false
	return true


func _string_array_as_set(values: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for value: String in values:
		result[value] = true
	return result
