class_name SimulationEngine
extends RefCounted

const StateType = preload("res://simulation/state/simulation_state.gd")
const GraphType = preload("res://simulation/systems/simulation_graph.gd")
const InventorySystemType = preload("res://simulation/systems/inventory_system.gd")
const ConstructionSystemType = preload("res://simulation/systems/construction_system.gd")
const WorkforceSystemType = preload("res://simulation/systems/workforce_system.gd")
const ProductionSystemType = preload("res://simulation/systems/production_system.gd")
const TransportSystemType = preload("res://simulation/systems/transport_system.gd")
const ProgressionSystemType = preload("res://simulation/systems/progression_system.gd")
const SavegameCodecType = preload("res://simulation/persistence/savegame_codec.gd")
const WorldGridType = preload("res://world/placement/world_grid.gd")

var registry: Variant
var state: Variant
var graph: Variant
var inventory: Variant
var construction: Variant
var workforce: Variant
var production: Variant
var transport: Variant
var progression: Variant
var savegames: Variant
var world_grid: Variant = null
var step_count: int = 0
var simulated_seconds: float = 0.0


func _init(definition_registry: Variant) -> void:
	registry = definition_registry
	state = StateType.new()
	state.initialize_transport_inventory(registry)
	graph = GraphType.new(registry, state)
	inventory = InventorySystemType
	construction = ConstructionSystemType.new(registry)
	workforce = WorkforceSystemType.new(registry)
	production = ProductionSystemType.new(registry)
	transport = TransportSystemType.new(registry, graph, construction, production)
	production.set_transport_system(transport)
	progression = ProgressionSystemType.new(registry)
	savegames = SavegameCodecType.new()


func step(dt: float) -> void:
	workforce.process(state, dt)
	production.process_all(state, dt)
	transport.advance_transporters(state, dt)
	transport.launch_packets(state)
	transport.promote_finished_construction(state)
	step_count += 1
	simulated_seconds += dt


func step_many(dt: float, count: int) -> void:
	for _index in range(count):
		step(dt)


func create_node(entity_type: String, world_x: float, world_y: float) -> Variant:
	return graph.create_node(entity_type, world_x, world_y)


func connect_nodes(from_id: int, to_id: int, edge_type_id: String) -> Variant:
	return transport.connect_nodes(state, from_id, to_id, edge_type_id)


func configure_world(grid_size: Vector2i, default_terrain: String = "ground") -> Variant:
	world_grid = WorldGridType.new(grid_size, default_terrain)
	return world_grid


func delete_edge(edge_index: int) -> void:
	transport.delete_edge(state, edge_index)


func delete_node(node_id: int) -> void:
	transport.delete_node(state, node_id)


func build_savegame_data() -> Dictionary:
	return savegames.build_savegame_data(self)


func save_to_path(path: String) -> Error:
	return savegames.save_to_path(self, path)


func load_from_path(path: String) -> Error:
	return savegames.load_from_path(self, path)


func load_from_dictionary(data: Dictionary) -> Error:
	return savegames.load_from_dictionary(self, data)
