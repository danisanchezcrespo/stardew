class_name SpatialFootprint
extends RefCounted

const DirectionType = preload("res://world/spatial/grid_direction.gd")

var cells: Array[Vector2i] = []
var ports: Dictionary = {}
var allowed_rotations: Array[int] = [0, 1, 2, 3]


func _init(
	footprint_cells: Array[Vector2i],
	footprint_ports: Dictionary = {},
	rotations: Array[int] = [0, 1, 2, 3]
) -> void:
	cells = footprint_cells.duplicate()
	ports = footprint_ports.duplicate(true)
	allowed_rotations = rotations.duplicate()


func validate() -> Array[String]:
	var errors: Array[String] = []
	if cells.is_empty():
		errors.append("Footprint must contain at least one cell.")

	var unique_cells: Dictionary = {}
	for cell in cells:
		if unique_cells.has(cell):
			errors.append("Footprint contains duplicate cell %s." % str(cell))
		unique_cells[cell] = true

	if allowed_rotations.is_empty():
		errors.append("Footprint must allow at least one rotation.")
	var unique_rotations: Dictionary = {}
	for rotation in allowed_rotations:
		if rotation < 0 or rotation > 3:
			errors.append("Rotation %d is not a quarter turn from 0 to 3." % rotation)
		elif unique_rotations.has(rotation):
			errors.append("Rotation %d is duplicated." % rotation)
		unique_rotations[rotation] = true

	for port_name: Variant in ports:
		if not port_name is String or String(port_name).is_empty():
			errors.append("Port names must be non-empty strings.")
		elif not ports[port_name] is Vector2i:
			errors.append("Port '%s' must use a Vector2i cell." % String(port_name))

	return errors


func supports_rotation(rotation: int) -> bool:
	return allowed_rotations.has(DirectionType.normalize(rotation))


func transformed_cells(origin: Vector2i, rotation: int) -> Array[Vector2i]:
	var transformed: Array[Vector2i] = []
	for cell in cells:
		transformed.append(origin + DirectionType.rotate_cell_clockwise(cell, rotation))
	transformed.sort_custom(_sort_cells)
	return transformed


func transformed_ports(origin: Vector2i, rotation: int) -> Dictionary:
	var transformed: Dictionary = {}
	for port_name: Variant in ports:
		var port_cell: Vector2i = ports[port_name]
		transformed[port_name] = origin + DirectionType.rotate_cell_clockwise(port_cell, rotation)
	return transformed


static func _sort_cells(left: Vector2i, right: Vector2i) -> bool:
	if left.y == right.y:
		return left.x < right.x
	return left.y < right.y
