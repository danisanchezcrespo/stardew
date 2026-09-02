extends SceneTree

const RegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const StateType = preload("res://simulation/state/simulation_state.gd")
const GraphType = preload("res://simulation/systems/simulation_graph.gd")
const ConstructionType = preload("res://simulation/systems/construction_system.gd")
const ProductionType = preload("res://simulation/systems/production_system.gd")
const TransportType = preload("res://simulation/systems/transport_system.gd")
const NodeInstanceType = preload("res://simulation/state/node_instance.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var registry := RegistryType.new()
	var result: Error = registry.load_from_path("res://scenarios/ancient_egypt/entities.json")
	_expect(result == OK, "Ancient Egypt definitions must load.", failures)

	_test_connection_cost_and_refund(registry, failures)
	_test_packet_delivery_and_ping_pong_return(registry, failures)
	_test_one_way_relaunch(failures)
	_test_incoming_reservations(registry, failures)
	_test_construction_promotion_releases_edge(registry, failures)
	_test_blocked_machine_releases_full_input_edge(registry, failures)

	if failures.is_empty():
		print("PASS: transport system")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_connection_cost_and_refund(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var forest: Variant = context.graph.create_node("DELTA_FOREST", 0.0, 0.0)
	var kiln: Variant = context.graph.create_node("BRICK_KILN", 45.0, 0.0)
	_expect(context.transport.can_connect_nodes(forest.id, kiln.id), "Wood source should connect to kiln construction.", failures)
	var edge: Variant = context.transport.connect_nodes(context.state, forest.id, kiln.id, "PORTER")
	_expect(edge != null, "Compatible nodes should connect.", failures)
	_expect(context.state.transport_inventory.porter == 1.0, "Connection should spend one porter.", failures)
	_expect(context.transport.connect_nodes(context.state, forest.id, kiln.id, "PORTER") == null, "Duplicate edge should be rejected.", failures)
	context.transport.delete_edge(context.state, 0)
	_expect(context.state.transport_inventory.porter == 2.0, "Deleting edge should refund its porter.", failures)


func _test_packet_delivery_and_ping_pong_return(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var forest: Variant = context.graph.create_node("DELTA_FOREST", 0.0, 0.0)
	var kiln: Variant = context.graph.create_node("BRICK_KILN", 45.0, 0.0)
	var edge: Variant = context.transport.connect_nodes(context.state, forest.id, kiln.id, "PORTER")
	context.transport.launch_packets(context.state)
	_expect(edge.packet.amount == 12.0, "Packet should use porter trip capacity.", failures)
	_expect(forest.inventory.wood == 438.0, "Cargo should leave source on launch.", failures)
	context.transport.advance_transporters(context.state, 1.0)
	_expect(kiln.construction_progress.wood == 12.0, "Arriving packet should deliver construction material.", failures)
	_expect(edge.packet == null and edge.return_progress == 0.0, "Ping-pong edge should begin empty return.", failures)
	context.transport.launch_packets(context.state)
	_expect(edge.packet == null, "Returning transporter must not relaunch.", failures)
	context.transport.advance_transporters(context.state, 1.0)
	_expect(edge.return_progress == null, "Empty return should finish after equal travel time.", failures)


func _test_incoming_reservations(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var first: Variant = context.graph.create_node("DELTA_FOREST", 0.0, 0.0)
	var second: Variant = context.graph.create_node("DELTA_FOREST", 0.0, 45.0)
	var kiln: Variant = context.graph.create_node("BRICK_KILN", 45.0, 0.0)
	var first_edge: Variant = context.transport.connect_nodes(context.state, first.id, kiln.id, "PORTER")
	var second_edge: Variant = context.transport.connect_nodes(context.state, second.id, kiln.id, "SLED")
	context.transport.launch_packets(context.state)
	_expect(first_edge.packet.amount == 12.0, "First packet should reserve 12 wood.", failures)
	_expect(second_edge.packet.amount == 13.0, "Second packet should reserve only remaining construction need.", failures)


func _test_one_way_relaunch(failures: Array[String]) -> void:
	var registry := RegistryType.new()
	var result: Error = registry.load_from_dictionary(
		{
			"entities": [
				{
					"id": "SOURCE",
					"initial_amounts": {"ore": 5},
					"max_amounts": {"ore": 10},
					"recipe_outputs": {"ore": 1},
					"source_rate_per_sec": 1,
				},
				{
					"id": "TARGET",
					"max_amounts": {"ore": 5, "product": 10},
					"recipe_inputs": {"ore": 1},
					"recipe_outputs": {"product": 1},
					"process_time_sec": 1,
				},
			],
			"edges": [
				{
					"id": "BELT",
					"speed": 10,
					"capacity_per_trip": 3,
					"mode": "one_way",
				}
			],
		}
	)
	_expect(result == OK, "One-way transport fixture should load.", failures)
	var context := _context(registry)
	var source: Variant = context.graph.create_node("SOURCE", 0.0, 0.0)
	var target: Variant = context.graph.create_node("TARGET", 10.0, 0.0)
	var edge: Variant = context.transport.connect_nodes(context.state, source.id, target.id, "BELT")
	context.transport.launch_packets(context.state)
	context.transport.advance_transporters(context.state, 1.0)
	_expect(target.inventory.ore == 3.0, "One-way packet should deliver after distance/speed seconds.", failures)
	_expect(edge.return_progress == null, "One-way edge should not start an empty return.", failures)
	context.transport.launch_packets(context.state)
	_expect(edge.packet.amount == 2.0, "One-way edge should relaunch immediately after delivery phase.", failures)


func _test_construction_promotion_releases_edge(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var forest: Variant = context.graph.create_node("DELTA_FOREST", 0.0, 0.0)
	var kiln: Variant = context.graph.create_node("BRICK_KILN", 45.0, 0.0)
	var edge: Variant = context.transport.connect_nodes(context.state, forest.id, kiln.id, "SLED")
	context.transport.launch_packets(context.state)
	context.transport.advance_transporters(context.state, 1.0)
	_expect(edge.packet == null, "Construction packet should have arrived.", failures)
	context.transport.promote_finished_construction(context.state)
	_expect(kiln.state == NodeInstanceType.STATE_READY, "Fully supplied construction should promote.", failures)
	_expect(context.state.edges.is_empty(), "Promotion should release idle incoming edge.", failures)
	_expect(context.state.transport_inventory.sled == 2.0, "Released construction edge should refund its sled.", failures)


func _test_blocked_machine_releases_full_input_edge(registry: Variant, failures: Array[String]) -> void:
	var context := _context(registry)
	var clay: Variant = context.graph.create_node("CLAY_PIT", 0.0, 0.0)
	var kiln: Variant = context.graph.create_node("BRICK_KILN", 45.0, 0.0)
	kiln.state = NodeInstanceType.STATE_READY
	kiln.inventory = {"clay": 300.0, "mud_bricks": 448.0}
	var edge: Variant = context.transport.connect_nodes(context.state, clay.id, kiln.id, "PORTER")
	_expect(edge != null, "Clay input edge should connect.", failures)
	context.production.process_all(context.state, 1.0)
	_expect(context.state.edges.is_empty(), "Output-blocked machine should release edge for its full input.", failures)
	_expect(context.state.transport_inventory.porter == 2.0, "Released production edge should refund transporter.", failures)


func _context(registry: Variant) -> Dictionary:
	var state := StateType.new()
	state.initialize_transport_inventory(registry)
	var graph := GraphType.new(registry, state)
	var construction := ConstructionType.new(registry)
	var production := ProductionType.new(registry)
	var transport := TransportType.new(registry, graph, construction, production)
	production.set_transport_system(transport)
	return {
		"state": state,
		"graph": graph,
		"construction": construction,
		"production": production,
		"transport": transport,
	}


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
