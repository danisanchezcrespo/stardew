class_name StructureVisual
extends Node2D

const BUILDING_TEXTURE = preload("res://assets/generated/buildings/egypt_buildings_sheet.png")
const ECONOMY_BUILDING_TEXTURE = preload("res://assets/generated/buildings/egypt_economy_buildings_sheet.png")
const CELL_SIZE := 32

var definition_id := ""
var sprite_size := Vector2.ZERO


func configure(type_id: String, cells: Array[Vector2i]) -> void:
	definition_id = type_id
	var minimum := cells[0]
	var maximum := cells[0]
	for cell: Vector2i in cells:
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	var footprint_size := Vector2(maximum - minimum + Vector2i.ONE) * CELL_SIZE
	sprite_size = Vector2(maxf(48.0, footprint_size.x + 20.0), maxf(56.0, footprint_size.y + 28.0))
	if definition_id == "SHRINE": sprite_size.y += 20.0
	global_position = Vector2((minimum.x + maximum.x + 1) * CELL_SIZE * 0.5, (maximum.y + 1) * CELL_SIZE)
	z_as_relative = false
	z_index = roundi(global_position.y)
	queue_redraw()


func _draw() -> void:
	var columns := {"STORAGE_CRATE": 0, "BRICK_KILN": 1, "DWELLING": 2, "SHRINE": 3}
	var economy_columns := {"GRAIN_FARM": 0, "BAKERY": 1, "BREWERY": 2, "KITCHEN": 3, "SAWMILL": 4}
	var destination := Rect2(Vector2(-sprite_size.x * 0.5, -sprite_size.y), sprite_size)
	if economy_columns.has(definition_id):
		var cell_width := ECONOMY_BUILDING_TEXTURE.get_width() / 5.0
		draw_texture_rect_region(ECONOMY_BUILDING_TEXTURE, destination, Rect2(int(economy_columns[definition_id]) * cell_width, 0, cell_width, ECONOMY_BUILDING_TEXTURE.get_height()))
	elif columns.has(definition_id):
		draw_texture_rect_region(BUILDING_TEXTURE, destination, Rect2(int(columns[definition_id]) * 256, 0, 256, 256))
