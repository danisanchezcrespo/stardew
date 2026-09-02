class_name SimulationGraph
extends RefCounted

const NodeInstanceType = preload("res://simulation/state/node_instance.gd")
const EdgeInstanceType = preload("res://simulation/state/edge_instance.gd")

var registry: Variant
var simulation_state: Variant


func _init(definition_registry: Variant, state: Variant) -> void:
	registry = definition_registry
	simulation_state = state


func create_node(entity_type: String, world_x: float, world_y: float) -> Variant:
	var entity_definition: Variant = registry.get_entity(entity_type)
	if entity_definition == null:
		return null

	var node := NodeInstanceType.new(
		simulation_state.next_node_id,
		entity_type,
		world_x,
		world_y
	)
	var has_construction_cost: bool = not entity_definition.construction_cost.is_empty()
	var is_source: bool = (
		not entity_definition.recipe_outputs.is_empty()
		and entity_definition.recipe_inputs.is_empty()
	)

	if has_construction_cost:
		node.state = NodeInstanceType.STATE_UNDER_CONSTRUCTION
		for resource_name: Variant in entity_definition.construction_cost:
			node.construction_progress[str(resource_name)] = 0.0
	else:
		node.state = NodeInstanceType.STATE_RUNNING if is_source else NodeInstanceType.STATE_READY
		node.inventory = entity_definition.initial_amounts.duplicate(true)

	simulation_state.nodes[node.id] = node
	simulation_state.next_node_id += 1
	return node


func get_node(node_id: int) -> Variant:
	return simulation_state.nodes.get(node_id)


func create_edge(from_id: int, to_id: int, edge_type_id: String) -> Variant:
	if from_id == to_id:
		return null
	if get_node(from_id) == null or get_node(to_id) == null:
		return null
	if registry.get_edge_type(edge_type_id) == null:
		return null
	for existing: Variant in simulation_state.edges:
		if existing.from_id == from_id and existing.to_id == to_id:
			return null
	var edge := EdgeInstanceType.new(from_id, to_id, edge_type_id)
	simulation_state.edges.append(edge)
	return edge


func remove_edge_by_index(edge_index: int) -> void:
	if edge_index >= 0 and edge_index < simulation_state.edges.size():
		simulation_state.edges.remove_at(edge_index)


func remove_node(node_id: int) -> void:
	if not simulation_state.nodes.has(node_id):
		return
	simulation_state.nodes.erase(node_id)
	for index in range(simulation_state.edges.size() - 1, -1, -1):
		var edge: Variant = simulation_state.edges[index]
		if edge.from_id == node_id or edge.to_id == node_id:
			simulation_state.edges.remove_at(index)
