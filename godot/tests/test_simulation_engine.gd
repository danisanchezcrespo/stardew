extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const EngineType = preload("res://simulation/simulation_engine.gd")
const NodeInstanceType = preload("res://simulation/state/node_instance.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var registry := RegistryType.new()
	var result: Error = registry.load_from_path("res://scenarios/ancient_egypt/entities.json")
	_expect(result == OK, "Ancient Egypt definitions must load.", failures)

	_test_step_accounting(registry, failures)
	_test_new_packet_does_not_move(registry, failures)
	_test_delivery_is_used_on_next_tick(registry, failures)
	_test_population_precedes_production(registry, failures)
	_test_construction_promotes_after_delivery(registry, failures)
	_test_engine_mutation_api(registry, failures)

	if failures.is_empty():
		print("PASS: simulation engine")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_step_accounting(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	engine.step_many(0.1, 3)
	_expect(engine.step_count == 3, "Engine should count explicit steps.", failures)
	_expect(is_equal_approx(engine.simulated_seconds, 0.3), "Engine should accumulate simulated time.", failures)


func _test_new_packet_does_not_move(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	var nile: Variant = engine.create_node("NILE_RIVER", 0.0, 0.0)
	var farm: Variant = engine.create_node("GRAIN_FARM", 45.0, 0.0)
	farm.state = NodeInstanceType.STATE_READY
	farm.inventory = {}
	var edge: Variant = engine.connect_nodes(nile.id, farm.id, "PORTER")
	engine.step(0.1)
	_expect(edge.packet != null, "Idle edge should launch during the tick.", failures)
	_expect(edge.packet.progress == 0.0, "Packet launched this tick must not move yet.", failures)
	_expect(not farm.inventory.has("water"), "Target should not receive newly launched cargo in same tick.", failures)


func _test_delivery_is_used_on_next_tick(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	var nile: Variant = engine.create_node("NILE_RIVER", 0.0, 0.0)
	var farm: Variant = engine.create_node("GRAIN_FARM", 4.5, 0.0)
	farm.state = NodeInstanceType.STATE_READY
	farm.inventory = {}
	engine.connect_nodes(nile.id, farm.id, "PORTER")

	engine.step(0.1)
	engine.step(0.1)
	_expect(farm.inventory.water == 12.0, "Second tick should deliver the existing packet.", failures)
	_expect(farm.active_process_remaining_sec == 0.0, "Delivered input must not start production during delivery tick.", failures)
	engine.step(0.1)
	_expect(farm.active_process_remaining_sec == 7.0, "Delivered input should start a batch on following tick.", failures)
	_expect(farm.inventory.water == 10.0, "Starting grain batch should consume two water.", failures)


func _test_population_precedes_production(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	var huts: Variant = engine.create_node("WORKERS_HUTS", 0.0, 0.0)
	huts.state = NodeInstanceType.STATE_READY
	var kitchen: Variant = engine.create_node("KITCHEN", 0.0, 0.0)
	kitchen.state = NodeInstanceType.STATE_READY
	kitchen.inventory = {"bread": 2.0, "beer": 1.0}
	kitchen.worker_efficiency = 1.0
	engine.state.workers_current = 2.0

	engine.step(0.1)
	_expect(engine.state.food_available == 0.0, "Population phase should not see food produced later in tick.", failures)
	_expect(engine.state.food_support_ratio == 0.0, "Workers should be unsupported before kitchen output exists.", failures)
	_expect(kitchen.active_process_remaining_sec == 3.0, "Production should still start after worker allocation.", failures)


func _test_construction_promotes_after_delivery(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	var forest: Variant = engine.create_node("DELTA_FOREST", 0.0, 0.0)
	var kiln: Variant = engine.create_node("BRICK_KILN", 45.0, 0.0)
	engine.connect_nodes(forest.id, kiln.id, "SLED")
	engine.step(1.0)
	_expect(kiln.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION, "Construction should remain pending while packet has just launched.", failures)
	engine.step(1.0)
	_expect(kiln.state == NodeInstanceType.STATE_READY, "Construction should promote at end of delivery tick.", failures)
	_expect(engine.state.edges.is_empty(), "Promotion should release incoming construction edge.", failures)


func _test_engine_mutation_api(registry: Variant, failures: Array[String]) -> void:
	var engine := EngineType.new(registry)
	var forest: Variant = engine.create_node("DELTA_FOREST", 0.0, 0.0)
	var kiln: Variant = engine.create_node("BRICK_KILN", 45.0, 0.0)
	engine.connect_nodes(forest.id, kiln.id, "PORTER")
	engine.delete_node(forest.id)
	_expect(engine.graph.get_node(forest.id) == null, "Engine delete API should remove node.", failures)
	_expect(engine.state.edges.is_empty(), "Engine delete API should remove incident edge.", failures)
	_expect(engine.state.transport_inventory.porter == 2.0, "Deleting through engine should refund transporter.", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
