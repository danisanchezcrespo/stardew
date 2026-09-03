class_name MainGame
extends Node2D

const PlayerScene = preload("res://player/player.tscn")

const CELL_SIZE := 32
const WORLD_SIZE := Vector2i(50, 30)
const WORLD_PIXELS := Vector2(WORLD_SIZE * CELL_SIZE)
const SAND := Color("#cdbb7d")
const WATER := Color("#4d8fbd")
const GRID_LINE := Color(0.16, 0.14, 0.10, 0.18)

var player: CharacterBody2D
var position_label: Label
var water_cells: Dictionary = {}


func _ready() -> void:
	_build_terrain()
	_build_boundaries()
	_build_player()
	_build_hud()
	queue_redraw()


func _process(_delta: float) -> void:
	if player != null and position_label != null:
		var cell := Vector2i(floori(player.position.x / CELL_SIZE), floori(player.position.y / CELL_SIZE))
		position_label.text = "Cell %s    Facing: %s" % [str(cell), player.facing]


func _build_terrain() -> void:
	for y in range(4, 26):
		for x in range(34, 40):
			water_cells[Vector2i(x, y)] = true
	for x in range(8, 18):
		water_cells[Vector2i(x, 10)] = true
	water_cells.erase(Vector2i(13, 10))
	water_cells.erase(Vector2i(14, 10))
	for cell: Vector2i in water_cells:
		_add_static_rect(Vector2(cell * CELL_SIZE) + Vector2.ONE * 16.0, Vector2.ONE * CELL_SIZE, "Water")


func _build_boundaries() -> void:
	_add_static_rect(Vector2(WORLD_PIXELS.x * 0.5, -16), Vector2(WORLD_PIXELS.x + 64, 32), "NorthBoundary")
	_add_static_rect(Vector2(WORLD_PIXELS.x * 0.5, WORLD_PIXELS.y + 16), Vector2(WORLD_PIXELS.x + 64, 32), "SouthBoundary")
	_add_static_rect(Vector2(-16, WORLD_PIXELS.y * 0.5), Vector2(32, WORLD_PIXELS.y + 64), "WestBoundary")
	_add_static_rect(Vector2(WORLD_PIXELS.x + 16, WORLD_PIXELS.y * 0.5), Vector2(32, WORLD_PIXELS.y + 64), "EastBoundary")


func _add_static_rect(center: Vector2, rectangle_size: Vector2, body_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = body_name
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rectangle_size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _build_player() -> void:
	player = PlayerScene.instantiate()
	player.position = Vector2(6.5, 6.5) * CELL_SIZE
	add_child(player)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_PIXELS.x)
	camera.limit_bottom = int(WORLD_PIXELS.y)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var background := ColorRect.new()
	background.position = Vector2(18, 16)
	background.size = Vector2(360, 76)
	background.color = Color(0.08, 0.09, 0.11, 0.86)
	layer.add_child(background)
	var title := Label.new()
	title.position = Vector2(34, 26)
	title.text = "STARDew - Player movement prototype"
	title.add_theme_font_size_override("font_size", 18)
	layer.add_child(title)
	position_label = Label.new()
	position_label.position = Vector2(34, 58)
	position_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(position_label)
	var help := Label.new()
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(22, -54)
	help.text = "Move: WASD / arrows / left stick"
	help.add_theme_color_override("font_color", Color.WHITE)
	help.add_theme_font_size_override("font_size", 16)
	layer.add_child(help)


func _draw() -> void:
	for y in range(WORLD_SIZE.y):
		for x in range(WORLD_SIZE.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * CELL_SIZE), Vector2.ONE * CELL_SIZE)
			draw_rect(rect, WATER if water_cells.has(cell) else SAND)
			draw_rect(rect, GRID_LINE, false, 1.0)
