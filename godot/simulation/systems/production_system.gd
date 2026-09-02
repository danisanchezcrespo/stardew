class_name SimulationProductionSystem
extends RefCounted

const NodeInstanceType = preload("res://simulation/state/node_instance.gd")
const InventorySystem = preload("res://simulation/systems/inventory_system.gd")

var registry: Variant
var _transport_resource_ids: Dictionary = {}


func _init(definition_registry: Variant) -> void:
	registry = definition_registry
	for edge_type_id: String in registry.edge_type_order:
		var edge_definition: Variant = registry.get_edge_type(edge_type_id)
		if not edge_definition.transport_resource.is_empty():
			_transport_resource_ids[edge_definition.transport_resource] = true


func process_all(simulation_state: Variant, dt: float) -> void:
	for node: Variant in simulation_state.nodes.values():
		process_node(simulation_state, node, dt)


func process_node(simulation_state: Variant, node: Variant, dt: float) -> void:
	if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
		return
	var definition: Variant = registry.get_entity(node.entity_type)
	if definition == null:
		return
	if definition.recipe_outputs.is_empty():
		node.state = NodeInstanceType.STATE_READY
		return

	if is_source(definition):
		_process_source(simulation_state, node, definition, dt)
	else:
		_process_machine(simulation_state, node, definition, dt)


func is_source(definition: Variant) -> bool:
	return not definition.recipe_outputs.is_empty() and definition.recipe_inputs.is_empty()


func get_staffing_efficiency(node: Variant, definition: Variant) -> float:
	if definition.workers_required <= 0.0:
		return 1.0
	var efficiency := clampf(float(node.worker_efficiency), 0.0, 1.0)
	if definition.min_worker_efficiency > 0.0:
		efficiency = maxf(definition.min_worker_efficiency, efficiency)
	return efficiency


func has_output_capacity_for_batch(node: Variant, definition: Variant) -> bool:
	if definition.recipe_outputs.is_empty():
		return true
	for resource_name: Variant in definition.recipe_outputs:
		var resource_id := str(resource_name)
		if is_transport_resource(resource_id):
			continue
		var current := InventorySystem.get_amount(node.inventory, resource_id)
		var maximum := INF
		if definition.max_amounts.has(resource_id):
			maximum = float(definition.max_amounts[resource_id])
		if current + float(definition.recipe_outputs[resource_name]) > maximum + InventorySystem.EPSILON:
			return false
	return true


func is_transport_resource(resource_name: String) -> bool:
	return _transport_resource_ids.has(resource_name)


func _process_source(
	simulation_state: Variant,
	node: Variant,
	definition: Variant,
	dt: float
) -> void:
	var rate := float(definition.source_rate_per_sec)
	if rate <= 0.0:
		node.state = NodeInstanceType.STATE_READY
		return

	var has_capacity := false
	for resource_name: Variant in definition.recipe_outputs:
		var resource_id := str(resource_name)
		if is_transport_resource(resource_id):
			has_capacity = true
			break
		var current := InventorySystem.get_amount(node.inventory, resource_id)
		var maximum := INF
		if definition.max_amounts.has(resource_id):
			maximum = float(definition.max_amounts[resource_id])
		if current + InventorySystem.EPSILON < maximum:
			has_capacity = true
			break

	if not has_capacity:
		node.state = NodeInstanceType.STATE_READY
		return

	node.state = NodeInstanceType.STATE_RUNNING
	for resource_name: Variant in definition.recipe_outputs:
		_add_output(
			simulation_state,
			node,
			definition,
			str(resource_name),
			float(definition.recipe_outputs[resource_name]) * rate * dt
		)


func _process_machine(
	simulation_state: Variant,
	node: Variant,
	definition: Variant,
	dt: float
) -> void:
	var staffing_efficiency := get_staffing_efficiency(node, definition)
	if staffing_efficiency <= 0.0:
		node.state = NodeInstanceType.STATE_READY
		return
	if not has_output_capacity_for_batch(node, definition):
		node.state = NodeInstanceType.STATE_READY
		return

	if node.active_process_remaining_sec > 0.0:
		node.state = NodeInstanceType.STATE_RUNNING
		node.active_process_remaining_sec = maxf(
			0.0,
			node.active_process_remaining_sec - dt * staffing_efficiency
		)
		if node.active_process_remaining_sec <= 0.0:
			_finish_batch(simulation_state, node, definition)
		return

	if not InventorySystem.has_resources(node.inventory, definition.recipe_inputs):
		node.state = NodeInstanceType.STATE_READY
		return

	node.state = NodeInstanceType.STATE_RUNNING
	InventorySystem.consume_resources(node.inventory, definition.recipe_inputs)
	node.active_process_total_sec = maxf(0.0, float(definition.process_time_sec))
	node.active_process_remaining_sec = maxf(0.0, float(definition.process_time_sec))
	node.active_process_output_name = (
		str(definition.recipe_outputs.keys()[0])
		if not definition.recipe_outputs.is_empty()
		else null
	)
	if node.active_process_remaining_sec <= 0.0:
		_finish_batch(simulation_state, node, definition)


func _finish_batch(simulation_state: Variant, node: Variant, definition: Variant) -> void:
	for resource_name: Variant in definition.recipe_outputs:
		_add_output(
			simulation_state,
			node,
			definition,
			str(resource_name),
			float(definition.recipe_outputs[resource_name])
		)
	node.active_process_total_sec = 0.0
	node.active_process_remaining_sec = 0.0
	node.active_process_output_name = null


func _add_output(
	simulation_state: Variant,
	node: Variant,
	definition: Variant,
	resource_name: String,
	amount: float
) -> void:
	if is_transport_resource(resource_name):
		if amount <= 0.0:
			return
		var current := float(simulation_state.transport_inventory.get(resource_name, 0.0))
		simulation_state.transport_inventory[resource_name] = current + amount
		return
	InventorySystem.add_capped(node.inventory, definition.max_amounts, resource_name, amount)
