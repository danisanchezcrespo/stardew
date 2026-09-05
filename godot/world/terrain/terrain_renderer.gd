class_name TerrainRenderer
extends Node2D

var game: Node2D


func configure(owner_game: Node2D) -> void:
	game = owner_game
	z_as_relative = false
	z_index = -4096
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	queue_redraw()


func _draw() -> void:
	if game == null or game.world_grid == null: return
	for y in range(game.WORLD_SIZE.y):
		for x in range(game.WORLD_SIZE.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * game.CELL_SIZE), Vector2.ONE * game.CELL_SIZE)
			var terrain_texture: Texture2D = game.WATER_TEXTURE if game.water_cells.has(cell) else (game.ground_texture if game.ground_texture != null else game.SAND_TEXTURE)
			var source_position := Vector2((x * game.CELL_SIZE) % terrain_texture.get_width(), (y * game.CELL_SIZE) % terrain_texture.get_height())
			draw_texture_rect_region(terrain_texture, rect, Rect2(source_position, Vector2.ONE * game.CELL_SIZE))
			if game.path_cells.has(cell) and not game.water_cells.has(cell): _draw_path_cell(cell, rect)
			if game.water_cells.has(cell): _draw_shoreline(cell, rect)


func _draw_path_cell(cell: Vector2i, destination: Rect2) -> void:
	if game.path_texture != null:
		var source_position := Vector2((cell.x * game.CELL_SIZE) % game.path_texture.get_width(), (cell.y * game.CELL_SIZE) % game.path_texture.get_height())
		draw_texture_rect_region(game.path_texture, destination, Rect2(source_position, Vector2.ONE * game.CELL_SIZE))
		return
	draw_rect(destination, Color("#b89559") if (cell.x + cell.y) % 2 == 0 else Color("#bea064"))


func _draw_shoreline(cell: Vector2i, destination: Rect2) -> void:
	var bits := 0
	if not game.water_cells.has(cell + Vector2i.UP): bits |= 1
	if not game.water_cells.has(cell + Vector2i.RIGHT): bits |= 2
	if not game.water_cells.has(cell + Vector2i.DOWN): bits |= 4
	if not game.water_cells.has(cell + Vector2i.LEFT): bits |= 8
	if bits > 0:
		draw_texture_rect_region(game.SHORELINE_TEXTURE, destination, Rect2((bits % 4) * 64, floori(bits / 4.0) * 64, 64, 64))
	var diagonals := [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]
	var adjacent_pairs := [[Vector2i.UP, Vector2i.LEFT], [Vector2i.UP, Vector2i.RIGHT], [Vector2i.DOWN, Vector2i.RIGHT], [Vector2i.DOWN, Vector2i.LEFT]]
	for index in range(4):
		if not game.water_cells.has(cell + diagonals[index]) and game.water_cells.has(cell + adjacent_pairs[index][0]) and game.water_cells.has(cell + adjacent_pairs[index][1]):
			draw_texture_rect_region(game.SHORELINE_CORNER_TEXTURE, destination, Rect2(index * 64, 0, 64, 64))
