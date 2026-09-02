extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const StateType = preload("res://simulation/state/simulation_state.gd")
const GraphType = preload("res://simulation/systems/simulation_graph.gd")
const ProductionSystemType = preload("res://simulation/systems/production_system.gd")
const NodeInstanceType = preload("res://simulation/state/node_instance.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var registry := RegistryType.new()
	var result: Error = registry.load_from_path("res://scenarios/ancient_egypt/entities.json")
	_expect(result == OK, "Ancient Egypt definitions must load.", failures)

	_test_source_production(registry, failures)
	_test_source_capacity_block(registry, failures)
	_test_machine_batch(registry, failures)
	_test_worker_efficiency_floor(registry, failures)
	_test_output_capacity_block(registry, failures)
	_test_transport_output_pool(registry, failures)

	if failures.is_empty():
		print("PASS: production system")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_source_production(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var nile: Variant = context.graph.create_node("NILE_RIVER", 0.0, 0.0)
	context.production.process_all(context.state, 0.5)
	_expect(nile.state == NodeInstanceType.STATE_RUNNING, "Nile should remain running with capacity.", failures)
	_expect(nile.inventory.water == 1216.0, "Nile should produce output * rate * dt.", failures)


func _test_source_capacity_block(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var nile: Variant = context.graph.create_node("NILE_RIVER", 0.0, 0.0)
	nile.inventory.water = 6000.0
	context.production.process_all(context.state, 1.0)
	_expect(nile.state == NodeInstanceType.STATE_READY, "Full source should become ready.", failures)
	_expect(nile.inventory.water == 6000.0, "Full source must not exceed capacity.", failures)


func _test_machine_batch(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var kiln: Variant = _ready_machine(context, "BRICK_KILN", {"clay": 2.0, "water": 1.0})
	context.production.process_all(context.state, 0.1)
	_expect(kiln.inventory.clay == 0.0 and kiln.inventory.water == 0.0, "Inputs should be consumed at batch start.", failures)
	_expect(kiln.active_process_remaining_sec == 7.0, "New process must not advance on its starting tick.", failures)
	context.production.process_all(context.state, 7.0)
	_expect(kiln.inventory.mud_bricks == 4.0, "Completed batch should deposit its outputs.", failures)
	_expect(kiln.active_process_output_name == null, "Completed batch should clear process metadata.", failures)


func _test_worker_efficiency_floor(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var kiln: Variant = _ready_machine(context, "BRICK_KILN", {"clay": 2.0, "water": 1.0})
	kiln.worker_efficiency = 0.0
	context.production.process_all(context.state, 0.1)
	context.production.process_all(context.state, 4.0)
	_expect(kiln.active_process_remaining_sec == 6.0, "Efficiency floor should advance an unstaffed kiln at 25% speed.", failures)


func _test_output_capacity_block(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var kiln: Variant = _ready_machine(
		context,
		"BRICK_KILN",
		{"clay": 2.0, "water": 1.0, "mud_bricks": 448.0}
	)
	context.production.process_all(context.state, 1.0)
	_expect(kiln.state == NodeInstanceType.STATE_READY, "Machine without batch output room should stop.", failures)
	_expect(kiln.inventory.clay == 2.0, "Blocked machine should not consume inputs.", failures)


func _test_transport_output_pool(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	context.state.initialize_transport_inventory(registry)
	var workshop: Variant = _ready_machine(
		context,
		"SLED_WORKSHOP",
		{"planks": 2.0, "rope": 1.0}
	)
	context.production.process_all(context.state, 0.1)
	context.production.process_all(context.state, 11.0)
	_expect(context.state.transport_inventory.sled == 3.0, "Produced sled should enter global transport pool.", failures)
	_expect(not workshop.inventory.has("sled"), "Transport output should bypass node inventory.", failures)


func _context(registry: Variant) -> Dictionary:
	var state := StateType.new()
	return {
		"state": state,
		"graph": GraphType.new(registry, state),
		"production": ProductionSystemType.new(registry),
	}


func _ready_machine(context: Dictionary, entity_type: String, inventory: Dictionary) -> Variant:
	var machine: Variant = context.graph.create_node(entity_type, 0.0, 0.0)
	machine.state = NodeInstanceType.STATE_READY
	machine.inventory = inventory.duplicate(true)
	machine.worker_efficiency = 1.0
	return machine


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
