class_name MainGame
extends Node2D

const PlayerScene = preload("res://player/player.tscn")
const ItemRegistryType = preload("res://items/item_registry.gd")
const PlayerInventoryType = preload("res://player/player_inventory.gd")
const PickupType = preload("res://world/items/world_pickup.gd")
const TargetingType = preload("res://world/interaction/interaction_targeting.gd")

const CELL_SIZE := 32
const WORLD_SIZE := Vector2i(50, 30)
const WORLD_PIXELS := Vector2(WORLD_SIZE * CELL_SIZE)
const SAND := Color("#cdbb7d")
const WATER := Color("#4d8fbd")
const GRID_LINE := Color(0.16, 0.14, 0.10, 0.18)
const INTERACTION_REACH_PX := 40.0

var player: CharacterBody2D
var position_label: Label
var interaction_label: Label
var inventory_label: Label
var water_cells: Dictionary = {}
var item_registry: Variant
var inventory: Variant
var pickups: Array = []
var interaction_target: Variant = null


func _ready() -> void:
	_build_terrain()
	_build_boundaries()
	_build_player()
	_build_items()
	_build_hud()
	queue_redraw()


func _process(_delta: float) -> void:
	if player != null and position_label != null:
		var cell := Vector2i(floori(player.position.x / CELL_SIZE), floori(player.position.y / CELL_SIZE))
		position_label.text = "Cell %s    Facing: %s" % [str(cell), player.facing]
	_update_interaction_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		collect_target()


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


func _build_items() -> void:
	item_registry = ItemRegistryType.new()
	var result: Error = item_registry.load_from_path("res://items/items.json")
	assert(result == OK, "Item definitions must load: %s" % str(item_registry.errors))
	inventory = PlayerInventoryType.new(item_registry, 12)
	_spawn_pickup("pickup-wood-1", "wood", 18, Vector2(7.5, 6.5) * CELL_SIZE)
	_spawn_pickup("pickup-clay-1", "clay", 12, Vector2(9.5, 7.5) * CELL_SIZE)
	_spawn_pickup("pickup-grain-1", "grain", 25, Vector2(12.5, 5.5) * CELL_SIZE)
	_spawn_pickup("pickup-wood-2", "wood", 42, Vector2(15.5, 8.5) * CELL_SIZE)


func _spawn_pickup(stable_id: String, item_id: String, amount: int, world_position: Vector2) -> Variant:
	var definition: Variant = item_registry.get_item(item_id)
	assert(definition != null, "Pickup item must exist: %s" % item_id)
	var pickup := PickupType.new()
	pickup.position = world_position
	pickup.configure(stable_id, definition, amount)
	add_child(pickup)
	pickups.append(pickup)
	return pickup


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var background := ColorRect.new()
	background.position = Vector2(18, 16)
	background.size = Vector2(420, 104)
	background.color = Color(0.08, 0.09, 0.11, 0.86)
	layer.add_child(background)
	var title := Label.new()
	title.position = Vector2(34, 26)
	title.text = "STARDew - Pickup and inventory prototype"
	title.add_theme_font_size_override("font_size", 18)
	layer.add_child(title)
	position_label = Label.new()
	position_label.position = Vector2(34, 58)
	position_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(position_label)
	interaction_label = Label.new()
	interaction_label.position = Vector2(34, 82)
	interaction_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(interaction_label)

	var inventory_background := ColorRect.new()
	inventory_background.position = Vector2(16, 634)
	inventory_background.size = Vector2(1248, 64)
	inventory_background.color = Color(0.08, 0.09, 0.11, 0.9)
	layer.add_child(inventory_background)
	inventory_label = Label.new()
	inventory_label.position = Vector2(28, 648)
	inventory_label.size = Vector2(1224, 40)
	inventory_label.add_theme_font_size_override("font_size", 15)
	layer.add_child(inventory_label)
	_update_inventory_hud()
	var help := Label.new()
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(22, -118)
	help.text = "Move: WASD / arrows / left stick    Pick up: E / Space / A button"
	help.add_theme_color_override("font_color", Color.WHITE)
	help.add_theme_font_size_override("font_size", 16)
	layer.add_child(help)


func _update_interaction_target() -> void:
	var active: Array = []
	for pickup: Variant in pickups:
		if is_instance_valid(pickup) and pickup.amount > 0:
			active.append(pickup)
	var selected: Variant = TargetingType.select_target(player.global_position, player.facing, active, INTERACTION_REACH_PX)
	if selected != interaction_target:
		if is_instance_valid(interaction_target):
			interaction_target.set_targeted(false)
		interaction_target = selected
		if interaction_target != null:
			interaction_target.set_targeted(true)
	if interaction_label != null:
		interaction_label.text = (
			"E  Pick up %s x%d" % [interaction_target.item_label, interaction_target.amount]
			if interaction_target != null
			else "Approach a resource stack"
		)


func collect_target() -> int:
	_update_interaction_target()
	if interaction_target == null:
		return 0
	var accepted: int = inventory.add(interaction_target.item_id, interaction_target.amount)
	if accepted <= 0:
		interaction_label.text = "Inventory full"
		return 0
	interaction_target.take(accepted)
	if interaction_target.amount == 0:
		interaction_target.set_targeted(false)
		interaction_target.queue_free()
		interaction_target = null
	_update_inventory_hud()
	return accepted


func _update_inventory_hud() -> void:
	if inventory_label == null:
		return
	var labels: Array[String] = []
	for index in range(inventory.slots.size()):
		var slot: Dictionary = inventory.slots[index]
		if slot.is_empty():
			labels.append("[%d] --" % (index + 1))
		else:
			var definition: Variant = item_registry.get_item(slot.item_id)
			labels.append("[%d] %s x%d" % [index + 1, definition.label, int(slot.amount)])
	inventory_label.text = "   ".join(labels)


func _draw() -> void:
	for y in range(WORLD_SIZE.y):
		for x in range(WORLD_SIZE.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * CELL_SIZE), Vector2.ONE * CELL_SIZE)
			draw_rect(rect, WATER if water_cells.has(cell) else SAND)
			draw_rect(rect, GRID_LINE, false, 1.0)
