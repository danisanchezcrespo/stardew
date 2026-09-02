extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const StateType = preload("res://simulation/state/simulation_state.gd")
const GraphType = preload("res://simulation/systems/simulation_graph.gd")
const WorkforceSystemType = preload("res://simulation/systems/workforce_system.gd")
const NodeInstanceType = preload("res://simulation/state/node_instance.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var registry := RegistryType.new()
	var result: Error = registry.load_from_path("res://scenarios/ancient_egypt/entities.json")
	_expect(result == OK, "Ancient Egypt definitions must load.", failures)

	_test_shared_stats_and_food_growth(registry, failures)
	_test_growth_from_zero(registry, failures)
	_test_food_shortage_decline(registry, failures)
	_test_attractiveness_modifiers(registry, failures)
	_test_global_consumption_order(registry, failures)
	_test_worker_priority_and_tie_break(registry, failures)

	if failures.is_empty():
		print("PASS: workforce system")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_shared_stats_and_food_growth(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	_ready_node(context, "WORKERS_HUTS")
	var kitchen: Variant = _ready_node(context, "KITCHEN")
	kitchen.inventory = {"food": 100.0}
	context.state.workers_current = 10.0
	context.workforce.process(context.state, 1.0)
	_expect(context.state.workers_max == 20.0, "Completed huts should provide capacity for 20 workers.", failures)
	_expect(context.state.food_available == 100.0, "food_available should capture pre-consumption stock.", failures)
	_expect(context.state.food_consumed_last_tick == 0.5, "Ten workers should consume 0.5 food per second.", failures)
	_expect(is_equal_approx(context.state.workers_current, 11.2), "Supported population should grow toward capacity.", failures)
	_expect(context.state.worker_trend == "growing", "Supported population should report growing.", failures)


func _test_growth_from_zero(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	_ready_node(context, "WORKERS_HUTS")
	context.state.workers_current = 0.0
	context.workforce.process(context.state, 1.0)
	_expect(is_equal_approx(context.state.workers_current, 2.4), "Legacy population should grow from zero without first-tick food.", failures)
	_expect(context.state.food_support_ratio == 1.0, "Zero population should have full food support.", failures)


func _test_food_shortage_decline(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	_ready_node(context, "WORKERS_HUTS")
	context.state.workers_current = 10.0
	context.workforce.process(context.state, 1.0)
	_expect(is_equal_approx(context.state.workers_current, 8.2), "Unsupported population should decline by the legacy formula.", failures)
	_expect(context.state.food_support_ratio == 0.0, "No food should produce zero support.", failures)
	_expect(context.state.worker_trend == "shrinking", "Starving population should report shrinking.", failures)


func _test_attractiveness_modifiers(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	_ready_node(context, "WORKERS_HUTS")
	_ready_node(context, "TEMPLE_COMPLEX")
	var kitchen: Variant = _ready_node(context, "KITCHEN")
	kitchen.inventory = {"food": 100.0}
	context.state.workers_current = 10.0
	context.workforce.process(context.state, 1.0)
	_expect(context.state.attractiveness == 10.0, "Completed temple should contribute 10 attractiveness.", failures)
	_expect(is_equal_approx(context.state.workers_current, 11.8), "Attractiveness should multiply growth speed.", failures)

	context.state.workers_current = 10.0
	kitchen.inventory.food = 0.0
	context.workforce.process(context.state, 1.0)
	_expect(is_equal_approx(context.state.workers_current, 8.92), "Attractiveness should reduce decline speed.", failures)


func _test_global_consumption_order(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var first: Variant = _ready_node(context, "KITCHEN")
	var second: Variant = _ready_node(context, "KITCHEN")
	var unfinished: Variant = context.graph.create_node("KITCHEN", 0.0, 0.0)
	first.inventory = {"food": 0.3}
	second.inventory = {"food": 1.0}
	unfinished.inventory = {"food": 50.0}
	var consumed: float = context.workforce.consume_global_resource(context.state, "food", 0.5)
	_expect(is_equal_approx(consumed, 0.5), "Global consumption should return consumed amount.", failures)
	_expect(first.inventory.food == 0.0, "First-created completed node should be drained first.", failures)
	_expect(is_equal_approx(second.inventory.food, 0.8), "Second node should provide the remainder.", failures)
	_expect(unfinished.inventory.food == 50.0, "Construction inventory should be ignored globally.", failures)


func _test_worker_priority_and_tie_break(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var kitchen: Variant = _ready_node(context, "KITCHEN")
	var first_kiln: Variant = _ready_node(context, "BRICK_KILN")
	var second_kiln: Variant = _ready_node(context, "BRICK_KILN")
	var farm: Variant = _ready_node(context, "GRAIN_FARM")
	var unfinished: Variant = context.graph.create_node("BAKERY", 0.0, 0.0)
	context.state.workers_current = 5.0
	context.workforce.assign_workers_to_nodes(context.state)

	_expect(kitchen.workers_assigned == 2.0, "Priority 95 kitchen should be staffed first.", failures)
	_expect(first_kiln.workers_assigned == 2.0, "First priority-90 kiln should win ID tie-break.", failures)
	_expect(second_kiln.workers_assigned == 1.0, "Second kiln should receive the final worker.", failures)
	_expect(second_kiln.worker_efficiency == 0.5, "Partial staffing should set proportional efficiency.", failures)
	_expect(farm.workers_assigned == 0.0, "Lower-priority farm should remain unstaffed.", failures)
	_expect(unfinished.worker_efficiency == 0.0, "Construction should always have zero efficiency.", failures)


func _context(registry: Variant) -> Dictionary:
	var state := StateType.new()
	return {
		"state": state,
		"graph": GraphType.new(registry, state),
		"workforce": WorkforceSystemType.new(registry),
	}


func _ready_node(context: Dictionary, entity_type: String) -> Variant:
	var node: Variant = context.graph.create_node(entity_type, 0.0, 0.0)
	node.state = NodeInstanceType.STATE_READY
	return node


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
