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
var authored_sprite: Sprite2D
var targeted := false

const OUTLINE_SHADER := """
shader_type canvas_item;
uniform bool highlighted = false;
uniform vec4 outline_color : source_color = vec4(1.0);
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	if (highlighted && base.a < 0.05) {
		vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
		float near_alpha = max(max(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a), max(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a));
		if (near_alpha > 0.05) base = outline_color;
	}
	COLOR = base;
}
"""


func set_upgrade_level(level: int) -> void:
	upgrade_level = clampi(level, 1, 4)
	queue_redraw()


func set_machine_state(running: bool, broken: bool, delta: float) -> void:
	machine_running = running
	machine_broken = broken
	queue_redraw()


func set_targeted(value: bool) -> void:
	targeted = value
	if authored_sprite != null and authored_sprite.material is ShaderMaterial:
		(authored_sprite.material as ShaderMaterial).set_shader_parameter("highlighted", value)
	queue_redraw()


func _process(delta: float) -> void:
	var ambient := definition_id in ["DECOR_ROSES","DECOR_BLUEBELLS","DECOR_SUNFLOWERS","DECOR_LAVENDER","DECOR_TOPIARY","DECOR_TRELLIS","DECOR_HERB_POTS","DECOR_CHERRY_TREE","DECOR_ANGEL_FOUNTAIN","DECOR_BIRDBATH","CHICKEN_COOP"]
	if not machine_running and not ambient: return
	effect_time += maxf(delta, 0.0)
	if authored_sprite != null and definition_id in ["DECOR_ROSES","DECOR_BLUEBELLS","DECOR_SUNFLOWERS","DECOR_LAVENDER","DECOR_TOPIARY","DECOR_TRELLIS","DECOR_HERB_POTS","DECOR_CHERRY_TREE"]:
		authored_sprite.rotation = sin(effect_time * 1.25 + global_position.x * 0.01) * 0.012
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
	_build_authored_sprite()
	queue_redraw()


func _build_authored_sprite() -> void:
	var texture: Texture2D
	var columns_count := 1
	var rows_count := 1
	var column := 0
	var row := 0
	if not visual.is_empty() and not str(visual.get("texture", "")).is_empty():
		texture = load(str(visual.texture)) as Texture2D
		columns_count = maxi(1, int(visual.get("columns", 1)))
		rows_count = maxi(1, int(visual.get("rows", 1)))
		column = int(visual.get("column", 0))
		row = int(visual.get("row", 0))
	else:
		var base_columns := {"STORAGE_CRATE": 0, "BRICK_KILN": 1, "DWELLING": 2}
		var economy_columns := {"GRAIN_FARM": 0, "BAKERY": 1, "BREWERY": 2, "KITCHEN": 3, "SAWMILL": 4}
		var industry_columns := {"QUARRY": 0, "COPPER_MINE": 1, "COPPER_SMELTER": 2, "WEAVER": 3, "PAPYRUS_WORKSHOP": 4}
		if base_columns.has(definition_id): texture = BUILDING_TEXTURE; columns_count = 4; column = int(base_columns[definition_id])
		elif economy_columns.has(definition_id): texture = ECONOMY_BUILDING_TEXTURE; columns_count = 5; column = int(economy_columns[definition_id])
		elif industry_columns.has(definition_id): texture = INDUSTRY_TEXTURE; columns_count = 5; column = int(industry_columns[definition_id])
		elif definition_id == "SHRINE": texture = SHRINE_TEXTURE
	if texture == null: return
	authored_sprite = Sprite2D.new()
	authored_sprite.texture = texture
	var region_size := Vector2(texture.get_width() / float(columns_count), texture.get_height() / float(rows_count))
	if columns_count > 1 or rows_count > 1:
		authored_sprite.region_enabled = true
		authored_sprite.region_rect = Rect2(Vector2(column, row) * region_size, region_size)
	authored_sprite.position = Vector2(0.0, -sprite_size.y * 0.5)
	authored_sprite.scale = sprite_size / region_size
	var outline_material := ShaderMaterial.new()
	var outline_shader := Shader.new()
	outline_shader.code = OUTLINE_SHADER
	outline_material.shader = outline_shader
	outline_material.set_shader_parameter("highlighted", targeted)
	authored_sprite.material = outline_material
	add_child(authored_sprite)


func _draw() -> void:
	var columns := {"STORAGE_CRATE": 0, "BRICK_KILN": 1, "DWELLING": 2, "SHRINE": 3}
	var economy_columns := {"GRAIN_FARM": 0, "BAKERY": 1, "BREWERY": 2, "KITCHEN": 3, "SAWMILL": 4}
	var industry_columns := {"QUARRY": 0, "COPPER_MINE": 1, "COPPER_SMELTER": 2, "WEAVER": 3, "PAPYRUS_WORKSHOP": 4}
	var destination := Rect2(Vector2(-sprite_size.x * 0.5, -sprite_size.y), sprite_size)
	if authored_sprite != null:
		pass
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
		_draw_working_delight()
	elif machine_broken:
		draw_circle(Vector2(sprite_size.x * 0.27, -sprite_size.y * 0.72), 11.0, Color("#8b2f2f"))
		draw_string(ThemeDB.fallback_font, Vector2(sprite_size.x * 0.235, -sprite_size.y * 0.675), "!", HORIZONTAL_ALIGNMENT_CENTER, 10, 18, Color.WHITE)
	if upgrade_level > 1:
		var badge_position := Vector2(sprite_size.x * 0.34, -sprite_size.y + 16.0)
		draw_circle(badge_position, 15.0, Color("#d9ae54"))
		draw_circle(badge_position, 15.0, Color("#fff3d2"), false, 2.0)
		draw_string(ThemeDB.fallback_font, badge_position + Vector2(-10, 6), "L%d" % upgrade_level, HORIZONTAL_ALIGNMENT_CENTER, 20, 15, Color("#30241d"))
	_draw_ambient_delight()


func _draw_working_delight() -> void:
	if definition_id == "WINDMILL":
		var hub := Vector2(4, -sprite_size.y * 0.62); var angle := effect_time * 2.4
		for index in range(4):
			var direction := Vector2.RIGHT.rotated(angle + index * PI * 0.5)
			draw_line(hub, hub + direction * 42.0, Color("#f2ddb0"), 7.0); draw_line(hub + direction * 12.0, hub + direction * 42.0, Color("#6f4a2c"), 2.0)
		draw_circle(hub, 7.0, Color("#8a5b30"))
	elif definition_id == "FORGE":
		var fire := Vector2(sprite_size.x * 0.17, -sprite_size.y * 0.34)
		draw_circle(fire, 10.0 + sin(effect_time * 13.0) * 2.0, Color("#ff7a2f")); draw_circle(fire + Vector2(0,2), 5.0, Color("#ffe36e"))
		_draw_tiny_worker(fire + Vector2(-32, -4), absf(sin(effect_time * 5.5)))
		for index in range(5):
			var spark := Vector2(fmod(index * 13.0 + effect_time * 34.0, 45.0) - 18.0, -fmod(index * 9.0 + effect_time * 28.0, 34.0))
			draw_circle(fire + spark, 1.5, Color("#ffd36a"))
	elif definition_id == "SCULPTOR_WORKSHOP":
		var bench := Vector2(-sprite_size.x * 0.12, -sprite_size.y * 0.25); var strike := absf(sin(effect_time * 5.0))
		_draw_tiny_worker(bench + Vector2(-20, -2), strike)
		draw_line(bench + Vector2(12,-25), bench + Vector2(-4 + strike * 12,-4), Color("#6b4528"), 4.0)
		for index in range(3): draw_circle(bench + Vector2(index * 9 - 8, -index * 5 - fmod(effect_time * 8.0, 8.0)), 2.0, Color(0.8,0.77,0.68,0.65))
	elif definition_id == "GARDEN_NURSERY" or definition_id == "HERB_GARDEN":
		for index in range(7):
			var drop := Vector2(-45 + index * 15, -35 + fmod(effect_time * 24.0 + index * 11.0, 28.0))
			draw_line(drop, drop + Vector2(-2,5), Color(0.55,0.82,1.0,0.7), 2.0)
	elif definition_id == "APIARY":
		for index in range(8):
			var bee := Vector2(sin(effect_time * 2.2 + index) * (34 + index * 2), -55 + cos(effect_time * 2.8 + index * 1.7) * 22)
			draw_circle(bee, 2.5, Color("#f3c64f")); draw_line(bee - Vector2(2,0), bee + Vector2(2,0), Color("#3a2b1e"), 1.0)
	elif definition_id in ["BAKERY","KITCHEN"]:
		var glow := Vector2(sprite_size.x * 0.12, -sprite_size.y * 0.3); draw_circle(glow, 7.0 + sin(effect_time * 9.0), Color(1.0,0.48,0.18,0.72))


func _draw_tiny_worker(origin: Vector2, strike: float) -> void:
	draw_circle(origin + Vector2(0, -22), 6.0, Color("#d6a06c"))
	draw_rect(Rect2(origin + Vector2(-6, -16), Vector2(12, 17)), Color("#446b8c"), true)
	var hand := origin + Vector2(7 + strike * 8.0, -13 + strike * 12.0)
	draw_line(origin + Vector2(4, -13), hand, Color("#d6a06c"), 4.0)
	draw_line(hand, hand + Vector2(7, -9), Color("#65452f"), 3.0)


func _draw_ambient_delight() -> void:
	if definition_id in ["DECOR_ANGEL_FOUNTAIN","DECOR_BIRDBATH"]:
		for index in range(4):
			var phase := fmod(effect_time * 18.0 + index * 7.0, 24.0)
			draw_circle(Vector2(index * 5 - 8, -sprite_size.y * 0.38 - phase * 0.25), 1.8, Color(0.68,0.9,1.0,0.78))
	if definition_id == "CHICKEN_COOP":
		for index in range(3):
			var peck := Vector2(-25 + index * 22 + sin(effect_time * 2.0 + index) * 5.0, -13 + cos(effect_time * 4.0 + index) * 2.0)
			draw_circle(peck, 3.0, Color("#f2e4bc")); draw_circle(peck + Vector2(3,-1), 1.2, Color("#d86a34"))


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
