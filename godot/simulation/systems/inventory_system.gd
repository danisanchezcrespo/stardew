class_name SimulationInventorySystem
extends RefCounted

const EPSILON := 0.0001


static func get_amount(inventory: Dictionary, resource_name: String) -> float:
	return float(inventory.get(resource_name, 0.0))


static func get_receivable_amount(
	inventory: Dictionary,
	maximum_amounts: Dictionary,
	resource_name: String
) -> float:
	var current := get_amount(inventory, resource_name)
	if not maximum_amounts.has(resource_name):
		return INF
	return maxf(0.0, float(maximum_amounts[resource_name]) - current)


static func add_capped(
	inventory: Dictionary,
	maximum_amounts: Dictionary,
	resource_name: String,
	amount: float
) -> float:
	if amount <= 0.0:
		return 0.0
	var current := get_amount(inventory, resource_name)
	var accepted := amount
	if maximum_amounts.has(resource_name):
		accepted = minf(amount, maxf(0.0, float(maximum_amounts[resource_name]) - current))
	inventory[resource_name] = current + accepted
	return accepted


static func has_resources(inventory: Dictionary, costs: Dictionary) -> bool:
	for resource_name: Variant in costs:
		if get_amount(inventory, str(resource_name)) + EPSILON < float(costs[resource_name]):
			return false
	return true


static func consume(inventory: Dictionary, resource_name: String, amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var available := get_amount(inventory, resource_name)
	var consumed := minf(available, amount)
	var remainder := available - consumed
	inventory[resource_name] = 0.0 if remainder < EPSILON else remainder
	return consumed


static func consume_resources(inventory: Dictionary, costs: Dictionary) -> bool:
	if not has_resources(inventory, costs):
		return false
	for resource_name: Variant in costs:
		consume(inventory, str(resource_name), float(costs[resource_name]))
	return true
