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


func set_machine_state(running: bool, broken: bool, delta: float) -> void:
	machine_running = running
	machine_broken = broken
	if running: effect_time += maxf(delta, 0.0)
	queue_redraw()


func configure(type_id: String, cells: Array[Vector2i]) -> void:
	definition_id = type_id
	var minimum := cells[0]
	var maximum := cells[0]
	for cell: Vector2i in cells:
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	var footprint_size := Vector2(maximum - minimum + Vector2i.ONE) * CELL_SIZE
	sprite_size = Vector2(maxf(48.0, footprint_size.x + 20.0), maxf(56.0, footprint_size.y + 28.0))
	if definition_id in ["DWELLING", "BAKERY", "BREWERY", "KITCHEN", "SAWMILL", "QUARRY", "COPPER_MINE", "COPPER_SMELTER", "WEAVER", "PAPYRUS_WORKSHOP"]:
		sprite_size *= 2.0
	elif definition_id == "SHRINE":
		# The temple art is nearly square; preserve that authored 3/4 projection.
		sprite_size = Vector2(maxf(112.0, footprint_size.x + 36.0), maxf(116.0, footprint_size.y + 20.0)) * 2.0
	global_position = Vector2((minimum.x + maximum.x + 1) * CELL_SIZE * 0.5, (maximum.y + 1) * CELL_SIZE)
	z_as_relative = false
	z_index = roundi(global_position.y)
	queue_redraw()


func _draw() -> void:
	var columns := {"STORAGE_CRATE": 0, "BRICK_KILN": 1, "DWELLING": 2, "SHRINE": 3}
	var economy_columns := {"GRAIN_FARM": 0, "BAKERY": 1, "BREWERY": 2, "KITCHEN": 3, "SAWMILL": 4}
	var industry_columns := {"QUARRY": 0, "COPPER_MINE": 1, "COPPER_SMELTER": 2, "WEAVER": 3, "PAPYRUS_WORKSHOP": 4}
	var destination := Rect2(Vector2(-sprite_size.x * 0.5, -sprite_size.y), sprite_size)
	if industry_columns.has(definition_id):
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
