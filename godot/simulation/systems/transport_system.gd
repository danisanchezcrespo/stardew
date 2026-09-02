class_name SimulationTransportSystem
extends RefCounted

const NodeInstanceType = preload("res://simulation/state/node_instance.gd")
const PacketType = preload("res://simulation/state/transport_packet.gd")
const InventorySystem = preload("res://simulation/systems/inventory_system.gd")

var registry: Variant
var graph: Variant
var construction_system: Variant
var production_system: Variant


func _init(
	definition_registry: Variant,
	simulation_graph: Variant,
	construction: Variant,
	production: Variant = null
) -> void:
	registry = definition_registry
	graph = simulation_graph
	construction_system = construction
	production_system = production


func get_available_units(simulation_state: Variant, edge_type_id: String) -> int:
	var definition: Variant = registry.get_edge_type(edge_type_id)
	if definition == null:
		return 0
	if definition.transport_resource.is_empty():
		return 999999
	var current := float(
		simulation_state.transport_inventory.get(definition.transport_resource, 0.0)
	)
	return int(floor(current / definition.units_per_edge))


func spend_for_edge(simulation_state: Variant, edge_type_id: String) -> bool:
	var definition: Variant = registry.get_edge_type(edge_type_id)
	if definition == null:
		return false
	if definition.transport_resource.is_empty():
		return true
	var available := float(
		simulation_state.transport_inventory.get(definition.transport_resource, 0.0)
	)
	if available + InventorySystem.EPSILON < definition.units_per_edge:
		return false
	simulation_state.transport_inventory[definition.transport_resource] = maxf(
		0.0,
		available - definition.units_per_edge
	)
	return true


func refund_edge(simulation_state: Variant, edge: Variant) -> void:
	var definition: Variant = registry.get_edge_type(edge.edge_type_id)
	if definition == null or definition.transport_resource.is_empty():
		return
	var current := float(
		simulation_state.transport_inventory.get(definition.transport_resource, 0.0)
	)
	simulation_state.transport_inventory[definition.transport_resource] = (
		current + definition.units_per_edge
	)


func get_output_resources(node: Variant) -> Array[String]:
	var outputs: Array[String] = []
	if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
		return outputs
	var definition: Variant = registry.get_entity(node.entity_type)
	if definition == null:
		return outputs
	for resource_name: Variant in definition.recipe_outputs:
		var resource_id := str(resource_name)
		if not _is_transport_resource(resource_id):
			outputs.append(resource_id)
	return outputs


func get_acceptable_target_resources(node: Variant) -> Array[String]:
	var accepted: Array[String] = []
	var definition: Variant = registry.get_entity(node.entity_type)
	if definition == null:
		return accepted
	if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
		for resource_name: Variant in definition.construction_cost:
			var resource_id := str(resource_name)
			if construction_system.get_receivable_amount(node, resource_id) > 0.0:
				accepted.append(resource_id)
		return accepted
	for resource_name: Variant in definition.recipe_inputs:
		accepted.append(str(resource_name))
	return accepted


func can_connect_nodes(from_id: int, to_id: int) -> bool:
	var from_node: Variant = graph.get_node(from_id)
	var to_node: Variant = graph.get_node(to_id)
	if from_node == null or to_node == null:
		return false
	var acceptable := get_acceptable_target_resources(to_node)
	for resource_name: String in get_output_resources(from_node):
		if acceptable.has(resource_name):
			return true
	return false


func connect_nodes(
	simulation_state: Variant,
	from_id: int,
	to_id: int,
	edge_type_id: String
) -> Variant:
	if from_id == to_id or not can_connect_nodes(from_id, to_id):
		return null
	if get_available_units(simulation_state, edge_type_id) <= 0:
		return null
	var edge: Variant = graph.create_edge(from_id, to_id, edge_type_id)
	if edge == null:
		return null
	if not spend_for_edge(simulation_state, edge_type_id):
		graph.remove_edge_by_index(simulation_state.edges.size() - 1)
		return null
	return edge


func delete_edge(simulation_state: Variant, edge_index: int) -> void:
	if edge_index < 0 or edge_index >= simulation_state.edges.size():
		return
	refund_edge(simulation_state, simulation_state.edges[edge_index])
	graph.remove_edge_by_index(edge_index)


func delete_node(simulation_state: Variant, node_id: int) -> void:
	for index in range(simulation_state.edges.size() - 1, -1, -1):
		var edge: Variant = simulation_state.edges[index]
		if edge.from_id == node_id or edge.to_id == node_id:
			refund_edge(simulation_state, edge)
	graph.remove_node(node_id)


func advance_transporters(simulation_state: Variant, dt: float) -> void:
	for edge: Variant in simulation_state.edges:
		var from_node: Variant = graph.get_node(edge.from_id)
		var to_node: Variant = graph.get_node(edge.to_id)
		if from_node == null or to_node == null:
			continue
		var edge_definition: Variant = registry.get_edge_type(edge.edge_type_id)
		if edge_definition == null:
			continue
		var progress_per_sec: float = edge_definition.speed / _edge_distance(edge)
		if edge.packet != null:
			edge.packet.progress += dt * progress_per_sec
			if edge.packet.progress >= 1.0:
				_deliver_packet(
					simulation_state,
					to_node,
					edge.packet.resource_name,
					edge.packet.amount
				)
				edge.packet = null
				if edge_definition.mode == "ping_pong":
					edge.return_progress = 0.0
		elif edge.return_progress != null:
			edge.return_progress += dt * progress_per_sec
			if edge.return_progress >= 1.0:
				edge.return_progress = null


func launch_packets(simulation_state: Variant) -> void:
	for edge: Variant in simulation_state.edges:
		if _edge_is_busy(edge):
			continue
		var from_node: Variant = graph.get_node(edge.from_id)
		var to_node: Variant = graph.get_node(edge.to_id)
		if from_node == null or to_node == null:
			continue
		var edge_definition: Variant = registry.get_edge_type(edge.edge_type_id)
		if edge_definition == null:
			continue
		for resource_name: String in get_acceptable_target_resources(to_node):
			var available := InventorySystem.get_amount(from_node.inventory, resource_name)
			if available <= 0.0:
				continue
			var receivable := _get_receivable_with_reservations(
				simulation_state,
				to_node,
				resource_name
			)
			if receivable <= 0.0:
				continue
			var moved := minf(available, minf(receivable, edge_definition.capacity_per_trip))
			if moved <= 0.0:
				continue
			InventorySystem.consume(from_node.inventory, resource_name, moved)
			edge.packet = PacketType.new(resource_name, moved, 0.0)
			break


func promote_finished_construction(simulation_state: Variant) -> void:
	for node: Variant in simulation_state.nodes.values():
		if not construction_system.promote_if_finished(node):
			continue
		for index in range(simulation_state.edges.size() - 1, -1, -1):
			var edge: Variant = simulation_state.edges[index]
			if edge.to_id == node.id and edge.packet == null:
				refund_edge(simulation_state, edge)
				graph.remove_edge_by_index(index)


func release_satisfied_construction_edges(simulation_state: Variant, node: Variant) -> void:
	if node.state != NodeInstanceType.STATE_UNDER_CONSTRUCTION:
		return
	var acceptable := get_acceptable_target_resources(node)
	for index in range(simulation_state.edges.size() - 1, -1, -1):
		var edge: Variant = simulation_state.edges[index]
		if edge.to_id != node.id or edge.packet != null:
			continue
		var from_node: Variant = graph.get_node(edge.from_id)
		if from_node == null:
			continue
		var useful := false
		for resource_name: String in get_output_resources(from_node):
			if acceptable.has(resource_name):
				useful = true
				break
		if not useful:
			refund_edge(simulation_state, edge)
			graph.remove_edge_by_index(index)


func release_blocked_production_edges(simulation_state: Variant, node: Variant) -> void:
	if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION or production_system == null:
		return
	var definition: Variant = registry.get_entity(node.entity_type)
	if definition == null or definition.recipe_inputs.is_empty():
		return
	if production_system.has_output_capacity_for_batch(node, definition):
		return
	for index in range(simulation_state.edges.size() - 1, -1, -1):
		var edge: Variant = simulation_state.edges[index]
		if edge.to_id != node.id or edge.packet != null:
			continue
		var from_node: Variant = graph.get_node(edge.from_id)
		if from_node == null:
			continue
		var source_outputs := get_output_resources(from_node)
		var matched_full_input := false
		for resource_name: Variant in definition.recipe_inputs:
			var resource_id := str(resource_name)
			if not source_outputs.has(resource_id):
				continue
			var current := InventorySystem.get_amount(node.inventory, resource_id)
			var maximum := INF
			if definition.max_amounts.has(resource_id):
				maximum = float(definition.max_amounts[resource_id])
			if current + InventorySystem.EPSILON >= maximum:
				matched_full_input = true
				break
		if matched_full_input:
			refund_edge(simulation_state, edge)
			graph.remove_edge_by_index(index)


func _deliver_packet(
	simulation_state: Variant,
	to_node: Variant,
	resource_name: String,
	amount: float
) -> void:
	if to_node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
		construction_system.deliver(to_node, resource_name, amount)
		release_satisfied_construction_edges(simulation_state, to_node)
		return
	var definition: Variant = registry.get_entity(to_node.entity_type)
	if definition != null:
		InventorySystem.add_capped(
			to_node.inventory,
			definition.max_amounts,
			resource_name,
			amount
		)


func _get_receivable_with_reservations(
	simulation_state: Variant,
	to_node: Variant,
	resource_name: String
) -> float:
	var base := _get_receivable_amount(to_node, resource_name)
	var reserved := 0.0
	for edge: Variant in simulation_state.edges:
		if (
			edge.to_id == to_node.id
			and edge.packet != null
			and edge.packet.resource_name == resource_name
		):
			reserved += edge.packet.amount
	return maxf(0.0, base - reserved)


func _get_receivable_amount(node: Variant, resource_name: String) -> float:
	if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
		return construction_system.get_receivable_amount(node, resource_name)
	var definition: Variant = registry.get_entity(node.entity_type)
	if definition == null:
		return 0.0
	return InventorySystem.get_receivable_amount(
		node.inventory,
		definition.max_amounts,
		resource_name
	)


func _edge_distance(edge: Variant) -> float:
	var from_node: Variant = graph.get_node(edge.from_id)
	var to_node: Variant = graph.get_node(edge.to_id)
	if from_node == null or to_node == null:
		return 1.0
	return maxf(
		1.0,
		Vector2(to_node.world_x - from_node.world_x, to_node.world_y - from_node.world_y).length()
	)


func _edge_is_busy(edge: Variant) -> bool:
	return edge.packet != null or edge.return_progress != null


func _is_transport_resource(resource_name: String) -> bool:
	if production_system != null:
		return production_system.is_transport_resource(resource_name)
	for edge_type_id: String in registry.edge_type_order:
		var definition: Variant = registry.get_edge_type(edge_type_id)
		if definition.transport_resource == resource_name:
			return true
	return false
