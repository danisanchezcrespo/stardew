class_name SimulationState
extends RefCounted

var nodes: Dictionary = {}
var edges: Array = []
var next_node_id: int = 1

var transport_inventory: Dictionary = {}
var workers_current: float = 0.0
var workers_max: float = 0.0
var food_available: float = 0.0
var food_consumed_last_tick: float = 0.0
var food_support_ratio: float = 1.0
var attractiveness: float = 0.0
var worker_trend: String = "stable"


func initialize_transport_inventory(registry: Variant) -> void:
	transport_inventory.clear()
	for edge_type_id: String in registry.edge_type_order:
		var edge_definition: Variant = registry.get_edge_type(edge_type_id)
		if edge_definition.transport_resource.is_empty():
			continue
		var current := float(transport_inventory.get(edge_definition.transport_resource, 0.0))
		transport_inventory[edge_definition.transport_resource] = current + edge_definition.initial_pool_units
