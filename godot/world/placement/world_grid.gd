class_name WorldGrid
extends RefCounted

const PlacementResultType = preload("res://world/placement/placement_result.gd")
const PlacedEntityType = preload("res://world/placement/placed_entity.gd")

var size: Vector2i
var default_terrain: String
var terrain_by_cell: Dictionary = {}
var occupant_by_cell: Dictionary = {}
var entities_by_id: Dictionary = {}


func _init(grid_size: Vector2i, base_terrain: String = "ground") -> void:
	assert(grid_size.x > 0 and grid_size.y > 0, "World grid dimensions must be positive.")
	size = grid_size
	default_terrain = base_terrain


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func terrain_at(cell: Vector2i) -> String:
	return str(terrain_by_cell.get(cell, default_terrain))


func set_terrain(cell: Vector2i, terrain_id: String) -> bool:
	if not contains(cell) or terrain_id.is_empty():
		return false
	terrain_by_cell[cell] = terrain_id
	return true


func occupant_at(cell: Vector2i) -> String:
	return str(occupant_by_cell.get(cell, ""))


func query_placement(footprint: RefCounted, origin: Vector2i, rotation: int, allowed_terrain: Array[String] = []) -> RefCounted:
	if not footprint.supports_rotation(rotation):
		return PlacementResultType.new(false, PlacementResultType.ROTATION_NOT_ALLOWED, [])
	var cells: Array[Vector2i] = footprint.transformed_cells(origin, rotation)
	for cell in cells:
		if not contains(cell):
			return PlacementResultType.new(false, PlacementResultType.OUT_OF_BOUNDS, cells, cell)
		if occupant_by_cell.has(cell):
			return PlacementResultType.new(false, PlacementResultType.OCCUPIED, cells, cell)
		if not allowed_terrain.is_empty() and not allowed_terrain.has(terrain_at(cell)):
			return PlacementResultType.new(false, PlacementResultType.INVALID_TERRAIN, cells, cell)
	return PlacementResultType.new(true, PlacementResultType.OK, cells)


func place(instance_id: String, definition_id: String, footprint: RefCounted, origin: Vector2i, rotation: int, allowed_terrain: Array[String] = []) -> RefCounted:
	if instance_id.is_empty() or entities_by_id.has(instance_id):
		return PlacementResultType.new(false, PlacementResultType.INVALID_ENTITY_ID, [])
	var result: RefCounted = query_placement(footprint, origin, rotation, allowed_terrain)
	if not result.valid:
		return result
	var placed: RefCounted = PlacedEntityType.new(instance_id, definition_id, origin, rotation, result.cells)
	entities_by_id[instance_id] = placed
	for cell in result.cells:
		occupant_by_cell[cell] = instance_id
	return result


func remove(instance_id: String) -> bool:
	var placed: Variant = entities_by_id.get(instance_id)
	if placed == null:
		return false
	for cell: Vector2i in placed.cells:
		if occupant_by_cell.get(cell) == instance_id:
			occupant_by_cell.erase(cell)
	entities_by_id.erase(instance_id)
	return true
