extends SceneTree

const GridMathType = preload("res://world/spatial/grid_math.gd")
const DirectionType = preload("res://world/spatial/grid_direction.gd")
const FootprintType = preload("res://world/spatial/spatial_footprint.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	_test_grid_conversions(failures)
	_test_direction_rotation(failures)
	_test_irregular_footprint(failures)
	_test_ports_follow_rotation(failures)
	_test_validation(failures)

	if failures.is_empty():
		print("PASS: spatial primitives")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_grid_conversions(failures: Array[String]) -> void:
	_expect(GridMathType.world_to_cell(Vector2.ZERO) == Vector2i.ZERO, "Origin should be cell zero.", failures)
	_expect(GridMathType.world_to_cell(Vector2(31.999, 31.999)) == Vector2i.ZERO, "Upper edge should stay in cell zero.", failures)
	_expect(GridMathType.world_to_cell(Vector2(32.0, 32.0)) == Vector2i.ONE, "Boundary should enter the next cell.", failures)
	_expect(GridMathType.world_to_cell(Vector2(-0.01, -32.01)) == Vector2i(-1, -2), "Negative positions should floor consistently.", failures)
	_expect(GridMathType.cell_to_world_origin(Vector2i(2, 3)) == Vector2(64, 96), "Cell origin should use the visual scale.", failures)
	_expect(GridMathType.cell_to_world_center(Vector2i(-1, 0)) == Vector2(-16, 16), "Cell center should work across the origin.", failures)


func _test_direction_rotation(failures: Array[String]) -> void:
	var cell := Vector2i(2, 1)
	_expect(DirectionType.rotate_cell_clockwise(cell, 0) == Vector2i(2, 1), "North rotation should preserve a cell.", failures)
	_expect(DirectionType.rotate_cell_clockwise(cell, 1) == Vector2i(-1, 2), "East rotation should turn clockwise in screen coordinates.", failures)
	_expect(DirectionType.rotate_cell_clockwise(cell, 2) == Vector2i(-2, -1), "South rotation should invert a cell.", failures)
	_expect(DirectionType.rotate_cell_clockwise(cell, 3) == Vector2i(1, -2), "West rotation should turn counter-clockwise once.", failures)
	_expect(DirectionType.rotate_cell_clockwise(cell, 4) == cell, "Rotations should wrap after four turns.", failures)
	_expect(DirectionType.normalize(-1) == 3, "Negative rotations should normalize.", failures)


func _test_irregular_footprint(failures: Array[String]) -> void:
	var footprint: RefCounted = FootprintType.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)])
	var transformed: Array[Vector2i] = footprint.transformed_cells(Vector2i(10, 20), 1)
	_expect(transformed == [Vector2i(9, 20), Vector2i(10, 20), Vector2i(10, 21)], "Irregular footprint should rotate around its origin without filling its hole.", failures)
	_expect(not transformed.has(Vector2i(9, 21)), "Irregular footprint hole must remain empty.", failures)


func _test_ports_follow_rotation(failures: Array[String]) -> void:
	var footprint: RefCounted = FootprintType.new(
		[Vector2i(0, 0), Vector2i(1, 0)],
		{"input": Vector2i(-1, 0), "output": Vector2i(2, 0)}
	)
	var ports: Dictionary = footprint.transformed_ports(Vector2i(5, 5), 1)
	_expect(ports["input"] == Vector2i(5, 4), "Input port should rotate with the footprint.", failures)
	_expect(ports["output"] == Vector2i(5, 7), "Output port should rotate with the footprint.", failures)


func _test_validation(failures: Array[String]) -> void:
	var invalid: RefCounted = FootprintType.new(
		[Vector2i.ZERO, Vector2i.ZERO],
		{"": Vector2i.ZERO, "bad": "not a cell"},
		[0, 0, 5]
	)
	var errors: Array[String] = invalid.validate()
	_expect(errors.size() == 5, "Invalid footprint should report every independent error: %s" % str(errors), failures)

	var valid: RefCounted = FootprintType.new([Vector2i.ZERO], {"use": Vector2i(0, 1)}, [0, 2])
	_expect(valid.validate().is_empty(), "Valid footprint should pass validation.", failures)
	_expect(valid.supports_rotation(2), "Allowed rotation should be supported.", failures)
	_expect(not valid.supports_rotation(1), "Disallowed rotation should be rejected.", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
