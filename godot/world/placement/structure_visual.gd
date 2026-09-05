class_name StructureVisual
extends Node2D

const BUILDING_TEXTURE = preload("res://assets/generated/buildings/egypt_buildings_sheet.png")
const ECONOMY_BUILDING_TEXTURE = preload("res://assets/generated/buildings/egypt_economy_buildings_sheet.png")
const SHRINE_TEXTURE = preload("res://assets/generated/buildings/egypt_shrine_v2.png")
const INDUSTRY_TEXTURE = preload("res://assets/generated/buildings/egypt_industry_buildings.png")
const CELL_SIZE := 32

var definition_id := ""
var sprite_size := Vector2.ZERO
var machine_running := false
var machine_broken := false
var effect_time := 0.0
var visual: Dictionary = {}
var upgrade_level := 1


func set_upgrade_level(level: int) -> void:
	upgrade_level = clampi(level, 1, 3)
	queue_redraw()


func set_machine_state(running: bool, broken: bool, delta: float) -> void:
	machine_running = running
	machine_broken = broken
	if running: effect_time += maxf(delta, 0.0)
	queue_redraw()


func configure(type_id: String, cells: Array[Vector2i], visual_data: Dictionary = {}) -> void:
	definition_id = type_id
	visual = visual_data.duplicate(true)
	var minimum := cells[0]
	var maximum := cells[0]
	for cell: Vector2i in cells:
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	sprite_size = sprite_size_for(definition_id, cells, visual)
	global_position = Vector2((minimum.x + maximum.x + 1) * CELL_SIZE * 0.5, (maximum.y + 1) * CELL_SIZE)
	z_as_relative = false
	z_index = roundi(global_position.y)
	queue_redraw()


func _draw() -> void:
	var columns := {"STORAGE_CRATE": 0, "BRICK_KILN": 1, "DWELLING": 2, "SHRINE": 3}
	var economy_columns := {"GRAIN_FARM": 0, "BAKERY": 1, "BREWERY": 2, "KITCHEN": 3, "SAWMILL": 4}
	var industry_columns := {"QUARRY": 0, "COPPER_MINE": 1, "COPPER_SMELTER": 2, "WEAVER": 3, "PAPYRUS_WORKSHOP": 4}
	var destination := Rect2(Vector2(-sprite_size.x * 0.5, -sprite_size.y), sprite_size)
	if not visual.is_empty() and not str(visual.get("texture", "")).is_empty():
		var texture := load(str(visual.texture)) as Texture2D
		var columns_count := maxi(1, int(visual.get("columns", 1)))
		var rows_count := maxi(1, int(visual.get("rows", 1)))
		var column := int(visual.get("column", 0))
		var row := int(visual.get("row", 0))
		var region_size := Vector2(texture.get_width() / float(columns_count), texture.get_height() / float(rows_count))
		draw_texture_rect_region(texture, destination, Rect2(Vector2(column, row) * region_size, region_size))
	elif industry_columns.has(definition_id):
		var cell_width := INDUSTRY_TEXTURE.get_width() / 5.0
		draw_texture_rect_region(INDUSTRY_TEXTURE, destination, Rect2(int(industry_columns[definition_id]) * cell_width, 0, cell_width, INDUSTRY_TEXTURE.get_height()))
	elif economy_columns.has(definition_id):
		var cell_width := ECONOMY_BUILDING_TEXTURE.get_width() / 5.0
		draw_texture_rect_region(ECONOMY_BUILDING_TEXTURE, destination, Rect2(int(economy_columns[definition_id]) * cell_width, 0, cell_width, ECONOMY_BUILDING_TEXTURE.get_height()))
	elif definition_id == "SHRINE":
		draw_texture_rect(SHRINE_TEXTURE, destination, false)
	elif columns.has(definition_id):
		draw_texture_rect_region(BUILDING_TEXTURE, destination, Rect2(int(columns[definition_id]) * 256, 0, 256, 256))
	if machine_running:
		for index in range(3):
			var phase := fmod(effect_time * 16.0 + index * 11.0, 34.0)
			var drift := sin(effect_time * 2.2 + index) * 4.0
			draw_circle(Vector2(sprite_size.x * 0.12 + drift, -sprite_size.y * 0.78 - phase), 4.5 + index, Color(0.92, 0.9, 0.82, 0.52 - index * 0.1))
	elif machine_broken:
		draw_circle(Vector2(sprite_size.x * 0.27, -sprite_size.y * 0.72), 11.0, Color("#8b2f2f"))
		draw_string(ThemeDB.fallback_font, Vector2(sprite_size.x * 0.235, -sprite_size.y * 0.675), "!", HORIZONTAL_ALIGNMENT_CENTER, 10, 18, Color.WHITE)
	if upgrade_level > 1:
		var badge_position := Vector2(sprite_size.x * 0.34, -sprite_size.y + 16.0)
		draw_circle(badge_position, 15.0, Color("#d9ae54"))
		draw_circle(badge_position, 15.0, Color("#fff3d2"), false, 2.0)
		draw_string(ThemeDB.fallback_font, badge_position + Vector2(-10, 6), "L%d" % upgrade_level, HORIZONTAL_ALIGNMENT_CENTER, 20, 15, Color("#30241d"))


static func sprite_size_for(type_id: String, cells: Array[Vector2i], visual_data: Dictionary = {}) -> Vector2:
	if cells.is_empty(): return Vector2.ZERO
	var minimum := cells[0]
	var maximum := cells[0]
	for cell: Vector2i in cells:
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	var footprint_size := Vector2(maximum - minimum + Vector2i.ONE) * CELL_SIZE
	var result := Vector2(maxf(48.0, footprint_size.x + 20.0), maxf(56.0, footprint_size.y + 28.0))
	var authored_size: Array = visual_data.get("size", [])
	if authored_size.size() >= 2:
		result = Vector2(float(authored_size[0]), float(authored_size[1]))
	elif type_id == "GRAIN_FARM":
		result = Vector2(128, 112)
	elif type_id in ["DWELLING", "BAKERY", "BREWERY", "KITCHEN", "SAWMILL", "QUARRY", "COPPER_MINE", "COPPER_SMELTER", "WEAVER", "PAPYRUS_WORKSHOP"]:
		result *= 2.0
	elif type_id == "SHRINE":
		result = Vector2(maxf(112.0, footprint_size.x + 36.0), maxf(116.0, footprint_size.y + 20.0)) * 2.0
	if visual_data.has("scale"): result *= float(visual_data.scale)
	return result
