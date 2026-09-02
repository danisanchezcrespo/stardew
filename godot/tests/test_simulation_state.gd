extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const StateType = preload("res://simulation/state/simulation_state.gd")
const GraphType = preload("res://simulation/systems/simulation_graph.gd")
const InventorySystem = preload("res://simulation/systems/inventory_system.gd")
const ConstructionSystemType = preload("res://simulation/systems/construction_system.gd")
const NodeInstanceType = preload("res://simulation/state/node_instance.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var registry := RegistryType.new()
	var load_result: Error = registry.load_from_path("res://scenarios/ancient_egypt/entities.json")
	_expect(load_result == OK, "Definitions must load before state tests.", failures)

	_test_initial_state(registry, failures)
	_test_node_creation(registry, failures)
	_test_inventory(registry, failures)
	_test_construction(registry, failures)
	_test_graph_edges(registry, failures)

	if failures.is_empty():
		print("PASS: simulation state")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_initial_state(registry: Variant, failures: Array[String]) -> void:
	var state := StateType.new()
	state.initialize_transport_inventory(registry)
	_expect(state.next_node_id == 1, "Node IDs should start at 1.", failures)
	_expect(state.transport_inventory.get("porter") == 2.0, "Initial pool should contain 2 porters.", failures)
	_expect(state.transport_inventory.get("sled") == 2.0, "Initial pool should contain 2 sleds.", failures)
	_expect(state.transport_inventory.get("ox_cart") == 0.0, "Initial ox cart pool should be empty.", failures)


func _test_node_creation(registry: Variant, failures: Array[String]) -> void:
	var state := StateType.new()
	var graph := GraphType.new(registry, state)
	var source: Variant = graph.create_node("NILE_RIVER", 40.0, 80.0)
	var machine: Variant = graph.create_node("BRICK_KILN", 120.0, 80.0)
	_expect(source.id == 1 and machine.id == 2, "Node IDs should be monotonic.", failures)
	_expect(source.state == NodeInstanceType.STATE_RUNNING, "Cost-free source should start running.", failures)
	_expect(source.inventory.get("water") == 1200.0, "Source should copy initial inventory.", failures)
	_expect(machine.state == NodeInstanceType.STATE_UNDER_CONSTRUCTION, "Costed machine should start under construction.", failures)
	_expect(machine.inventory.is_empty(), "Construction inventory should start empty.", failures)
	_expect(machine.construction_progress.get("wood") == 0.0, "Construction progress should contain zeroed costs.", failures)
	_expect(graph.create_node("DOES_NOT_EXIST", 0.0, 0.0) == null, "Unknown entity types should be rejected.", failures)


func _test_inventory(registry: Variant, failures: Array[String]) -> void:
	var kiln: Variant = registry.get_entity("BRICK_KILN")
	var inventory := {"clay": 299.0, "water": 2.0}
	var accepted := InventorySystem.add_capped(inventory, kiln.max_amounts, "clay", 5.0)
	_expect(accepted == 1.0 and inventory.clay == 300.0, "Inventory additions should respect capacity.", failures)
	_expect(InventorySystem.has_resources(inventory, {"clay": 2, "water": 1}), "Inventory should recognize complete costs.", failures)
	_expect(InventorySystem.consume_resources(inventory, {"clay": 2, "water": 1}), "Atomic cost consumption should succeed.", failures)
	_expect(inventory.clay == 298.0 and inventory.water == 1.0, "Cost consumption should update every resource.", failures)


func _test_construction(registry: Variant, failures: Array[String]) -> void:
	var state := StateType.new()
	var graph := GraphType.new(registry, state)
	var construction := ConstructionSystemType.new(registry)
	var kiln: Variant = graph.create_node("BRICK_KILN", 0.0, 0.0)

	_expect(construction.get_progress(kiln) == 0.0, "New construction should have zero progress.", failures)
	_expect(construction.deliver(kiln, "wood", 10.0) == 10.0, "Construction should accept needed material.", failures)
	_expect(is_equal_approx(construction.get_progress(kiln), 0.4), "Progress should be delivered cost fraction.", failures)
	_expect(not construction.promote_if_finished(kiln), "Incomplete construction should not promote.", failures)
	_expect(construction.deliver(kiln, "wood", 50.0) == 15.0, "Construction delivery should cap at remaining cost.", failures)
	_expect(construction.promote_if_finished(kiln), "Completed construction should promote.", failures)
	_expect(kiln.state == NodeInstanceType.STATE_READY, "Completed construction should become ready.", failures)


func _test_graph_edges(registry: Variant, failures: Array[String]) -> void:
	var state := StateType.new()
	var graph := GraphType.new(registry, state)
	var first: Variant = graph.create_node("NILE_RIVER", 0.0, 0.0)
	var second: Variant = graph.create_node("GRAIN_FARM", 80.0, 0.0)
	_expect(graph.create_edge(first.id, first.id, "PORTER") == null, "Self edges should be rejected.", failures)
	_expect(graph.create_edge(first.id, second.id, "PORTER") != null, "Valid edge should be created.", failures)
	_expect(graph.create_edge(first.id, second.id, "PORTER") == null, "Duplicate direction should be rejected.", failures)
	_expect(graph.create_edge(second.id, first.id, "PORTER") != null, "Reverse edge should be allowed.", failures)
	graph.remove_node(first.id)
	_expect(graph.get_node(first.id) == null, "Removed node should disappear.", failures)
	_expect(state.edges.is_empty(), "Removing a node should remove incident edges.", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
