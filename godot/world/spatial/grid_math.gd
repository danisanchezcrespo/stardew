class_name GridMath
extends RefCounted

const DEFAULT_CELL_SIZE_PX := 32


static func world_to_cell(world_position: Vector2, cell_size_px: int = DEFAULT_CELL_SIZE_PX) -> Vector2i:
	assert(cell_size_px > 0, "Cell size must be positive.")
	return Vector2i(
		floori(world_position.x / float(cell_size_px)),
		floori(world_position.y / float(cell_size_px))
	)


static func cell_to_world_origin(cell: Vector2i, cell_size_px: int = DEFAULT_CELL_SIZE_PX) -> Vector2:
	assert(cell_size_px > 0, "Cell size must be positive.")
	return Vector2(cell * cell_size_px)


static func cell_to_world_center(cell: Vector2i, cell_size_px: int = DEFAULT_CELL_SIZE_PX) -> Vector2:
	return cell_to_world_origin(cell, cell_size_px) + Vector2.ONE * (float(cell_size_px) * 0.5)


static func snap_world_to_cell_origin(world_position: Vector2, cell_size_px: int = DEFAULT_CELL_SIZE_PX) -> Vector2:
	return cell_to_world_origin(world_to_cell(world_position, cell_size_px), cell_size_px)
