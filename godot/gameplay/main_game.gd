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
const EgyptCampaignType = preload("res://world/progression/egypt_campaign.gd")
const PhysicalSaveCodecType = preload("res://world/persistence/physical_save_codec.gd")
const PhysicalScenarioType = preload("res://world/scenario/physical_scenario.gd")
const PhysicalMachineType = preload("res://world/machines/physical_machine.gd")
const PhysicalRouteType = preload("res://world/logistics/physical_route.gd")
const PhysicalWorkforceType = preload("res://world/population/physical_workforce.gd")

const CELL_SIZE := 32
const WORLD_SIZE := Vector2i(50, 30)
const WORLD_PIXELS := Vector2(WORLD_SIZE * CELL_SIZE)
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
var machines_by_entity_id: Dictionary = {}
var logistics_routes: Array = []
var route_source_id := ""
var next_route_id := 1
var workforce: Variant
var population_label: Label
var campaign: Variant
var objective_label: Label
var physical_save: Variant
@export_file("*.json") var scenario_path := "res://scenarios/physical/ancient_egypt.json"
var scenario: Variant
var sand_color := Color("#cdbb7d")
var water_color := Color("#4d8fbd")
var scenario_panel: Control
var scenario_select_open := false
var machine_open := false
var active_machine_id := ""
var machine_panel: Control
var machine_status_label: Label


func _ready() -> void:
	scenario = PhysicalScenarioType.new()
	if not PhysicalScenarioType.requested_path.is_empty():
		scenario_path = PhysicalScenarioType.requested_path
		PhysicalScenarioType.requested_path = ""
	assert(scenario.load_from_path(scenario_path) == OK, "Physical scenario must load")
	sand_color = scenario.sand_color
	water_color = scenario.water_color
	workforce = PhysicalWorkforceType.new()
	campaign = EgyptCampaignType.new()
	physical_save = PhysicalSaveCodecType.new()
	_build_terrain()
	_build_boundaries()
	_build_player()
	_build_items()
	_build_hud()
	if DisplayServer.get_name() != "headless":
		set_scenario_select_open(true)
	if PhysicalSaveCodecType.pending_reload:
		PhysicalSaveCodecType.pending_reload = false
		physical_save.load_from_path(self, "user://physical_save.json")
	queue_redraw()


func _process(delta: float) -> void:
	workforce.process(delta)
	_update_population_hud()
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
	for machine: Variant in machines_by_entity_id.values():
		machine.staffed = workforce.assigned_to(machine.instance_id) > 0
		machine.process(delta)
	for route: Variant in logistics_routes:
		_process_logistics_route(route, delta)
	campaign.refresh(machines_by_entity_id, logistics_routes)
	if objective_label != null:
		objective_label.text = campaign.current_text()
	if machine_open:
		_update_machine_panel()
	if not machines_by_entity_id.is_empty():
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if scenario_select_open:
		if event.is_action_pressed("quick_slot_1"):
			select_scenario("res://scenarios/physical/ancient_egypt.json")
		elif event.is_action_pressed("quick_slot_2"):
			select_scenario("res://scenarios/physical/mesopotamia.json")
		return
	if machine_open:
		if event.is_action_pressed("cancel") or event.is_action_pressed("open_crafting"):
			close_machine()
		elif event.is_action_pressed("interact"):
			deliver_selected_to_machine(active_machine_id)
		elif event.is_action_pressed("use_selected"):
			withdraw_machine_output(active_machine_id)
		return
	if event.is_action_pressed("save_game"):
		var result: Error = physical_save.save_to_path(self, "user://physical_save.json")
		interaction_label.text = "Game saved" if result == OK else "Save failed"
		return
	if event.is_action_pressed("load_game"):
		if world_grid.entities_by_id.is_empty():
			var result: Error = physical_save.load_from_path(self, "user://physical_save.json")
			interaction_label.text = "Game loaded" if result == OK else "Load failed"
		else:
			PhysicalSaveCodecType.pending_reload = true
			get_tree().reload_current_scene()
		return
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
		elif interaction_target != null and interaction_target.target_kind == "machine":
			withdraw_machine_output(interaction_target.stable_id)
		else:
			begin_placement()
	elif not crafting_open and event.is_action_pressed("quick_previous"):
		select_quick_slot(selected_slot - 1)
	elif not crafting_open and event.is_action_pressed("quick_next"):
		select_quick_slot(selected_slot + 1)
	elif not crafting_open and event.is_action_pressed("rotate_blueprint"):
		select_route_endpoint(interaction_target.stable_id if interaction_target != null else "")
	elif not crafting_open:
		for index in range(8):
			if event.is_action_pressed("quick_slot_%d" % (index + 1)):
				select_quick_slot(index)
				break


func _build_terrain() -> void:
	world_grid = WorldGridType.new(WORLD_SIZE, "sand")
	for values: Array in scenario.water_rects:
		for y in range(int(values[1]), int(values[1]) + int(values[3])):
			for x in range(int(values[0]), int(values[0]) + int(values[2])):
				water_cells[Vector2i(x, y)] = true
	for gap: Vector2i in scenario.water_gaps:
		water_cells.erase(gap)
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
	for pickup: Dictionary in scenario.pickups:
		_spawn_pickup(str(pickup.id), str(pickup.item), int(pickup.amount), Vector2(float(pickup.cell[0]), float(pickup.cell[1])) * CELL_SIZE)


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
	population_label = Label.new()
	population_label.position = Vector2(500, 58)
	population_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(population_label)
	objective_label = Label.new()
	objective_label.position = Vector2(500, 84)
	objective_label.add_theme_font_size_override("font_size", 16)
	objective_label.add_theme_color_override("font_color", Color("#f0cc72"))
	layer.add_child(objective_label)
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
	_build_machine_panel(layer)
	_build_scenario_panel(layer)
	var help := Label.new()
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(22, -118)
	help.text = "Move/Pick up: WASD + E/A    Craft: C/Y    Use: Space/X    Routes: R    Save/Load: F5/F9"
	help.add_theme_color_override("font_color", Color.WHITE)
	help.add_theme_font_size_override("font_size", 16)
	layer.add_child(help)


func _build_scenario_panel(layer: CanvasLayer) -> void:
	scenario_panel = ColorRect.new()
	scenario_panel.position = Vector2(330, 190)
	scenario_panel.size = Vector2(620, 300)
	scenario_panel.color = Color(0.05, 0.06, 0.08, 0.97)
	scenario_panel.visible = false
	layer.add_child(scenario_panel)
	var title := Label.new()
	title.position = Vector2(44, 36)
	title.text = "CHOOSE A SETTLEMENT"
	title.add_theme_font_size_override("font_size", 28)
	scenario_panel.add_child(title)
	var options := Label.new()
	options.position = Vector2(44, 105)
	options.text = "[1]  Settlement on the Nile\n\n[2]  Settlement between the Rivers"
	options.add_theme_font_size_override("font_size", 22)
	scenario_panel.add_child(options)


func _build_machine_panel(layer: CanvasLayer) -> void:
	machine_panel = ColorRect.new()
	machine_panel.position = Vector2(350, 160)
	machine_panel.size = Vector2(580, 360)
	machine_panel.color = Color(0.06, 0.07, 0.09, 0.96)
	machine_panel.visible = false
	layer.add_child(machine_panel)
	var title := Label.new()
	title.position = Vector2(26, 22)
	title.text = "BRICK KILN"
	title.add_theme_font_size_override("font_size", 25)
	machine_panel.add_child(title)
	machine_status_label = Label.new()
	machine_status_label.position = Vector2(28, 72)
	machine_status_label.size = Vector2(520, 220)
	machine_status_label.add_theme_font_size_override("font_size", 18)
	machine_panel.add_child(machine_status_label)
	var controls := Label.new()
	controls.position = Vector2(28, 318)
	controls.text = "E/A: add selected stack    Space/X: collect output    Esc/B: close"
	controls.add_theme_font_size_override("font_size", 14)
	machine_panel.add_child(controls)


func set_scenario_select_open(value: bool) -> void:
	scenario_select_open = value
	if scenario_panel != null: scenario_panel.visible = value
	if player != null:
		player.movement_enabled = not value
		player.velocity = Vector2.ZERO


func select_scenario(path: String) -> void:
	if path == scenario_path:
		set_scenario_select_open(false)
		return
	PhysicalScenarioType.requested_path = path
	get_tree().reload_current_scene()


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
	campaign.record_placement(definition.entity_id)
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
	var footprint_points: Array[Vector2] = []
	for cell: Vector2i in definition.spatial_footprint.transformed_cells(origin, placed_rotation):
		footprint_points.append(Vector2(cell * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5))
	target.configure(instance_id, definition.label, origin_position, use_position, kind, footprint_points)
	add_child(target)
	placed_targets[instance_id] = target


func select_recipe(direction: int) -> void:
	selected_recipe_index = posmod(selected_recipe_index + direction, recipe_registry.recipe_order.size())
	_update_crafting_ui()


func craft_selected_recipe() -> bool:
	var recipe_id: String = recipe_registry.recipe_order[selected_recipe_index]
	var result: Dictionary = crafting.craft(inventory, recipe_id)
	if result.valid:
		campaign.record_craft(recipe_id)
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
	if placement_mode or crafting_open or storage_open or machine_open:
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
		elif interaction_target.target_kind == "machine":
			interaction_label.text = _machine_prompt(interaction_target.stable_id) + " | R route"
		else:
			interaction_label.text = "E  Open %s | R route" % interaction_target.item_label


func collect_target() -> int:
	_update_interaction_target()
	if interaction_target == null:
		return 0
	if interaction_target.target_kind == "storage":
		open_storage(interaction_target.stable_id)
		return 0
	if interaction_target.target_kind == "construction":
		return deliver_selected_to_construction(interaction_target.stable_id)
	if interaction_target.target_kind == "building":
		return feed_settlement()
	if interaction_target.target_kind == "machine":
		var machine_id: String = interaction_target.stable_id
		var delivered := deliver_selected_to_machine(machine_id)
		if delivered == 0: open_machine(machine_id)
		return delivered
	var accepted: int = inventory.add(interaction_target.item_id, interaction_target.amount)
	if accepted <= 0:
		interaction_label.text = "Inventory full"
		return 0
	interaction_target.take(accepted)
	campaign.record_pickup(interaction_target.item_id)
	if interaction_target.amount == 0:
		interaction_target.set_targeted(false)
		interaction_target.queue_free()
		interaction_target = null
	_update_inventory_hud()
	return accepted


func feed_settlement() -> int:
	if inventory.slots[selected_slot].is_empty(): return 0
	var slot: Dictionary = inventory.slots[selected_slot]
	if slot.item_id != "food_ration":
		interaction_label.text = "Select a Food ration to support the settlement"
		return 0
	var amount := int(slot.amount)
	inventory.remove("food_ration", amount)
	workforce.add_food(amount)
	_update_inventory_hud()
	interaction_label.text = "Delivered %d food rations" % amount
	return amount


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
		var placed: Variant = world_grid.entities_by_id.get(instance_id)
		var definition: Variant = placement_registry.get_entity(placed.definition_id) if placed != null else null
		if target != null:
			target.target_kind = "machine" if definition != null and not definition.recipe_outputs.is_empty() else "building"
		if definition != null and not definition.recipe_outputs.is_empty():
			machines_by_entity_id[instance_id] = PhysicalMachineType.new(instance_id, definition.recipe_inputs, definition.recipe_outputs, definition.process_time_sec, item_registry)
			workforce.register_job(instance_id, ceili(definition.workers_required), definition.worker_priority)
		if definition != null:
			campaign.record_completion(definition.entity_id)
		_refresh_population_capacity()
		interaction_label.text = "%s completed" % (target.item_label if target != null else "Building")
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


func deliver_selected_to_machine(instance_id: String) -> int:
	var machine: Variant = machines_by_entity_id.get(instance_id)
	if machine == null or inventory.slots[selected_slot].is_empty():
		return 0
	var slot: Dictionary = inventory.slots[selected_slot]
	if machine.broken:
		var repair_cost: int = machine.repair(slot.item_id, int(slot.amount))
		if repair_cost > 0:
			inventory.remove(slot.item_id, repair_cost)
			_update_inventory_hud()
		interaction_label.text = _machine_prompt(instance_id)
		return repair_cost
	var accepted: int = machine.add_input(slot.item_id, int(slot.amount))
	if accepted > 0:
		inventory.remove(slot.item_id, accepted)
		_update_inventory_hud()
	interaction_label.text = _machine_prompt(instance_id)
	if machine_open: _update_machine_panel()
	return accepted


func withdraw_machine_output(instance_id: String) -> int:
	var machine: Variant = machines_by_entity_id.get(instance_id)
	if machine == null:
		return 0
	for slot: Dictionary in machine.output_inventory.slots:
		if slot.is_empty():
			continue
		var accepted: int = inventory.add(slot.item_id, int(slot.amount))
		if accepted > 0:
			machine.output_inventory.remove(slot.item_id, accepted)
			_update_inventory_hud()
		interaction_label.text = _machine_prompt(instance_id)
		if machine_open: _update_machine_panel()
		return accepted
	interaction_label.text = _machine_prompt(instance_id)
	return 0


func _machine_prompt(instance_id: String) -> String:
	var machine: Variant = machines_by_entity_id.get(instance_id)
	if machine == null:
		return "Machine unavailable"
	if machine.broken:
		return "Kiln broken | Select Wood x2 and press E to repair"
	var output_count := 0
	for item_id: String in machine.recipe_outputs:
		output_count += machine.output_inventory.count(item_id)
	if machine.is_running():
		return "Kiln firing %d%% | E add clay | Space/X collect (%d)" % [roundi(machine.progress() * 100.0), output_count]
	return "Kiln ready | E add clay | Space/X collect (%d)" % output_count


func open_machine(instance_id: String) -> bool:
	if not machines_by_entity_id.has(instance_id): return false
	machine_open = true
	active_machine_id = instance_id
	player.movement_enabled = false
	player.velocity = Vector2.ZERO
	machine_panel.visible = true
	interaction_target = null
	_update_machine_panel()
	return true


func close_machine() -> void:
	machine_open = false
	active_machine_id = ""
	player.movement_enabled = true
	machine_panel.visible = false


func _update_machine_panel() -> void:
	if machine_status_label == null: return
	var machine: Variant = machines_by_entity_id.get(active_machine_id)
	if machine == null: return
	var input_rows: Array[String] = []
	for item_id: String in machine.recipe_inputs:
		input_rows.append("%s: %d / %d" % [item_registry.get_item(item_id).label, machine.input_inventory.count(item_id), int(machine.recipe_inputs[item_id])])
	var output_rows: Array[String] = []
	for item_id: String in machine.recipe_outputs:
		output_rows.append("%s: %d" % [item_registry.get_item(item_id).label, machine.output_inventory.count(item_id)])
	var state := "BROKEN - needs Wood x2" if machine.broken else ("UNSTAFFED" if not machine.staffed else ("FIRING %d%%" % roundi(machine.progress() * 100.0) if machine.is_running() else "READY / WAITING FOR INPUT"))
	machine_status_label.text = "State: %s\nWorker: %s\nDurability: %d / %d\n\nINPUT\n%s\n\nOUTPUT\n%s" % [state, "assigned" if machine.staffed else "missing", machine.durability, machine.max_durability, "\n".join(input_rows), "\n".join(output_rows)]


func select_route_endpoint(instance_id: String) -> bool:
	if instance_id.is_empty() or not placed_targets.has(instance_id):
		return false
	if route_source_id.is_empty():
		route_source_id = instance_id
		interaction_label.text = "Route source selected; approach destination and press R"
		return true
	if route_source_id == instance_id:
		route_source_id = ""
		interaction_label.text = "Route cancelled"
		return false
	var created := create_logistics_route(route_source_id, instance_id)
	route_source_id = ""
	return created


func create_logistics_route(source_id: String, destination_id: String) -> bool:
	if not placed_targets.has(source_id) or not placed_targets.has(destination_id):
		return false
	var source_valid := storage_by_entity_id.has(source_id) or machines_by_entity_id.has(source_id)
	var destination_valid := storage_by_entity_id.has(destination_id) or machines_by_entity_id.has(destination_id)
	if not source_valid or not destination_valid:
		return false
	for route: Variant in logistics_routes:
		if route.source_id == source_id and route.destination_id == destination_id:
			return false
	logistics_routes.append(PhysicalRouteType.new("route-%04d" % next_route_id, source_id, destination_id))
	next_route_id += 1
	interaction_label.text = "Porter route created"
	queue_redraw()
	return true


func _process_logistics_route(route: Variant, delta: float) -> int:
	var source_inventory: Variant = storage_by_entity_id.get(route.source_id)
	if source_inventory == null and machines_by_entity_id.has(route.source_id):
		source_inventory = machines_by_entity_id[route.source_id].output_inventory
	var destination: Variant = machines_by_entity_id.get(route.destination_id)
	if destination == null:
		destination = storage_by_entity_id.get(route.destination_id)
	if source_inventory == null or destination == null:
		return 0
	return route.process(delta, source_inventory, destination)


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
	_update_population_hud()


func _update_population_hud() -> void:
	if population_label != null and workforce != null:
		population_label.text = workforce.employment_summary()


func _refresh_population_capacity() -> void:
	var capacity := 1
	for instance_id: String in construction_by_entity_id:
		var site: Variant = construction_by_entity_id[instance_id]
		if not site.complete:
			continue
		var placed: Variant = world_grid.entities_by_id.get(instance_id)
		var definition: Variant = placement_registry.get_entity(placed.definition_id) if placed != null else null
		if definition != null:
			capacity += definition.population_capacity
	workforce.set_population(capacity)
	_update_population_hud()


func _draw() -> void:
	for y in range(WORLD_SIZE.y):
		for x in range(WORLD_SIZE.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell * CELL_SIZE), Vector2.ONE * CELL_SIZE)
			draw_rect(rect, water_color if water_cells.has(cell) else sand_color)
			draw_rect(rect, GRID_LINE, false, 1.0)
	if world_grid != null:
		for placed: Variant in world_grid.entities_by_id.values():
			var site: Variant = construction_by_entity_id.get(placed.instance_id)
			var machine: Variant = machines_by_entity_id.get(placed.instance_id)
			var placed_color := Color("#8c7a66") if site != null and not site.complete else (Color("#8f302b") if machine != null and machine.broken else (Color("#db6b35") if machine != null and machine.is_running() else Color("#71472b")))
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
	for route: Variant in logistics_routes:
		var from_target: Variant = placed_targets.get(route.source_id)
		var to_target: Variant = placed_targets.get(route.destination_id)
		if from_target == null or to_target == null:
			continue
		var start: Vector2 = from_target.global_position
		var finish: Vector2 = to_target.global_position
		draw_line(start, finish, Color("#e1bd62"), 3.0)
		var porter_position := start.lerp(finish, route.progress())
		draw_circle(porter_position, 7.0, Color("#315b70"))
		draw_circle(porter_position, 7.0, Color.WHITE, false, 1.5)
	for instance_id: String in machines_by_entity_id:
		if workforce.assigned_to(instance_id) <= 0:
			continue
		var worker_target: Variant = placed_targets.get(instance_id)
		if worker_target != null:
			var worker_position: Vector2 = worker_target.global_position + Vector2(12, -10)
			draw_circle(worker_position, 6.0, Color("#efe1c1"))
			draw_circle(worker_position + Vector2(0, -5), 3.5, Color("#3a251e"))
