class_name DependentActor
extends Node2D

const CELL_SIZE := 96.0

var stable_id := ""
var species_id := ""
var display_name := "Animal"
var home_id := ""
var home_position := Vector2.ZERO
var feed_item := "grain"
var drink_item := "water"
var product_item := "egg"
var harvest_outputs: Dictionary = {}
var hunger := 70.0
var thirst := 70.0
var health := 100.0
var age_seconds := 0.0
var mature_seconds := 90.0
var product_interval := 45.0
var product_elapsed := 0.0
var stored_product := 0
var wander_radius := 38.0
var wander_target := Vector2.ZERO
var texture: Texture2D
var juvenile_row := 1
var adult_row := 0
var facing_column := 0
var target_kind := "dependent"
var targeted := false
var harvest_armed := false
var cared_for := false
var wild := false
var required_tool := ""
var sprite_columns := 4
var sprite_rows := 4
var adult_size := Vector2(62, 62)
var juvenile_size := Vector2(42, 42)


func configure(id: String, definition: Dictionary, dwelling_id: String, spawn_position: Vector2) -> void:
	stable_id = id
	species_id = str(definition.get("id", "dependent"))
	display_name = str(definition.get("label", species_id.capitalize()))
	home_id = dwelling_id
	home_position = spawn_position
	position = spawn_position
	feed_item = str(definition.get("feed_item", "grain"))
	drink_item = str(definition.get("drink_item", "water"))
	product_item = str(definition.get("product_item", ""))
	harvest_outputs = definition.get("harvest_outputs", {}).duplicate(true)
	mature_seconds = float(definition.get("mature_seconds", 90.0))
	product_interval = float(definition.get("product_interval", 45.0))
	wander_radius = float(definition.get("wander_radius", 38.0))
	wild = bool(definition.get("wild", false))
	required_tool = str(definition.get("required_tool", ""))
	sprite_columns = maxi(1, int(definition.get("sprite_columns", 4)))
	sprite_rows = maxi(1, int(definition.get("sprite_rows", 4)))
	var configured_size: Array = definition.get("adult_size", [62, 62])
	adult_size = Vector2(float(configured_size[0]), float(configured_size[1]))
	var configured_juvenile_size: Array = definition.get("juvenile_size", [42, 42])
	juvenile_size = Vector2(float(configured_juvenile_size[0]), float(configured_juvenile_size[1]))
	texture = load(str(definition.get("texture", "res://assets/generated/animals/livestock.png"))) as Texture2D
	juvenile_row = int(definition.get("juvenile_row", 1))
	adult_row = int(definition.get("adult_row", 0))
	wander_target = home_position
	z_as_relative = false
	queue_redraw()


func process_life(game: Node2D, delta: float) -> void:
	cared_for = wild or game.assigned_villagers_to(home_id) > 0
	if wild:
		hunger = 100.0
		thirst = 100.0
	hunger = maxf(0.0, hunger - delta * 0.18)
	thirst = maxf(0.0, thirst - delta * 0.24)
	health = clampf(health + delta * (0.08 if hunger > 20.0 and thirst > 20.0 else -0.22), 0.0, 100.0)
	if cared_for and hunger > 0.0 and thirst > 0.0: age_seconds += delta
	if cared_for and is_mature() and hunger > 25.0 and thirst > 25.0 and not product_item.is_empty():
		product_elapsed += delta
		if product_elapsed >= product_interval:
			product_elapsed = 0.0
			stored_product = mini(5, stored_product + 1)
	if position.distance_to(wander_target) < 3.0:
		var phase := age_seconds * 1.71 + float(stable_id.hash() % 31)
		wander_target = home_position + Vector2(cos(phase), sin(phase * 1.37)) * wander_radius
	var offset := wander_target - position
	if offset.length() > 2.0:
		var direction := offset.normalized()
		position += direction * minf(delta * (18.0 if is_mature() else 24.0), offset.length())
		facing_column = 0 if direction.x < -0.35 else (1 if direction.x > 0.35 else (2 if direction.y > 0 else 3))
	z_index = roundi(global_position.y)
	queue_redraw()


func is_mature() -> bool:
	return age_seconds >= mature_seconds


func feed(item_id: String, amount: int = 1) -> int:
	if item_id == feed_item and hunger < 96.0 and amount > 0:
		hunger = minf(100.0, hunger + 40.0)
		return 1
	if item_id == drink_item and thirst < 96.0 and amount > 0:
		thirst = minf(100.0, thirst + 50.0)
		return 1
	return 0


func interaction_position() -> Vector2: return global_position
func is_interactable() -> bool: return health > 0.0
func set_targeted(value: bool) -> void: targeted = value; queue_redraw()


func status_text() -> String:
	var stage := "adult" if is_mature() else "young - %d%%" % roundi(age_seconds / mature_seconds * 100.0)
	if wild: return "%s\nWild animal - Health %d%%\nRequired: %s" % [display_name, roundi(health), required_tool.capitalize()]
	var product_status := "\n%s ready: %d" % [product_item.capitalize(), stored_product] if not product_item.is_empty() else ""
	return "%s\n%s - %s\nFood %d%% - Water %d%% - Health %d%%%s" % [display_name, stage, "cared for" if cared_for else "needs assigned keeper", roundi(hunger), roundi(thirst), roundi(health), product_status]


func _draw() -> void:
	if texture == null: return
	var row := adult_row if is_mature() else juvenile_row
	var source_size := Vector2(texture.get_width() / float(sprite_columns), texture.get_height() / float(sprite_rows))
	var size := adult_size if is_mature() else juvenile_size
	facing_column = clampi(facing_column, 0, sprite_columns - 1)
	draw_texture_rect_region(texture, Rect2(Vector2(-size.x * 0.5, -size.y + 8), size), Rect2(Vector2(facing_column, row) * source_size, source_size))
	if targeted: draw_circle(Vector2(0, 9), 18.0, Color("#ffe27a"), false, 3.0)
	if hunger < 20.0 or thirst < 20.0: draw_string(ThemeDB.fallback_font, Vector2(-5, -58), "!", HORIZONTAL_ALIGNMENT_CENTER, 12, 18, Color("#ff8066"))
