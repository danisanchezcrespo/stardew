extends SceneTree

const FootprintType = preload("res://world/spatial/spatial_footprint.gd")
const WorldGridType = preload("res://world/placement/world_grid.gd")
const PlacementResultType = preload("res://world/placement/placement_result.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	_test_query_reasons_do_not_mutate(failures)
	_test_place_and_remove_are_atomic(failures)
	_test_irregular_occupancy(failures)

	if failures.is_empty():
		print("PASS: world grid")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_query_reasons_do_not_mutate(failures: Array[String]) -> void:
	var grid: RefCounted = WorldGridType.new(Vector2i(4, 4), "sand")
	var footprint: RefCounted = FootprintType.new([Vector2i.ZERO, Vector2i.RIGHT], {}, [0])
	var sand_only: Array[String] = ["sand"]

	var rotation_result: RefCounted = grid.query_placement(footprint, Vector2i.ZERO, 1, sand_only)
	_expect(rotation_result.reason == PlacementResultType.ROTATION_NOT_ALLOWED, "Forbidden rotation should have a stable reason.", failures)
	var bounds_result: RefCounted = grid.query_placement(footprint, Vector2i(3, 0), 0, sand_only)
	_expect(bounds_result.reason == PlacementResultType.OUT_OF_BOUNDS, "Outside footprint should be rejected.", failures)

	grid.set_terrain(Vector2i(1, 0), "water")
	var terrain_result: RefCounted = grid.query_placement(footprint, Vector2i.ZERO, 0, sand_only)
	_expect(terrain_result.reason == PlacementResultType.INVALID_TERRAIN, "Wrong terrain should be rejected.", failures)
	_expect(grid.entities_by_id.is_empty() and grid.occupant_by_cell.is_empty(), "Queries must never mutate occupancy.", failures)


func _test_place_and_remove_are_atomic(failures: Array[String]) -> void:
	var grid: RefCounted = WorldGridType.new(Vector2i(5, 5))
	var footprint: RefCounted = FootprintType.new([Vector2i.ZERO, Vector2i.RIGHT])
	var placed: RefCounted = grid.place("chest-1", "CHEST", footprint, Vector2i(1, 1), 0)
	_expect(placed.valid, "First entity should be placed.", failures)
	_expect(grid.occupant_at(Vector2i(1, 1)) == "chest-1", "Origin cell should be occupied.", failures)
	_expect(grid.occupant_at(Vector2i(2, 1)) == "chest-1", "Second footprint cell should be occupied.", failures)

	var before: Dictionary = grid.occupant_by_cell.duplicate()
	var overlap: RefCounted = grid.place("chest-2", "CHEST", footprint, Vector2i(2, 1), 0)
	_expect(overlap.reason == PlacementResultType.OCCUPIED, "Overlap should be rejected.", failures)
	_expect(grid.occupant_by_cell == before and not grid.entities_by_id.has("chest-2"), "Rejected placement must be atomic.", failures)

	var duplicate: RefCounted = grid.place("chest-1", "CHEST", footprint, Vector2i(3, 3), 0)
	_expect(duplicate.reason == PlacementResultType.INVALID_ENTITY_ID, "Duplicate stable ID should be rejected.", failures)
	_expect(grid.remove("chest-1"), "Existing entity should be removable.", failures)
	_expect(grid.occupant_at(Vector2i(1, 1)).is_empty() and grid.occupant_at(Vector2i(2, 1)).is_empty(), "Removal should free exactly owned cells.", failures)
	_expect(not grid.remove("chest-1"), "Removing a missing entity should be harmless.", failures)


func _test_irregular_occupancy(failures: Array[String]) -> void:
	var grid: RefCounted = WorldGridType.new(Vector2i(4, 4))
	var footprint: RefCounted = FootprintType.new([Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN])
	var result: RefCounted = grid.place("workbench-1", "WORKBENCH", footprint, Vector2i(1, 1), 0)
	_expect(result.valid, "Irregular entity should be placed.", failures)
	_expect(grid.occupant_at(Vector2i(2, 2)).is_empty(), "Hole in irregular footprint must remain free.", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
