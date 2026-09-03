class_name MainGame
extends Node2D

const PlayerScene = preload("res://player/player.tscn")
const ItemRegistryType = preload("res://items/item_registry.gd")
const PlayerInventoryType = preload("res://player/player_inventory.gd")
const PickupType = preload("res://world/items/world_pickup.gd")
const TargetingType = preload("res://world/interaction/interaction_targeting.gd")
const RecipeRegistryType = preload("res://crafting/recipe_registry.gd")
const CraftingSystemType = preload("res://crafting/crafting_system.gd")
const DefinitionRegistryType = preload("res://simulation/definitions/simulation_definition_registry.gd")
const WorldGridType = preload("res://world/placement/world_grid.gd")
const PlacedTargetType = preload("res://world/placement/placed_object_target.gd")
const ConstructionSiteType = preload("res://world/construction/construction_site.gd")

const CELL_SIZE := 32
const WORLD_SIZE := Vector2i(50, 30)
const WORLD_PIXELS := Vector2(WORLD_SIZE * CELL_SIZE)
const SAND := Color("#cdbb7d")
const WATER := Color("#4d8fbd")
const GRID_LINE := Color(0.16, 0.14, 0.10, 0.18)
const INTERACTION_REACH_PX := 40.0
const PLACEMENT_RANGE_CELLS := 4.0

var player: CharacterBody2D
var position_label: Label
var interaction_label: Label
var inventory_label: Label
var water_cells: Dictionary = {}
var item_registry: Variant
var inventory: Variant
var pickups: Array = []
var interaction_target: Variant = null
var recipe_registry: Variant
var crafting: Variant
var crafting_open := false
var selected_recipe_index := 0
var crafting_panel: Control
var crafting_list_label: Label
var crafting_detail_label: Label
var placement_registry: Variant
var world_grid: Variant
var selected_slot := 0
var placement_mode := false
var placement_cursor := Vector2i.ZERO
var placement_rotation := 0
var next_placed_id := 1
var placement_feedback := ""
var placed_targets: Dictionary = {}
var storage_by_entity_id: Dictionary = {}
var storage_open := false
var active_storage_id := ""
var selected_storage_slot := 0
var storage_panel: Control
var storage_player_label: Label
var storage_contents_label: Label
var storage_feedback_label: Label
var construction_by_entity_id: Dictionary = {}


func _ready() -> void:
	_build_terrain()
	_build_boundaries()
	_build_player()
	_build_items()
	_build_hud()
	queue_redraw()


func _process(delta: float) -> void:
	if player != null and position_label != null:
		var cell := Vector2i(floori(player.position.x / CELL_SIZE), floori(player.position.y / CELL_SIZE))
		position_label.text = "Cell %s    Facing: %s" % [str(cell), player.facing]
	_update_interaction_target()
	if (
		interaction_target != null
		and interaction_target.target_kind == "construction"
		and Input.is_action_pressed("use_selected")
	):
		apply_construction_work(interaction_target.stable_id, delta)


func _unhandled_input(event: InputEvent) -> void:
	if storage_open:
		if event.is_action_pressed("cancel") or event.is_action_pressed("open_crafting"):
			close_storage()
		elif event.is_action_pressed("menu_up"):
			select_storage_slot(-1)
		elif event.is_action_pressed("menu_down"):
			select_storage_slot(1)
		elif event.is_action_pressed("interact"):
			deposit_selected_stack()
		elif event.is_action_pressed("use_selected"):
			withdraw_selected_stack()
		return
	if placement_mode:
		if event is InputEventMouseMotion:
			var mouse_world := get_global_mouse_position()
			var hovered := Vector2i(floori(mouse_world.x / CELL_SIZE), floori(mouse_world.y / CELL_SIZE))
			if world_grid.contains(hovered) and hovered != placement_cursor:
				placement_cursor = hovered
				_update_placement_feedback()
				queue_redraw()
		elif event.is_action_pressed("cancel"):
			cancel_placement()
		elif event.is_action_pressed("rotate_blueprint"):
			rotate_placement()
		elif event.is_action_pressed("move_left"):
			move_placement_cursor(Vector2i.LEFT)
		elif event.is_action_pressed("move_right"):
			move_placement_cursor(Vector2i.RIGHT)
		elif event.is_action_pressed("move_up"):
			move_placement_cursor(Vector2i.UP)
		elif event.is_action_pressed("move_down"):
			move_placement_cursor(Vector2i.DOWN)
		elif event.is_action_pressed("use_selected") or event.is_action_pressed("interact"):
			confirm_placement()
		return
	if event.is_action_pressed("open_crafting"):
		set_crafting_open(not crafting_open)
	elif crafting_open and event.is_action_pressed("cancel"):
		set_crafting_open(false)
	elif crafting_open and event.is_action_pressed("menu_up"):
		select_recipe(-1)
	elif crafting_open and event.is_action_pressed("menu_down"):
		select_recipe(1)
	elif crafting_open and event.is_action_pressed("interact"):
		craft_selected_recipe()
	elif not crafting_open and event.is_action_pressed("interact"):
		collect_target()
	elif not crafting_open and event.is_action_pressed("use_selected"):
		if interaction_target != null and interaction_target.target_kind == "construction":
			apply_construction_work(interaction_target.stable_id, 0.1)
		else:
			begin_placement()
	elif not crafting_open and event.is_action_pressed("quick_previous"):
		select_quick_slot(selected_slot - 1)
	elif not crafting_open and event.is_action_pressed("quick_next"):
		select_quick_slot(selected_slot + 1)
	elif not crafting_open:
		for index in range(8):
			if event.is_action_pressed("quick_slot_%d" % (index + 1)):
				select_quick_slot(index)
				break


func _build_terrain() -> void:
	world_grid = WorldGridType.new(WORLD_SIZE, "sand")
	for y in range(4, 26):
		for x in range(34, 40):
			water_cells[Vector2i(x, y)] = true
	for x in range(8, 18):
		water_cells[Vector2i(x, 10)] = true
	water_cells.erase(Vector2i(13, 10))
	water_cells.erase(Vector2i(14, 10))
	for cell: Vector2i in water_cells:
		world_grid.set_terrain(cell, "water")
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
	recipe_registry = RecipeRegistryType.new()
	result = recipe_registry.load_from_path("res://crafting/recipes.json", item_registry)
	assert(result == OK, "Recipe definitions must load: %s" % str(recipe_registry.errors))
	crafting = CraftingSystemType.new(recipe_registry)
	placement_registry = DefinitionRegistryType.new()
	result = placement_registry.load_from_path("res://world/placeables.json")
	assert(result == OK, "Placeable definitions must load: %s" % str(placement_registry.errors))
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
	title.text = "STARDew - Craft and place prototype"
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
	_build_crafting_panel(layer)
	_build_storage_panel(layer)
	var help := Label.new()
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(22, -118)
	help.text = "Move/Pick up: WASD + E/A    Craft: C/Y    Select: 1-8 or Q/F    Use/place: Space/X/click"
	help.add_theme_color_override("font_color", Color.WHITE)
	help.add_theme_font_size_override("font_size", 16)
	layer.add_child(help)


func _build_crafting_panel(layer: CanvasLayer) -> void:
	crafting_panel = ColorRect.new()
	crafting_panel.position = Vector2(360, 150)
	crafting_panel.size = Vector2(560, 390)
	crafting_panel.color = Color(0.06, 0.07, 0.09, 0.96)
	crafting_panel.visible = false
	layer.add_child(crafting_panel)
	var title := Label.new()
	title.position = Vector2(24, 20)
	title.text = "CRAFTING"
	title.add_theme_font_size_override("font_size", 24)
	crafting_panel.add_child(title)
	crafting_list_label = Label.new()
	crafting_list_label.position = Vector2(24, 70)
	crafting_list_label.size = Vector2(250, 260)
	crafting_list_label.add_theme_font_size_override("font_size", 18)
	crafting_panel.add_child(crafting_list_label)
	crafting_detail_label = Label.new()
	crafting_detail_label.position = Vector2(290, 70)
	crafting_detail_label.size = Vector2(240, 260)
	crafting_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crafting_detail_label.add_theme_font_size_override("font_size", 17)
	crafting_panel.add_child(crafting_detail_label)
	var controls := Label.new()
	controls.position = Vector2(24, 345)
	controls.text = "W/S or D-pad: select    E/A: craft    C/Esc/B: close"
	controls.add_theme_font_size_override("font_size", 14)
	crafting_panel.add_child(controls)
	_update_crafting_ui()


func _build_storage_panel(layer: CanvasLayer) -> void:
	storage_panel = ColorRect.new()
	storage_panel.position = Vector2(300, 140)
	storage_panel.size = Vector2(680, 420)
	storage_panel.color = Color(0.06, 0.07, 0.09, 0.96)
	storage_panel.visible = false
	layer.add_child(storage_panel)
	var title := Label.new()
	title.position = Vector2(24, 18)
	title.text = "STORAGE CRATE"
	title.add_theme_font_size_override("font_size", 24)
	storage_panel.add_child(title)
	storage_player_label = Label.new()
	storage_player_label.position = Vector2(24, 68)
	storage_player_label.size = Vector2(300, 270)
	storage_player_label.add_theme_font_size_override("font_size", 16)
	storage_panel.add_child(storage_player_label)
	storage_contents_label = Label.new()
	storage_contents_label.position = Vector2(355, 68)
	storage_contents_label.size = Vector2(300, 270)
	storage_contents_label.add_theme_font_size_override("font_size", 16)
	storage_panel.add_child(storage_contents_label)
	storage_feedback_label = Label.new()
	storage_feedback_label.position = Vector2(24, 340)
	storage_feedback_label.size = Vector2(630, 36)
	storage_feedback_label.add_theme_font_size_override("font_size", 16)
	storage_panel.add_child(storage_feedback_label)
	var controls := Label.new()
	controls.position = Vector2(24, 382)
	controls.text = "W/S: crate slot    E/A: deposit selected player stack    Space/X: withdraw    Esc/B: close"
	controls.add_theme_font_size_override("font_size", 13)
	storage_panel.add_child(controls)


func set_crafting_open(value: bool) -> void:
	crafting_open = value
	player.movement_enabled = not value
	player.velocity = Vector2.ZERO
	crafting_panel.visible = value
	if value:
		_update_crafting_ui()


func select_quick_slot(index: int) -> void:
	selected_slot = posmod(index, mini(8, inventory.slots.size()))
	_update_inventory_hud()


func begin_placement() -> bool:
	var definition: Variant = _selected_placeable_definition()
	if definition == null:
		interaction_label.text = "Selected slot is not placeable"
		return false
	placement_mode = true
	player.movement_enabled = false
	player.velocity = Vector2.ZERO
	placement_rotation = 0
	placement_cursor = _player_cell() + _facing_cell(player.facing)
	_update_placement_feedback()
	queue_redraw()
	return true


func cancel_placement() -> void:
	placement_mode = false
	player.movement_enabled = true
	placement_feedback = ""
	queue_redraw()


func move_placement_cursor(direction: Vector2i) -> void:
	placement_cursor += direction
	_update_placement_feedback()
	queue_redraw()


func rotate_placement() -> void:
	placement_rotation = posmod(placement_rotation + 1, 4)
	_update_placement_feedback()
	queue_redraw()


func confirm_placement() -> bool:
	var definition: Variant = _selected_placeable_definition()
	if definition == null:
		cancel_placement()
		return false
	var validation: Dictionary = _placement_validation(definition)
	if not validation.valid:
		placement_feedback = validation.reason
		_update_placement_feedback()
		queue_redraw()
		return false
	var instance_id := "placed-%04d" % next_placed_id
	var result: Variant = world_grid.place(instance_id, definition.entity_id, definition.spatial_footprint, placement_cursor, placement_rotation, definition.allowed_terrain)
	if not result.valid:
		placement_feedback = result.reason
		return false
	var selected_item: String = inventory.slots[selected_slot].item_id
	var removed: int = inventory.remove(selected_item, 1)
	assert(removed == 1, "Validated placement must consume exactly one item.")
	next_placed_id += 1
	_add_placed_collision(instance_id, result.cells)
	if not definition.construction_cost.is_empty() or definition.construction_work_seconds > 0.0:
		construction_by_entity_id[instance_id] = ConstructionSiteType.new(
			instance_id,
			definition.construction_cost,
			definition.construction_work_seconds
		)
	_add_placed_target(instance_id, definition, placement_cursor, placement_rotation)
	if definition.storage_slots > 0:
		storage_by_entity_id[instance_id] = PlayerInventoryType.new(item_registry, definition.storage_slots)
	cancel_placement()
	_update_inventory_hud()
	interaction_label.text = "Placed %s" % definition.label
	queue_redraw()
	return true


func _placement_validation(definition: Variant) -> Dictionary:
	var player_cell := _player_cell()
	if Vector2(placement_cursor - player_cell).length() > PLACEMENT_RANGE_CELLS:
		return {"valid": false, "reason": "OUT_OF_RANGE", "cells": definition.spatial_footprint.transformed_cells(placement_cursor, placement_rotation)}
	var result: Variant = world_grid.query_placement(definition.spatial_footprint, placement_cursor, placement_rotation, definition.allowed_terrain)
	if result.cells.has(player_cell):
		return {"valid": false, "reason": "PLAYER_OCCUPIED", "cells": result.cells}
	return {"valid": result.valid, "reason": result.reason, "cells": result.cells}


func _selected_placeable_definition() -> Variant:
	if selected_slot >= inventory.slots.size() or inventory.slots[selected_slot].is_empty():
		return null
	var item: Variant = item_registry.get_item(inventory.slots[selected_slot].item_id)
	if item == null or item.placeable_entity_id.is_empty():
		return null
	return placement_registry.get_entity(item.placeable_entity_id)


func _player_cell() -> Vector2i:
	return Vector2i(floori(player.position.x / CELL_SIZE), floori(player.position.y / CELL_SIZE))


func _facing_cell(facing: String) -> Vector2i:
	match facing:
		"north": return Vector2i.UP
		"east": return Vector2i.RIGHT
		"west": return Vector2i.LEFT
	return Vector2i.DOWN


func _update_placement_feedback() -> void:
	var definition: Variant = _selected_placeable_definition()
	if definition == null:
		return
	var validation: Dictionary = _placement_validation(definition)
	placement_feedback = "Valid - Space/X to place" if validation.valid else "Blocked: %s" % validation.reason
	interaction_label.text = "Placement %s at %s | %s | R rotate, Esc cancel" % [definition.label, str(placement_cursor), placement_feedback]


func _add_placed_collision(instance_id: String, cells: Array[Vector2i]) -> void:
	for index in range(cells.size()):
		var cell := cells[index]
		_add_static_rect(Vector2(cell * CELL_SIZE) + Vector2.ONE * 16.0, Vector2.ONE * CELL_SIZE, "%s-%d" % [instance_id, index])


func _add_placed_target(instance_id: String, definition: Variant, origin: Vector2i, placed_rotation: int) -> void:
	var ports: Dictionary = definition.spatial_footprint.transformed_ports(origin, placed_rotation)
	var origin_position := Vector2(origin * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5)
	var use_cell: Vector2i = ports.get("use", origin)
	var use_position := Vector2(use_cell * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5)
	var target := PlacedTargetType.new()
	var kind := "construction" if construction_by_entity_id.has(instance_id) else ("storage" if definition.storage_slots > 0 else "machine")
	target.configure(instance_id, definition.label, origin_position, use_position, kind)
	add_child(target)
	placed_targets[instance_id] = target


func select_recipe(direction: int) -> void:
	selected_recipe_index = posmod(selected_recipe_index + direction, recipe_registry.recipe_order.size())
	_update_crafting_ui()


func craft_selected_recipe() -> bool:
	var recipe_id: String = recipe_registry.recipe_order[selected_recipe_index]
	var result: Dictionary = crafting.craft(inventory, recipe_id)
	if result.valid:
		_update_inventory_hud()
		_update_crafting_ui("Crafted successfully.")
		return true
	_update_crafting_ui(_crafting_failure_text(result))
	return false


func _update_crafting_ui(feedback: String = "") -> void:
	if crafting_list_label == null:
		return
	var rows: Array[String] = []
	for index in range(recipe_registry.recipe_order.size()):
		var recipe: Variant = recipe_registry.get_recipe(recipe_registry.recipe_order[index])
		rows.append("%s %s" % [">" if index == selected_recipe_index else " ", recipe.label])
	crafting_list_label.text = "\n".join(rows)
	var selected: Variant = recipe_registry.get_recipe(recipe_registry.recipe_order[selected_recipe_index])
	var ingredients: Array[String] = []
	for item_id: String in selected.inputs:
		var definition: Variant = item_registry.get_item(item_id)
		ingredients.append("%s: %d / %d" % [definition.label, inventory.count(item_id), int(selected.inputs[item_id])])
	var outputs: Array[String] = []
	for item_id: String in selected.outputs:
		var definition: Variant = item_registry.get_item(item_id)
		outputs.append("%s x%d" % [definition.label, int(selected.outputs[item_id])])
	var query: Dictionary = crafting.query(inventory, selected.recipe_id)
	var status := "Ready to craft" if query.valid else _crafting_failure_text(query)
	if not feedback.is_empty():
		status = feedback
	crafting_detail_label.text = "%s\n\nNeeds:\n%s\n\nProduces:\n%s\n\n%s" % [selected.label, "\n".join(ingredients), "\n".join(outputs), status]


func _crafting_failure_text(result: Dictionary) -> String:
	if result.reason == CraftingSystemType.MISSING_INGREDIENTS:
		var parts: Array[String] = []
		for item_id: String in result.missing:
			parts.append("%s x%d" % [item_registry.get_item(item_id).label, int(result.missing[item_id])])
		return "Missing: %s" % ", ".join(parts)
	if result.reason == CraftingSystemType.OUTPUT_FULL:
		return "Inventory has no room for output"
	return "Recipe unavailable"


func _update_interaction_target() -> void:
	if placement_mode or crafting_open or storage_open:
		if is_instance_valid(interaction_target):
			interaction_target.set_targeted(false)
		interaction_target = null
		return
	var active: Array = []
	for pickup: Variant in pickups:
		if is_instance_valid(pickup) and pickup.amount > 0:
			active.append(pickup)
	for target: Variant in placed_targets.values():
		if is_instance_valid(target):
			active.append(target)
	var selected: Variant = TargetingType.select_target(player.global_position, player.facing, active, INTERACTION_REACH_PX)
	if selected != interaction_target:
		if is_instance_valid(interaction_target):
			interaction_target.set_targeted(false)
		interaction_target = selected
		if interaction_target != null:
			interaction_target.set_targeted(true)
	if interaction_label != null:
		if interaction_target == null:
			interaction_label.text = "Approach a resource stack or placed object"
		elif interaction_target.target_kind == "pickup":
			interaction_label.text = "E  Pick up %s x%d" % [interaction_target.item_label, interaction_target.amount]
		elif interaction_target.target_kind == "construction":
			interaction_label.text = _construction_prompt(interaction_target.stable_id)
		else:
			interaction_label.text = "E  Open %s" % interaction_target.item_label


func collect_target() -> int:
	_update_interaction_target()
	if interaction_target == null:
		return 0
	if interaction_target.target_kind == "storage":
		open_storage(interaction_target.stable_id)
		return 0
	if interaction_target.target_kind == "construction":
		return deliver_selected_to_construction(interaction_target.stable_id)
	if interaction_target.target_kind == "machine":
		interaction_label.text = "%s is complete" % interaction_target.item_label
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


func deliver_selected_to_construction(instance_id: String) -> int:
	var site: Variant = construction_by_entity_id.get(instance_id)
	if site == null or site.complete or inventory.slots[selected_slot].is_empty():
		return 0
	var slot: Dictionary = inventory.slots[selected_slot]
	var accepted: int = site.deliver(slot.item_id, int(slot.amount))
	if accepted > 0:
		inventory.remove(slot.item_id, accepted)
		_update_inventory_hud()
	interaction_label.text = _construction_prompt(instance_id)
	queue_redraw()
	return accepted


func apply_construction_work(instance_id: String, seconds: float) -> float:
	var site: Variant = construction_by_entity_id.get(instance_id)
	if site == null or site.complete:
		return 0.0
	var applied: float = site.apply_work(seconds)
	if site.complete:
		var target: Variant = placed_targets.get(instance_id)
		if target != null:
			target.target_kind = "machine"
		interaction_label.text = "%s completed" % target.item_label
	else:
		interaction_label.text = _construction_prompt(instance_id)
	queue_redraw()
	return applied


func _construction_prompt(instance_id: String) -> String:
	var site: Variant = construction_by_entity_id.get(instance_id)
	if site == null:
		return "Construction unavailable"
	if not site.materials_complete():
		var missing: Array[String] = []
		for item_id: String in site.requirements:
			var amount: int = site.receivable(item_id)
			if amount > 0:
				missing.append("%s %d" % [item_registry.get_item(item_id).label, amount])
		return "E  Deliver selected | Missing: %s" % ", ".join(missing)
	return "Hold Space/X  Build %d%%" % roundi(site.work_progress() * 100.0)


func open_storage(instance_id: String) -> bool:
	if not storage_by_entity_id.has(instance_id):
		return false
	storage_open = true
	active_storage_id = instance_id
	selected_storage_slot = 0
	player.movement_enabled = false
	player.velocity = Vector2.ZERO
	storage_panel.visible = true
	if is_instance_valid(interaction_target):
		interaction_target.set_targeted(false)
	interaction_target = null
	_update_storage_ui("Storage opened.")
	return true


func close_storage() -> void:
	storage_open = false
	active_storage_id = ""
	player.movement_enabled = true
	storage_panel.visible = false
	_update_inventory_hud()


func select_storage_slot(direction: int) -> void:
	var storage: Variant = storage_by_entity_id.get(active_storage_id)
	if storage == null:
		return
	selected_storage_slot = posmod(selected_storage_slot + direction, storage.slots.size())
	_update_storage_ui()


func deposit_selected_stack() -> int:
	var storage: Variant = storage_by_entity_id.get(active_storage_id)
	if storage == null or inventory.slots[selected_slot].is_empty():
		_update_storage_ui("Select a non-empty player slot.")
		return 0
	var slot: Dictionary = inventory.slots[selected_slot]
	var accepted: int = storage.add(slot.item_id, int(slot.amount))
	if accepted > 0:
		inventory.remove(slot.item_id, accepted)
		_update_inventory_hud()
	_update_storage_ui("Deposited %d." % accepted if accepted > 0 else "Crate has no room.")
	return accepted


func withdraw_selected_stack() -> int:
	var storage: Variant = storage_by_entity_id.get(active_storage_id)
	if storage == null or storage.slots[selected_storage_slot].is_empty():
		_update_storage_ui("Selected crate slot is empty.")
		return 0
	var slot: Dictionary = storage.slots[selected_storage_slot]
	var accepted: int = inventory.add(slot.item_id, int(slot.amount))
	if accepted > 0:
		storage.remove(slot.item_id, accepted)
		_update_inventory_hud()
	_update_storage_ui("Withdrew %d." % accepted if accepted > 0 else "Player inventory has no room.")
	return accepted


func _update_storage_ui(feedback: String = "") -> void:
	if storage_contents_label == null:
		return
	var storage: Variant = storage_by_entity_id.get(active_storage_id)
	if storage == null:
		return
	var player_rows: Array[String] = ["PLAYER INVENTORY"]
	for index in range(inventory.slots.size()):
		var slot: Dictionary = inventory.slots[index]
		player_rows.append("%s[%d] %s" % [">" if index == selected_slot else " ", index + 1, _slot_text(slot)])
	storage_player_label.text = "\n".join(player_rows)
	var storage_rows: Array[String] = ["CRATE INVENTORY"]
	for index in range(storage.slots.size()):
		storage_rows.append("%s[%d] %s" % [">" if index == selected_storage_slot else " ", index + 1, _slot_text(storage.slots[index])])
	storage_contents_label.text = "\n".join(storage_rows)
	storage_feedback_label.text = feedback


func _slot_text(slot: Dictionary) -> String:
	if slot.is_empty():
		return "--"
	var definition: Variant = item_registry.get_item(slot.item_id)
	return "%s x%d" % [definition.label, int(slot.amount)]


func _update_inventory_hud() -> void:
	if inventory_label == null:
		return
	var labels: Array[String] = []
	for index in range(inventory.slots.size()):
		var slot: Dictionary = inventory.slots[index]
		if slot.is_empty():
			labels.append("%s[%d] --" % [">" if index == selected_slot else " ", index + 1])
		else:
			var definition: Variant = item_registry.get_item(slot.item_id)
			labels.append("%s[%d] %s x%d" % [">" if index == selected_slot else " ", index + 1, definition.label, int(slot.amount)])
	inventory_label.text = "   ".join(labels)


func _draw() -> void:
	for y in range(WORLD_SIZE.y):
		for x in range(WORLD_SIZE.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * CELL_SIZE), Vector2.ONE * CELL_SIZE)
			draw_rect(rect, WATER if water_cells.has(cell) else SAND)
			draw_rect(rect, GRID_LINE, false, 1.0)
	if world_grid != null:
		for placed: Variant in world_grid.entities_by_id.values():
			var site: Variant = construction_by_entity_id.get(placed.instance_id)
			var placed_color := Color("#8c7a66") if site != null and not site.complete else Color("#71472b")
			for cell: Vector2i in placed.cells:
				var placed_rect := Rect2(Vector2(cell * CELL_SIZE) + Vector2.ONE * 2.0, Vector2.ONE * (CELL_SIZE - 4))
				draw_rect(placed_rect, placed_color)
				if site != null and not site.complete:
					draw_line(placed_rect.position, placed_rect.end, Color("#d7c7a2"), 2.0)
					draw_line(Vector2(placed_rect.end.x, placed_rect.position.y), Vector2(placed_rect.position.x, placed_rect.end.y), Color("#d7c7a2"), 2.0)
	if placement_mode:
		var definition: Variant = _selected_placeable_definition()
		if definition != null:
			var validation: Dictionary = _placement_validation(definition)
			for cell: Vector2i in validation.cells:
				var preview_rect := Rect2(Vector2(cell * CELL_SIZE) + Vector2.ONE, Vector2.ONE * (CELL_SIZE - 2))
				draw_rect(preview_rect, Color(0.2, 0.9, 0.4, 0.58) if validation.valid else Color(0.95, 0.2, 0.2, 0.62))
				draw_rect(preview_rect, Color.WHITE, false, 2.0)
