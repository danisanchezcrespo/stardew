class_name SimulationWorkforceSystem
extends RefCounted

const NodeInstanceType = preload("res://simulation/state/node_instance.gd")
const InventorySystem = preload("res://simulation/systems/inventory_system.gd")

const FOOD_RESOURCE := "food"
const FOOD_PER_WORKER_PER_SEC := 0.05
const WORKER_GROWTH_RATE_PER_SEC := 0.12
const WORKER_DECLINE_RATE_PER_SEC := 0.18
const ATTRACTIVENESS_GROWTH_BONUS_PER_POINT := 0.05
const ATTRACTIVENESS_DECLINE_REDUCTION_PER_POINT := 0.04
const MIN_DECLINE_MULTIPLIER := 0.15

var registry: Variant


func _init(definition_registry: Variant) -> void:
	registry = definition_registry


func process(simulation_state: Variant, dt: float) -> void:
	rebuild_shared_city_stats(simulation_state)
	consume_food_and_update_workers(simulation_state, dt)
	assign_workers_to_nodes(simulation_state)


func rebuild_shared_city_stats(simulation_state: Variant) -> void:
	var workers_max := 0.0
	var attractiveness := 0.0
	for node: Variant in simulation_state.nodes.values():
		if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
			continue
		var definition: Variant = registry.get_entity(node.entity_type)
		if definition == null:
			continue
		workers_max += float(definition.shared_resource_modifiers.get("workers_max", 0.0))
		attractiveness += float(definition.shared_resource_modifiers.get("attractiveness", 0.0))

	simulation_state.workers_max = workers_max
	simulation_state.attractiveness = attractiveness
	simulation_state.workers_current = clampf(
		float(simulation_state.workers_current),
		0.0,
		workers_max
	)


func get_total_resource(simulation_state: Variant, resource_name: String) -> float:
	var total := 0.0
	for node: Variant in simulation_state.nodes.values():
		if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
			continue
		total += InventorySystem.get_amount(node.inventory, resource_name)
	return total


func consume_global_resource(
	simulation_state: Variant,
	resource_name: String,
	amount: float
) -> float:
	if amount <= 0.0:
		return 0.0
	var remaining := amount
	var consumed := 0.0
	for node: Variant in simulation_state.nodes.values():
		if remaining <= 0.0:
			break
		if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
			continue
		if InventorySystem.get_amount(node.inventory, resource_name) <= 0.0:
			continue
		var taken := InventorySystem.consume(node.inventory, resource_name, remaining)
		consumed += taken
		remaining -= taken
	return consumed


func consume_food_and_update_workers(simulation_state: Variant, dt: float) -> void:
	simulation_state.food_available = get_total_resource(simulation_state, FOOD_RESOURCE)
	var food_needed := float(simulation_state.workers_current) * FOOD_PER_WORKER_PER_SEC * dt
	var food_consumed := consume_global_resource(
		simulation_state,
		FOOD_RESOURCE,
		food_needed
	)
	simulation_state.food_consumed_last_tick = food_consumed

	var support_ratio := 1.0
	if food_needed > 0.000001:
		support_ratio = clampf(food_consumed / food_needed, 0.0, 1.0)
	simulation_state.food_support_ratio = support_ratio

	if simulation_state.workers_max <= 0.0:
		simulation_state.workers_current = 0.0
		simulation_state.worker_trend = "stable"
		return

	var current := float(simulation_state.workers_current)
	var maximum := float(simulation_state.workers_max)
	var attractiveness := float(simulation_state.attractiveness)
	var new_workers := current

	var growth_multiplier := (
		1.0 + attractiveness * ATTRACTIVENESS_GROWTH_BONUS_PER_POINT
	)
	var decline_multiplier := maxf(
		MIN_DECLINE_MULTIPLIER,
		1.0 - attractiveness * ATTRACTIVENESS_DECLINE_REDUCTION_PER_POINT
	)

	if support_ratio >= 0.9999:
		var room := maxf(0.0, maximum - current)
		var growth := WORKER_GROWTH_RATE_PER_SEC * growth_multiplier * room * dt
		new_workers = minf(maximum, current + growth)
		simulation_state.worker_trend = (
			"growing" if new_workers > current + InventorySystem.EPSILON else "stable"
		)
	else:
		var shortage := 1.0 - support_ratio
		var decline := (
			WORKER_DECLINE_RATE_PER_SEC
			* decline_multiplier
			* shortage
			* current
			* dt
		)
		new_workers = maxf(0.0, current - decline)
		simulation_state.worker_trend = (
			"shrinking" if new_workers + InventorySystem.EPSILON < current else "stable"
		)

	simulation_state.workers_current = clampf(new_workers, 0.0, maximum)


func assign_workers_to_nodes(simulation_state: Variant) -> void:
	var candidates: Array = []
	for node: Variant in simulation_state.nodes.values():
		node.workers_assigned = 0.0
		node.worker_efficiency = 1.0
		if node.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION:
			node.worker_efficiency = 0.0
			continue
		var definition: Variant = registry.get_entity(node.entity_type)
		if definition != null and definition.workers_required > 0.0:
			candidates.append(
				{
					"priority": definition.worker_priority,
					"node_id": node.id,
					"node": node,
					"definition": definition,
				}
			)

	candidates.sort_custom(_worker_candidate_precedes)
	var remaining_workers := float(simulation_state.workers_current)
	for candidate: Dictionary in candidates:
		var node: Variant = candidate.node
		var definition: Variant = candidate.definition
		var required := float(definition.workers_required)
		var assigned := minf(required, remaining_workers)
		node.workers_assigned = assigned
		node.worker_efficiency = clampf(assigned / required, 0.0, 1.0)
		remaining_workers -= assigned


static func _worker_candidate_precedes(left: Dictionary, right: Dictionary) -> bool:
	if left.priority != right.priority:
		return left.priority > right.priority
	return left.node_id < right.node_id
