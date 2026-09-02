class_name SimulationConstructionSystem
extends RefCounted

const NodeInstanceType = preload("res://simulation/state/node_instance.gd")
const InventorySystem = preload("res://simulation/systems/inventory_system.gd")

var registry: Variant


func _init(definition_registry: Variant) -> void:
	registry = definition_registry


func get_progress(node: Variant) -> float:
	var definition: Variant = registry.get_entity(node.entity_type)
	if definition == null or definition.construction_cost.is_empty():
		return 1.0
	var required_total := 0.0
	var delivered_total := 0.0
	for resource_name: Variant in definition.construction_cost:
		var required := float(definition.construction_cost[resource_name])
		required_total += required
		delivered_total += minf(
			float(node.construction_progress.get(resource_name, 0.0)),
			required
		)
	if required_total <= 0.0:
		return 1.0
	return clampf(delivered_total / required_total, 0.0, 1.0)


func get_receivable_amount(node: Variant, resource_name: String) -> float:
	if node.state != NodeInstanceType.STATE_UNDER_CONSTRUCTION:
		return 0.0
	var definition: Variant = registry.get_entity(node.entity_type)
	if definition == null:
		return 0.0
	var required := float(definition.construction_cost.get(resource_name, 0.0))
	var current := minf(
		float(node.construction_progress.get(resource_name, 0.0)),
		required
	)
	return maxf(0.0, required - current)


func deliver(node: Variant, resource_name: String, amount: float) -> float:
	var receivable := get_receivable_amount(node, resource_name)
	var delivered := minf(maxf(amount, 0.0), receivable)
	if delivered > 0.0:
		node.construction_progress[resource_name] = (
			float(node.construction_progress.get(resource_name, 0.0)) + delivered
		)
	return delivered


func is_finished(node: Variant) -> bool:
	if node.state != NodeInstanceType.STATE_UNDER_CONSTRUCTION:
		return false
	var definition: Variant = registry.get_entity(node.entity_type)
	if definition == null:
		return false
	for resource_name: Variant in definition.construction_cost:
		var delivered := float(node.construction_progress.get(resource_name, 0.0))
		if delivered + InventorySystem.EPSILON < float(definition.construction_cost[resource_name]):
			return false
	return true


func promote_if_finished(node: Variant) -> bool:
	if not is_finished(node):
		return false
	var definition: Variant = registry.get_entity(node.entity_type)
	node.state = NodeInstanceType.STATE_READY
	for resource_name: Variant in definition.initial_amounts:
		node.inventory[str(resource_name)] = float(definition.initial_amounts[resource_name])
	return true
