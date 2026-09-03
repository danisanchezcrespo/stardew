class_name WorldDebugLab
extends Node2D

const InputDefaultsType = preload("res://input/input_defaults.gd")
const WorldGridType = preload("res://world/placement/world_grid.gd")
const FootprintType = preload("res://world/spatial/spatial_footprint.gd")

const CELL_SIZE := 32
const GRID_SIZE := Vector2i(20, 14)
const GRID_OFFSET := Vector2(48, 88)
const SAND := Color("#cdbb7d")
const WATER := Color("#4d8fbd")
const GRID_LINE := Color(0.16, 0.14, 0.10, 0.35)
const VALID_PREVIEW := Color(0.25, 0.9, 0.45, 0.55)
const INVALID_PREVIEW := Color(0.95, 0.25, 0.22, 0.62)

var world: Variant
var blueprints: Array[Dictionary] = []
var selected_index := 0
var cursor_cell := Vector2i(3, 3)
var blueprint_rotation := 0
var next_instance_number := 1
var status_label: Label
var selection_label: Label
var _move_repeat_delay := 0.0


func _ready() -> void:
	InputDefaultsType.ensure_actions()
	_build_model()
	_build_ui()
	_update_feedback()
	queue_redraw()


func _process(delta: float) -> void:
	_move_repeat_delay = maxf(0.0, _move_repeat_delay - delta)
	if _move_repeat_delay > 0.0:
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if movement.length() >= 0.5:
		move_cursor(Vector2i(signi(roundi(movement.x)), signi(roundi(movement.y))))
		_move_repeat_delay = 0.12


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var local: Vector2 = event.position - GRID_OFFSET
		var hovered := Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))
		if world.contains(hovered) and hovered != cursor_cell:
			cursor_cell = hovered
			_update_feedback()
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_selected()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_at_cursor()
	elif event.is_action_pressed("interact"):
		place_selected()
	elif event.is_action_pressed("rotate_blueprint"):
		rotate_selected()
	elif event.is_action_pressed("remove_placed"):
		remove_at_cursor()
	elif event.is_action_pressed("select_previous"):
		select_blueprint(-1)
	elif event.is_action_pressed("select_next"):
		select_blueprint(1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			selected_index = int(event.keycode - KEY_1)
			blueprint_rotation = 0
			_update_feedback()
			queue_redraw()


func _build_model() -> void:
	world = WorldGridType.new(GRID_SIZE, "sand")
	for y in range(2, 12):
		world.set_terrain(Vector2i(15, y), "water")
		world.set_terrain(Vector2i(16, y), "water")
	blueprints = [
		{
			"id": "STORAGE_CRATE",
			"label": "Storage crate (1x1)",
			"color": Color("#8a5a35"),
			"footprint": FootprintType.new([Vector2i.ZERO], {"use": Vector2i(0, 1)}),
			"terrain": ["sand"],
		},
		{
			"id": "CRAFTING_BENCH",
			"label": "Crafting bench (2x1)",
			"color": Color("#d18b47"),
			"footprint": FootprintType.new([Vector2i.ZERO, Vector2i.RIGHT], {"use": Vector2i(0, 1)}),
			"terrain": ["sand"],
		},
		{
			"id": "BRICK_KILN",
			"label": "Brick kiln (L shape)",
			"color": Color("#a94f32"),
			"footprint": FootprintType.new([Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN], {"input": Vector2i(-1, 0), "output": Vector2i(1, 1)}),
			"terrain": ["sand"],
		},
	]


func _build_ui() -> void:
	var title := Label.new()
	title.position = Vector2(48, 24)
	title.text = "STARDew - Physical world lab"
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)

	var panel := ColorRect.new()
	panel.position = Vector2(720, 88)
	panel.size = Vector2(500, 448)
	panel.color = Color("#20242b")
	add_child(panel)

	selection_label = Label.new()
	selection_label.position = Vector2(744, 112)
	selection_label.add_theme_font_size_override("font_size", 20)
	add_child(selection_label)

	status_label = Label.new()
	status_label.position = Vector2(744, 160)
	status_label.size = Vector2(440, 90)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 18)
	add_child(status_label)

	var help := Label.new()
	help.position = Vector2(744, 268)
	help.size = Vector2(440, 240)
	help.text = "Move cursor: WASD / arrows / left stick\nPlace: E / Space / Enter / A / left click\nRotate: R / right shoulder\nRemove: X / Delete / X button / right click\nBlueprint: Q/F / left shoulder/Y / keys 1-3\n\nBlue cells are water and reject these sample objects."
	help.add_theme_font_size_override("font_size", 16)
	add_child(help)


func move_cursor(delta: Vector2i) -> void:
	if delta == Vector2i.ZERO:
		return
	cursor_cell = Vector2i(
		clampi(cursor_cell.x + delta.x, 0, GRID_SIZE.x - 1),
		clampi(cursor_cell.y + delta.y, 0, GRID_SIZE.y - 1)
	)
	_update_feedback()
	queue_redraw()


func select_blueprint(direction: int) -> void:
	selected_index = posmod(selected_index + direction, blueprints.size())
	blueprint_rotation = 0
	_update_feedback()
	queue_redraw()


func rotate_selected() -> void:
	blueprint_rotation = posmod(blueprint_rotation + 1, 4)
	_update_feedback()
	queue_redraw()


func place_selected() -> bool:
	var blueprint := blueprints[selected_index]
	var result: Variant = world.place(
		"debug-%04d" % next_instance_number,
		blueprint.id,
		blueprint.footprint,
		cursor_cell,
		blueprint_rotation,
		_typed_terrain(blueprint.terrain)
	)
	if not result.valid:
		_update_feedback()
		queue_redraw()
		return false
	next_instance_number += 1
	_update_feedback()
	queue_redraw()
	return true


func remove_at_cursor() -> bool:
	var occupant: String = world.occupant_at(cursor_cell)
	if occupant.is_empty():
		_update_feedback("Nothing to remove at %s." % str(cursor_cell))
		return false
	world.remove(occupant)
	_update_feedback("Removed %s." % occupant)
	queue_redraw()
	return true


func _placement_result() -> Variant:
	var blueprint := blueprints[selected_index]
	return world.query_placement(blueprint.footprint, cursor_cell, blueprint_rotation, _typed_terrain(blueprint.terrain))


func _typed_terrain(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		result.append(str(value))
	return result


func _update_feedback(override_status: String = "") -> void:
	if selection_label == null or status_label == null:
		return
	var blueprint := blueprints[selected_index]
	selection_label.text = "%d. %s | rotation %d deg" % [selected_index + 1, blueprint.label, blueprint_rotation * 90]
	if not override_status.is_empty():
		status_label.text = override_status
		return
	var result: Variant = _placement_result()
	status_label.text = (
		"Cell %s - valid placement" % str(cursor_cell)
		if result.valid
		else "Cell %s - blocked: %s" % [str(cursor_cell), result.reason]
	)


func _draw() -> void:
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(GRID_OFFSET + Vector2(cell * CELL_SIZE), Vector2.ONE * CELL_SIZE)
			draw_rect(rect, WATER if world.terrain_at(cell) == "water" else SAND)
			draw_rect(rect, GRID_LINE, false, 1.0)

	for placed: Variant in world.entities_by_id.values():
		var blueprint: Dictionary = _blueprint_by_id(placed.definition_id)
		for cell: Vector2i in placed.cells:
			var rect := Rect2(GRID_OFFSET + Vector2(cell * CELL_SIZE) + Vector2.ONE * 2.0, Vector2.ONE * (CELL_SIZE - 4))
			draw_rect(rect, blueprint.color)
		var ports: Dictionary = blueprint.footprint.transformed_ports(placed.origin, placed.rotation)
		for port_cell: Vector2i in ports.values():
			draw_circle(GRID_OFFSET + Vector2(port_cell * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5), 5.0, Color.WHITE)

	var preview: Variant = _placement_result()
	for cell: Vector2i in preview.cells:
		var rect := Rect2(GRID_OFFSET + Vector2(cell * CELL_SIZE) + Vector2.ONE, Vector2.ONE * (CELL_SIZE - 2))
		draw_rect(rect, VALID_PREVIEW if preview.valid else INVALID_PREVIEW)
		draw_rect(rect, Color.WHITE, false, 2.0)

	var cursor_rect := Rect2(GRID_OFFSET + Vector2(cursor_cell * CELL_SIZE), Vector2.ONE * CELL_SIZE)
	draw_rect(cursor_rect, Color("#fff29a"), false, 3.0)


func _blueprint_by_id(definition_id: String) -> Dictionary:
	for blueprint: Dictionary in blueprints:
		if blueprint.id == definition_id:
			return blueprint
	return blueprints[0]
