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
const BUILDING_TEXTURE = preload("res://assets/generated/buildings/egypt_buildings_sheet.png")
const PhysicalMachineType = preload("res://world/machines/physical_machine.gd")
const PhysicalRouteType = preload("res://world/logistics/physical_route.gd")
const PhysicalWorkforceType = preload("res://world/population/physical_workforce.gd")
const VillagerType = preload("res://world/population/villager.gd")
const ItemIconAtlasType = preload("res://items/item_icon_atlas.gd")
const WorldOverlayType = preload("res://world/interaction/world_overlay.gd")

const CELL_SIZE := 32
const WORLD_SIZE := Vector2i(50, 30)
const WORLD_PIXELS := Vector2(WORLD_SIZE * CELL_SIZE)
const GRID_LINE := Color(0.16, 0.14, 0.10, 0.18)
const INTERACTION_REACH_PX := 40.0
const PLACEMENT_RANGE_CELLS := 4.0
const CAMERA_ZOOM_LEVELS: Array[float] = [0.75, 1.0, 1.25, 1.5, 2.0]

var player: CharacterBody2D
var camera: Camera2D
var position_label: Label
var interaction_label: Label
var inventory_label: Label
var inventory_icons: Array[TextureRect] = []
var inventory_slot_labels: Array[Label] = []
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
var crafting_recipe_buttons: Array[Button] = []
var crafting_resource_icons: Array[TextureRect] = []
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
var storage_focus_side := 0 # 0 = player inventory, 1 = crate
var storage_panel: Control
var storage_player_label: Label
var storage_contents_label: Label
var storage_feedback_label: Label
var storage_player_icons: Array[TextureRect] = []
var storage_crate_icons: Array[TextureRect] = []
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
var villagers: Dictionary = {}
var next_villager_id := 1
var selected_villager_id := ""
var villager_panel: Control
var villager_name_edit: LineEdit
var villager_status_label: Label
var villager_order_feedback: Label
var villager_resource_option: OptionButton
var villager_order_mode := ""
var pending_order_source_id := ""
var building_details_open := false
var building_details_id := ""
var building_details_panel: Control
var building_details_title: Label
var building_details_body: Label
var world_overlay: Node2D
var active_player_build_id := ""
var day_time_seconds := 60.0
const DAY_LENGTH_SECONDS := 240.0
const VILLAGER_NAMES: Array[String] = ["Nefru", "Merit", "Hori", "Tia", "Bek", "Kiya", "Sabu", "Ipu", "Nebet", "Dagi"]


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
	world_overlay = WorldOverlayType.new()
	world_overlay.configure(self)
	add_child(world_overlay)
	if DisplayServer.get_name() != "headless":
		set_scenario_select_open(true)
	if PhysicalSaveCodecType.pending_reload:
		PhysicalSaveCodecType.pending_reload = false
		physical_save.load_from_path(self, "user://physical_save.json")
	queue_redraw()


func _process(delta: float) -> void:
	day_time_seconds = fmod(day_time_seconds + maxf(delta, 0.0), DAY_LENGTH_SECONDS)
	workforce.process(delta)
	for villager: Variant in villagers.values():
		villager.process_life(self, delta)
	_update_population_hud()
	if player != null and position_label != null:
		var cell := Vector2i(floori(player.position.x / CELL_SIZE), floori(player.position.y / CELL_SIZE))
		position_label.text = "Cell %s    Facing: %s" % [str(cell), player.facing]
	if placement_mode:
		var followed_cursor := _player_cell() + _facing_cell(player.facing)
		if followed_cursor != placement_cursor:
			placement_cursor = followed_cursor
			_update_placement_feedback()
			queue_redraw()
	_update_interaction_target()
	if not active_player_build_id.is_empty():
		var build_target: Variant = placed_targets.get(active_player_build_id)
		var build_site: Variant = construction_by_entity_id.get(active_player_build_id)
		if build_target == null or build_site == null or build_site.complete or player.position.distance_to(build_target.interaction_position_for(player.position)) > INTERACTION_REACH_PX + 8.0:
			active_player_build_id = ""
		else:
			apply_construction_work(active_player_build_id, delta)
	for machine: Variant in machines_by_entity_id.values():
		machine.staffed = assigned_villagers_to(machine.instance_id) > 0
		machine.process(delta)
	campaign.refresh(machines_by_entity_id, logistics_routes)
	if objective_label != null:
		objective_label.text = campaign.current_text()
	if machine_open:
		_update_machine_panel()
	if not selected_villager_id.is_empty():
		_update_villager_panel()
	if building_details_open:
		_update_building_details()
	if not machines_by_entity_id.is_empty():
		queue_redraw()
	if world_overlay != null: world_overlay.queue_redraw()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("rotate_blueprint") or placement_mode:
		return
	if scenario_select_open or machine_open or storage_open or crafting_open:
		return
	if selected_villager_id.is_empty():
		interaction_label.text = "Click a villager first, then assign transport from their panel"
		get_viewport().set_input_as_handled()
		return
	_update_route_interaction_target()
	if interaction_target == null:
		interaction_label.text = "Move beside a completed storage or machine to create a route"
	elif interaction_target.target_kind == "construction":
		interaction_label.text = "Complete this building before connecting a route"
	elif interaction_target.target_kind != "storage" and interaction_target.target_kind != "machine":
		interaction_label.text = "This object cannot be a route endpoint"
	else:
		select_route_endpoint(interaction_target.stable_id)
	get_viewport().set_input_as_handled()


func _update_route_interaction_target() -> void:
	var endpoints: Array = []
	for target: Variant in placed_targets.values():
		if is_instance_valid(target): endpoints.append(target)
	var selected: Variant = TargetingType.select_target(player.global_position, player.facing, endpoints, INTERACTION_REACH_PX)
	if selected != interaction_target:
		if is_instance_valid(interaction_target): interaction_target.set_targeted(false)
		interaction_target = selected
		if interaction_target != null: interaction_target.set_targeted(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _handle_villager_world_click(event.position):
			get_viewport().set_input_as_handled()
			return
	if not selected_villager_id.is_empty() and event.is_action_pressed("cancel"):
		close_villager_panel()
		return
	if event.is_action_pressed("zoom_in"):
		adjust_camera_zoom(1)
		return
	if event.is_action_pressed("zoom_out"):
		adjust_camera_zoom(-1)
		return
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
		return
	if event.is_action_pressed("next_villager") and not villagers.is_empty():
		cycle_villager_selection()
		return
	if building_details_open:
		if event.is_action_pressed("cancel") or event.is_action_pressed("use_selected"):
			close_building_details()
		return
	if scenario_select_open:
		if event.is_action_pressed("quick_slot_1"):
			select_scenario("res://scenarios/physical/ancient_egypt.json")
		elif event.is_action_pressed("quick_slot_2"):
			select_scenario("res://scenarios/physical/mesopotamia.json")
		return
	if machine_open:
		if event.is_action_pressed("cancel") or event.is_action_pressed("open_crafting"):
			close_machine()
		elif event.is_action_pressed("use_selected"):
			machine_context_action(active_machine_id)
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
		elif event.is_action_pressed("move_left"):
			set_storage_focus(0)
		elif event.is_action_pressed("move_right"):
			set_storage_focus(1)
		elif event.is_action_pressed("menu_up"):
			select_active_storage_slot(-1)
		elif event.is_action_pressed("menu_down"):
			select_active_storage_slot(1)
		elif event.is_action_pressed("use_selected"):
			transfer_storage_selected()
		return
	if placement_mode:
		if event.is_action_pressed("cancel"):
			cancel_placement()
		elif event.is_action_pressed("rotate_blueprint"):
			rotate_placement()
		elif event.is_action_pressed("use_selected"):
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
	elif crafting_open and (event.is_action_pressed("craft_confirm") or event.is_action_pressed("use_selected")):
		craft_selected_recipe()
	elif not crafting_open and event.is_action_pressed("use_selected"):
		if interaction_target != null and interaction_target.target_kind == "pickup":
			collect_target()
		elif interaction_target != null and interaction_target.target_kind == "construction":
			var site: Variant = construction_by_entity_id.get(interaction_target.stable_id)
			if site != null and site.materials_complete(): active_player_build_id = interaction_target.stable_id
			else: deliver_selected_to_construction(interaction_target.stable_id)
		elif interaction_target != null and interaction_target.target_kind == "machine":
			open_machine(interaction_target.stable_id)
		elif interaction_target != null and interaction_target.target_kind == "storage":
			open_storage(interaction_target.stable_id)
		elif interaction_target != null and interaction_target.target_kind == "building":
			open_building_details(interaction_target.stable_id)
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
	camera = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_PIXELS.x)
	camera.limit_bottom = int(WORLD_PIXELS.y)


func adjust_camera_zoom(direction: int) -> float:
	var current := camera.zoom.x
	var nearest_index := 0
	var nearest_distance := INF
	for index in range(CAMERA_ZOOM_LEVELS.size()):
		var distance := absf(CAMERA_ZOOM_LEVELS[index] - current)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	var next_index := clampi(nearest_index + direction, 0, CAMERA_ZOOM_LEVELS.size() - 1)
	var value := CAMERA_ZOOM_LEVELS[next_index]
	camera.zoom = Vector2.ONE * value
	return value


func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)


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
	background.size = Vector2(420, 70)
	background.color = Color(0.08, 0.09, 0.11, 0.86)
	background.visible = false
	layer.add_child(background)
	var title := Label.new()
	title.position = Vector2(34, 26)
	title.text = "STARDew - Craft and place prototype"
	title.add_theme_font_size_override("font_size", 18)
	title.visible = false
	layer.add_child(title)
	position_label = Label.new()
	position_label.position = Vector2(34, 58)
	position_label.add_theme_font_size_override("font_size", 16)
	position_label.visible = false
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
	interaction_label.visible = false
	layer.add_child(interaction_label)

	var inventory_background := ColorRect.new()
	inventory_background.position = Vector2(16, 634)
	inventory_background.size = Vector2(1248, 72)
	inventory_background.color = Color(0.08, 0.09, 0.11, 0.9)
	layer.add_child(inventory_background)
	inventory_label = Label.new()
	inventory_label.position = Vector2(28, 648)
	inventory_label.size = Vector2(1224, 40)
	inventory_label.add_theme_font_size_override("font_size", 15)
	inventory_label.visible = false
	layer.add_child(inventory_label)
	for index in range(mini(8, inventory.slot_count)):
		var icon := TextureRect.new()
		var slot_x := 28 + index * 153
		icon.position = Vector2(slot_x, 644)
		icon.size = Vector2(34, 34)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer.add_child(icon)
		inventory_icons.append(icon)
		var slot_label := Label.new()
		slot_label.position = Vector2(slot_x + 38, 640)
		slot_label.size = Vector2(110, 42)
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 13)
		layer.add_child(slot_label)
		inventory_slot_labels.append(slot_label)
	_update_inventory_hud()
	_build_crafting_panel(layer)
	_build_storage_panel(layer)
	_build_machine_panel(layer)
	_build_villager_panel(layer)
	_build_building_details_panel(layer)
	_build_scenario_panel(layer)
	var help := Label.new()
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(22, -118)
	help.text = "Move: WASD    Action: Space    Villagers: click/Tab    Crafting: C    Back: Esc"
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
	controls.text = "Space: add compatible selected item, otherwise collect    Esc: close"
	controls.add_theme_font_size_override("font_size", 14)
	machine_panel.add_child(controls)


func _build_villager_panel(layer: CanvasLayer) -> void:
	villager_panel = ColorRect.new()
	villager_panel.position = Vector2(915, 120)
	villager_panel.size = Vector2(340, 480)
	villager_panel.color = Color("#d8bd83")
	villager_panel.visible = false
	layer.add_child(villager_panel)
	var title := Label.new()
	title.position = Vector2(22, 18)
	title.text = "VILLAGER"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#3b281b"))
	villager_panel.add_child(title)
	villager_name_edit = LineEdit.new()
	villager_name_edit.position = Vector2(22, 60)
	villager_name_edit.size = Vector2(296, 38)
	villager_name_edit.placeholder_text = "Name"
	villager_name_edit.text_submitted.connect(_rename_selected_villager)
	villager_name_edit.focus_exited.connect(_commit_villager_name)
	villager_panel.add_child(villager_name_edit)
	villager_status_label = Label.new()
	villager_status_label.position = Vector2(22, 112)
	villager_status_label.size = Vector2(296, 190)
	villager_status_label.add_theme_font_size_override("font_size", 16)
	villager_status_label.add_theme_color_override("font_color", Color("#3b281b"))
	villager_panel.add_child(villager_status_label)
	villager_resource_option = OptionButton.new()
	villager_resource_option.position = Vector2(22, 286)
	villager_resource_option.size = Vector2(296, 36)
	villager_resource_option.visible = false
	villager_panel.add_child(villager_resource_option)
	var assign := Button.new()
	assign.position = Vector2(22, 330)
	assign.size = Vector2(94, 42)
	assign.text = "Assign transport"
	assign.pressed.connect(begin_villager_transport_order)
	villager_panel.add_child(assign)
	var work := Button.new()
	work.position = Vector2(123, 330)
	work.size = Vector2(94, 42)
	work.text = "Assign work"
	work.pressed.connect(begin_villager_work_order)
	villager_panel.add_child(work)
	var stop := Button.new()
	stop.position = Vector2(224, 330)
	stop.size = Vector2(94, 42)
	stop.text = "Stop task"
	stop.pressed.connect(stop_selected_villager_task)
	villager_panel.add_child(stop)
	villager_order_feedback = Label.new()
	villager_order_feedback.position = Vector2(22, 385)
	villager_order_feedback.size = Vector2(296, 62)
	villager_order_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	villager_order_feedback.add_theme_color_override("font_color", Color("#6b3e20"))
	villager_panel.add_child(villager_order_feedback)


func _build_building_details_panel(layer: CanvasLayer) -> void:
	building_details_panel = ColorRect.new()
	building_details_panel.position = Vector2(915, 120)
	building_details_panel.size = Vector2(340, 480)
	building_details_panel.color = Color("#d8bd83")
	building_details_panel.visible = false
	layer.add_child(building_details_panel)
	building_details_title = Label.new()
	building_details_title.position = Vector2(24, 20)
	building_details_title.add_theme_font_size_override("font_size", 25)
	building_details_title.add_theme_color_override("font_color", Color("#3b281b"))
	building_details_panel.add_child(building_details_title)
	building_details_body = Label.new()
	building_details_body.position = Vector2(24, 70)
	building_details_body.size = Vector2(292, 330)
	building_details_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_details_body.add_theme_font_size_override("font_size", 17)
	building_details_body.add_theme_color_override("font_color", Color("#3b281b"))
	building_details_panel.add_child(building_details_body)
	var controls := Label.new()
	controls.position = Vector2(24, 438)
	controls.text = "Space / Esc: close"
	controls.add_theme_color_override("font_color", Color("#6b3e20"))
	building_details_panel.add_child(controls)


func open_building_details(instance_id: String) -> bool:
	if not placed_targets.has(instance_id): return false
	if not selected_villager_id.is_empty(): close_villager_panel()
	building_details_id = instance_id
	building_details_open = true
	building_details_panel.visible = true
	player.movement_enabled = false
	player.velocity = Vector2.ZERO
	if is_instance_valid(interaction_target): interaction_target.set_targeted(false)
	interaction_target = null
	queue_redraw()
	_update_building_details()
	return true


func close_building_details() -> void:
	building_details_open = false
	building_details_id = ""
	building_details_panel.visible = false
	player.movement_enabled = true


func _update_building_details() -> void:
	var placed: Variant = world_grid.entities_by_id.get(building_details_id)
	if placed == null: close_building_details(); return
	var definition: Variant = placement_registry.get_entity(placed.definition_id)
	building_details_title.text = definition.label
	var site: Variant = construction_by_entity_id.get(building_details_id)
	if site != null and not site.complete:
		var materials: Array[String] = []
		for item_id: String in site.requirements:
			materials.append("%s: %d / %d" % [item_registry.get_item(item_id).label, int(site.delivered.get(item_id, 0)), int(site.requirements[item_id])])
		building_details_body.text = "UNDER CONSTRUCTION\n\nMaterials\n%s\n\nWork: %d%%\nHealth: stable" % ["\n".join(materials), roundi(site.work_progress() * 100.0)]
		return
	if storage_by_entity_id.has(building_details_id):
		var rows: Array[String] = []
		for slot: Dictionary in storage_by_entity_id[building_details_id].slots:
			if not slot.is_empty(): rows.append("%s x%d" % [item_registry.get_item(slot.item_id).label, int(slot.amount)])
		building_details_body.text = "STORAGE\n\nContents\n%s\n\nHealth: good\n\nSpace opens inventory." % ("\n".join(rows) if not rows.is_empty() else "Empty")
		return
	if machines_by_entity_id.has(building_details_id):
		var machine: Variant = machines_by_entity_id[building_details_id]
		var inputs: Array[String] = []
		var outputs: Array[String] = []
		for item_id: String in machine.recipe_inputs: inputs.append("%s x%d" % [item_registry.get_item(item_id).label, machine.input_inventory.count(item_id)])
		for item_id: String in machine.recipe_outputs: outputs.append("%s x%d" % [item_registry.get_item(item_id).label, machine.output_inventory.count(item_id)])
		building_details_body.text = "KILN\n\nState: %s\nHealth: %d / %d\nProgress: %d%%\n\nInput\n%s\n\nOutput\n%s" % ["broken" if machine.broken else ("working" if machine.is_running() else "ready"), machine.durability, machine.max_durability, roundi(machine.progress() * 100.0), "\n".join(inputs), "\n".join(outputs)]
		return
	if definition.entity_id == "DWELLING":
		var resident_rows: Array[String] = []
		for villager: Variant in villagers.values():
			if villager.home_id == building_details_id:
				resident_rows.append("• %s — %s | Hunger %d%% | Energy %d%%" % [villager.villager_name, villager.status_text(), roundi(villager.hunger), roundi(villager.energy)])
		building_details_body.text = "HOME\n\nBeds: %d / %d occupied\n\nResidents\n%s\n\nHealth: good" % [resident_rows.size(), definition.population_capacity, "\n".join(resident_rows) if not resident_rows.is_empty() else "None"]
		return
	building_details_body.text = "Status: complete\n\nHealth: good\n\nNo active production."


func select_villager(villager_id: String) -> bool:
	if not villagers.has(villager_id): return false
	if building_details_open: close_building_details()
	if villagers.has(selected_villager_id): villagers[selected_villager_id].selected = false; villagers[selected_villager_id].queue_redraw()
	selected_villager_id = villager_id
	villagers[villager_id].selected = true
	villagers[villager_id].queue_redraw()
	villager_panel.visible = true
	villager_name_edit.text = villagers[villager_id].villager_name
	villager_order_feedback.text = ""
	_update_villager_panel()
	return true


func cycle_villager_selection() -> void:
	var ids: Array = villagers.keys()
	ids.sort()
	var index := ids.find(selected_villager_id)
	select_villager(str(ids[(index + 1) % ids.size()]))


func close_villager_panel() -> void:
	if villagers.has(selected_villager_id): villagers[selected_villager_id].selected = false; villagers[selected_villager_id].queue_redraw()
	selected_villager_id = ""
	villager_order_mode = ""
	pending_order_source_id = ""
	villager_panel.visible = false


func _rename_selected_villager(value: String) -> void:
	if not villagers.has(selected_villager_id): return
	var clean := value.strip_edges().substr(0, 24)
	if clean.is_empty(): clean = villagers[selected_villager_id].villager_name
	villagers[selected_villager_id].villager_name = clean
	villager_name_edit.text = clean
	_update_villager_panel()


func _commit_villager_name() -> void:
	_rename_selected_villager(villager_name_edit.text)


func _update_villager_panel() -> void:
	if not villagers.has(selected_villager_id): return
	var villager: Variant = villagers[selected_villager_id]
	var task_text := "None"
	if not villager.task.is_empty() and str(villager.task.get("type", "transport")) == "work":
		var work_target: Variant = placed_targets.get(str(villager.task.target))
		task_text = "Work at %s" % (work_target.item_label if work_target != null else str(villager.task.target))
	elif not villager.task.is_empty() and str(villager.task.get("type", "transport")) == "move":
		task_text = "Move to selected point"
	elif not villager.task.is_empty():
		var resource: Variant = item_registry.get_item(str(villager.task.item))
		var source_target: Variant = placed_targets.get(str(villager.task.source))
		var destination_target: Variant = placed_targets.get(str(villager.task.destination))
		task_text = "Carry %s\n%s → %s" % [resource.label if resource != null else str(villager.task.item), source_target.item_label if source_target != null else str(villager.task.source), destination_target.item_label if destination_target != null else str(villager.task.destination)]
	villager_status_label.text = "Home: %s\nStatus: %s\n\nHunger   %d%%\nEnergy   %d%%\n\nTask: %s\nCarrying: %s" % [villager.home_id, villager.status_text(), roundi(villager.hunger), roundi(villager.energy), task_text, "nothing" if villager.carrying_amount == 0 else "%s x%d" % [villager.carrying_item, villager.carrying_amount]]


func begin_villager_transport_order() -> void:
	if not villagers.has(selected_villager_id): return
	villager_order_mode = "source"
	pending_order_source_id = ""
	villager_resource_option.clear()
	villager_resource_option.visible = false
	villager_order_feedback.text = "Click a completed crate or machine as SOURCE."


func begin_villager_work_order() -> void:
	if not villagers.has(selected_villager_id): return
	villager_order_mode = "work"
	pending_order_source_id = ""
	villager_resource_option.visible = false
	villager_order_feedback.text = "Click a kiln or construction site as WORKPLACE."


func stop_selected_villager_task() -> void:
	if not villagers.has(selected_villager_id): return
	var villager: Variant = villagers[selected_villager_id]
	for index in range(logistics_routes.size() - 1, -1, -1):
		if logistics_routes[index].villager_id == selected_villager_id: logistics_routes.remove_at(index)
	villager.clear_task()
	villager_order_feedback.text = "Task stopped."
	queue_redraw()


func _handle_villager_world_click(screen_position: Vector2) -> bool:
	if scenario_select_open or crafting_open or storage_open or machine_open or placement_mode or building_details_open: return false
	var world_position: Vector2 = get_canvas_transform().affine_inverse() * screen_position
	if not villager_order_mode.is_empty():
		var endpoint: Variant = _placed_target_at(world_position)
		if endpoint == null:
			villager_order_feedback.text = "Select a completed crate or machine."
			return true
		return _handle_order_endpoint(endpoint.stable_id)
	var clicked_object: Variant = _any_placed_target_at(world_position)
	if clicked_object != null:
		return open_building_details(clicked_object.stable_id)
	var nearest: Variant = null
	var distance := 28.0
	for villager: Variant in villagers.values():
		var candidate: float = villager.global_position.distance_to(world_position)
		if candidate < distance: nearest = villager; distance = candidate
	if nearest != null:
		return select_villager(nearest.stable_id)
	if villagers.has(selected_villager_id):
		villagers[selected_villager_id].assign_move(world_position)
		villager_order_feedback.text = "Moving to selected point."
		return true
	return false


func _any_placed_target_at(world_position: Vector2) -> Variant:
	for target: Variant in placed_targets.values():
		for point: Vector2 in target.interaction_points:
			if point.distance_to(world_position) <= CELL_SIZE * 0.7: return target
	return null


func _make_item_icon(at: Vector2, dimensions: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.position = at
	icon.size = dimensions
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _sync_item_icon(icon: TextureRect, slot: Dictionary) -> void:
	icon.visible = not slot.is_empty()
	icon.texture = null if slot.is_empty() else ItemIconAtlasType.icon(str(slot.item_id))


func _placed_target_at(world_position: Vector2) -> Variant:
	for target: Variant in placed_targets.values():
		if villager_order_mode == "work":
			if target.target_kind != "construction" and target.target_kind != "machine": continue
		elif target.target_kind != "storage" and target.target_kind != "machine": continue
		for point: Vector2 in target.interaction_points:
			if point.distance_to(world_position) <= CELL_SIZE * 0.7: return target
	return null


func _handle_order_endpoint(instance_id: String) -> bool:
	if villager_order_mode == "work":
		villagers[selected_villager_id].assign_work(instance_id)
		villager_order_mode = ""
		villager_order_feedback.text = "Work order assigned."
		return true
	if villager_order_mode == "source":
		pending_order_source_id = instance_id
		villager_resource_option.clear()
		var source_inventory: Variant = _route_source_inventory(instance_id)
		if machines_by_entity_id.has(instance_id):
			for output_id: String in machines_by_entity_id[instance_id].recipe_outputs:
				villager_resource_option.add_item(item_registry.get_item(output_id).label)
				villager_resource_option.set_item_metadata(villager_resource_option.item_count - 1, output_id)
		elif storage_by_entity_id.has(instance_id):
			for resource_id: String in item_registry.item_order:
				var definition: Variant = item_registry.get_item(resource_id)
				if definition == null or not definition.placeable_entity_id.is_empty(): continue
				villager_resource_option.add_item(definition.label)
				villager_resource_option.set_item_metadata(villager_resource_option.item_count - 1, resource_id)
		elif source_inventory != null:
			var added: Dictionary = {}
			for slot: Dictionary in source_inventory.slots:
				if slot.is_empty() or added.has(slot.item_id): continue
				villager_resource_option.add_item(item_registry.get_item(slot.item_id).label)
				villager_resource_option.set_item_metadata(villager_resource_option.item_count - 1, slot.item_id)
				added[slot.item_id] = true
		if villager_resource_option.item_count == 0:
			villager_order_feedback.text = "That source has no transportable resources."
			return true
		villager_resource_option.visible = true
		villager_order_mode = "destination"
		villager_order_feedback.text = "Choose the resource above, then click DESTINATION."
		return true
	if instance_id == pending_order_source_id:
		villager_order_feedback.text = "Destination must be different from source."
		return true
	var item_id := str(villager_resource_option.get_item_metadata(villager_resource_option.selected))
	if not _destination_accepts(instance_id, item_id):
		villager_order_feedback.text = "Destination does not accept %s." % item_registry.get_item(item_id).label
		return true
	create_logistics_route(pending_order_source_id, instance_id, selected_villager_id, item_id)
	villager_order_mode = ""
	pending_order_source_id = ""
	villager_resource_option.visible = false
	villager_order_feedback.text = "Transport order assigned."
	return true


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
	crafting_panel.position = Vector2(290, 125)
	crafting_panel.size = Vector2(700, 450)
	crafting_panel.color = Color("#d8bd83")
	crafting_panel.visible = false
	layer.add_child(crafting_panel)
	var title := Label.new()
	title.position = Vector2(24, 20)
	title.text = "WORKBENCH — CHOOSE A RECIPE"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#3b281b"))
	crafting_panel.add_child(title)
	crafting_list_label = Label.new()
	crafting_list_label.position = Vector2(24, 78)
	crafting_list_label.size = Vector2(300, 300)
	crafting_list_label.add_theme_font_size_override("font_size", 18)
	crafting_list_label.add_theme_color_override("font_color", Color("#3b281b"))
	crafting_panel.add_child(crafting_list_label)
	for index in range(recipe_registry.recipe_order.size()):
		var recipe: Variant = recipe_registry.get_recipe(recipe_registry.recipe_order[index])
		var button := Button.new()
		button.position = Vector2(22, 74 + index * 43)
		button.size = Vector2(292, 38)
		button.text = "%d.  %s" % [index + 1, recipe.label]
		if not recipe.outputs.is_empty(): button.icon = ItemIconAtlasType.icon(str(recipe.outputs.keys()[0]))
		button.add_theme_constant_override("icon_max_width", 30)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_recipe_button_pressed.bind(index))
		crafting_panel.add_child(button)
		crafting_recipe_buttons.append(button)
	crafting_list_label.visible = false
	crafting_detail_label = Label.new()
	crafting_detail_label.position = Vector2(375, 78)
	crafting_detail_label.size = Vector2(295, 300)
	crafting_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crafting_detail_label.add_theme_font_size_override("font_size", 17)
	crafting_detail_label.add_theme_color_override("font_color", Color("#3b281b"))
	crafting_panel.add_child(crafting_detail_label)
	for index in range(8):
		var resource_icon := _make_item_icon(Vector2(345, 142 + index * 25), Vector2(23, 23))
		crafting_panel.add_child(resource_icon)
		crafting_resource_icons.append(resource_icon)
	var controls := Label.new()
	controls.position = Vector2(24, 405)
	controls.text = "Click a recipe, or W/S + Space to craft    C/Esc/B closes"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("#3b281b"))
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
	for index in range(inventory.slot_count):
		var player_icon := _make_item_icon(Vector2(42, 96 + index * 21), Vector2(20, 20))
		storage_panel.add_child(player_icon)
		storage_player_icons.append(player_icon)
	storage_contents_label = Label.new()
	storage_contents_label.position = Vector2(355, 68)
	storage_contents_label.size = Vector2(300, 270)
	storage_contents_label.add_theme_font_size_override("font_size", 16)
	storage_panel.add_child(storage_contents_label)
	for index in range(12):
		var crate_icon := _make_item_icon(Vector2(373, 96 + index * 21), Vector2(20, 20))
		storage_panel.add_child(crate_icon)
		storage_crate_icons.append(crate_icon)
	storage_feedback_label = Label.new()
	storage_feedback_label.position = Vector2(24, 340)
	storage_feedback_label.size = Vector2(630, 36)
	storage_feedback_label.add_theme_font_size_override("font_size", 16)
	storage_panel.add_child(storage_feedback_label)
	var controls := Label.new()
	controls.position = Vector2(24, 382)
	controls.text = "Left/Right: choose inventory    Up/Down: choose item    Space: move stack    Esc: close"
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
	if not crafting_open and not storage_open and not machine_open and _selected_placeable_definition() != null:
		begin_placement()


func begin_placement() -> bool:
	var definition: Variant = _selected_placeable_definition()
	if definition == null:
		interaction_label.text = "Selected slot is not placeable"
		return false
	placement_mode = true
	player.movement_enabled = true
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
	placement_feedback = "Space = Place" if validation.valid else "Blocked: %s" % validation.reason
	interaction_label.text = "%s   %s   | Walk to move ghost | R rotate, Esc cancel" % [definition.label, placement_feedback]


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


func _on_recipe_button_pressed(index: int) -> void:
	selected_recipe_index = index
	craft_selected_recipe()


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
	for index in range(crafting_recipe_buttons.size()):
		crafting_recipe_buttons[index].modulate = Color("#fff0be") if index == selected_recipe_index else Color.WHITE
	var selected: Variant = recipe_registry.get_recipe(recipe_registry.recipe_order[selected_recipe_index])
	var ingredients: Array[String] = []
	var icon_index := 0
	for icon: TextureRect in crafting_resource_icons: icon.visible = false
	for item_id: String in selected.inputs:
		var definition: Variant = item_registry.get_item(item_id)
		ingredients.append("%s: %d / %d" % [definition.label, inventory.count(item_id), int(selected.inputs[item_id])])
		if icon_index < crafting_resource_icons.size():
			crafting_resource_icons[icon_index].position.y = 139 + icon_index * 22
			crafting_resource_icons[icon_index].texture = ItemIconAtlasType.icon(item_id)
			crafting_resource_icons[icon_index].visible = true
			icon_index += 1
	var outputs: Array[String] = []
	for item_id: String in selected.outputs:
		var definition: Variant = item_registry.get_item(item_id)
		outputs.append("%s x%d" % [definition.label, int(selected.outputs[item_id])])
		if icon_index < crafting_resource_icons.size():
			crafting_resource_icons[icon_index].position.y = 183 + selected.inputs.size() * 22 + (icon_index - selected.inputs.size()) * 22
			crafting_resource_icons[icon_index].texture = ItemIconAtlasType.icon(item_id)
			crafting_resource_icons[icon_index].visible = true
			icon_index += 1
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
		queue_redraw()
	if interaction_label != null:
		if interaction_target == null:
			interaction_label.text = "ROUTE: approach destination and press R" if not route_source_id.is_empty() else "Approach a resource stack or placed object"
		elif interaction_target.target_kind == "pickup":
			interaction_label.text = "%s x%d   Space = Pick up" % [interaction_target.item_label, interaction_target.amount]
		elif interaction_target.target_kind == "construction":
			interaction_label.text = _construction_prompt(interaction_target.stable_id)
		elif interaction_target.target_kind == "machine":
			interaction_label.text = _machine_prompt(interaction_target.stable_id)
		else:
			interaction_label.text = "Space to Open %s" % interaction_target.item_label
		if not route_source_id.is_empty() and interaction_target != null:
			interaction_label.text = "ROUTE SOURCE SET | Approach destination and press R | " + interaction_label.text


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
	queue_redraw()
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
		if active_player_build_id == instance_id: active_player_build_id = ""
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
			if definition.entity_id == "DWELLING":
				spawn_villagers_for_home(instance_id, definition.population_capacity)
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
		return "Space  Place selected | Missing: %s" % ", ".join(missing)
	return "Hold Space to build  %d%%" % roundi(site.work_progress() * 100.0)


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


func machine_context_action(instance_id: String) -> int:
	var machine: Variant = machines_by_entity_id.get(instance_id)
	if machine == null: return 0
	if not inventory.slots[selected_slot].is_empty():
		var item_id: String = inventory.slots[selected_slot].item_id
		if (machine.broken and item_id == "wood") or machine.accepts(item_id):
			return deliver_selected_to_machine(instance_id)
	return withdraw_machine_output(instance_id)


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
		return "Kiln broken | Space to open"
	var output_count := 0
	for item_id: String in machine.recipe_outputs:
		output_count += machine.output_inventory.count(item_id)
	if machine.is_running():
		return "Kiln firing %d%% | Output %d | Space to open" % [roundi(machine.progress() * 100.0), output_count]
	return "Kiln ready | Output %d | Space to open" % output_count


func open_machine(instance_id: String) -> bool:
	if not machines_by_entity_id.has(instance_id): return false
	machine_open = true
	active_machine_id = instance_id
	player.movement_enabled = false
	player.velocity = Vector2.ZERO
	machine_panel.visible = true
	interaction_target = null
	queue_redraw()
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
	var worker_names: Array[String] = []
	for villager: Variant in villagers.values():
		if not villager.task.is_empty() and str(villager.task.get("type", "")) == "work" and str(villager.task.get("target", "")) == active_machine_id:
			worker_names.append(villager.villager_name)
	machine_status_label.text = "State: %s\nHealth: %d / %d\nWorker: %s\nProgress: %d%%\n\nINPUT\n%s\n\nACCUMULATED OUTPUT\n%s" % [state, machine.durability, machine.max_durability, ", ".join(worker_names) if not worker_names.is_empty() else "none", roundi(machine.progress() * 100.0), "\n".join(input_rows), "\n".join(output_rows)]


func select_route_endpoint(instance_id: String) -> bool:
	if instance_id.is_empty() or not placed_targets.has(instance_id):
		interaction_label.text = "No valid route endpoint selected"
		return false
	var target: Variant = placed_targets[instance_id]
	if target.target_kind != "storage" and target.target_kind != "machine":
		interaction_label.text = "Complete this building before connecting a route"
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


func create_logistics_route(source_id: String, destination_id: String, villager_id: String = "", item_id: String = "") -> bool:
	if not placed_targets.has(source_id) or not placed_targets.has(destination_id):
		return false
	var source_valid := storage_by_entity_id.has(source_id) or machines_by_entity_id.has(source_id)
	var destination_valid := storage_by_entity_id.has(destination_id) or machines_by_entity_id.has(destination_id)
	if not source_valid or not destination_valid:
		return false
	if villager_id.is_empty():
		villager_id = selected_villager_id
	if not villagers.has(villager_id):
		interaction_label.text = "Select a villager before creating a route"
		return false
	if item_id.is_empty():
		var source_inventory: Variant = _route_source_inventory(source_id)
		if source_inventory != null:
			for slot: Dictionary in source_inventory.slots:
				if not slot.is_empty() and _destination_accepts(destination_id, slot.item_id): item_id = slot.item_id; break
	if item_id.is_empty() or not _destination_accepts(destination_id, item_id):
		interaction_label.text = "No compatible resource for this route"
		return false
	for route: Variant in logistics_routes:
		if route.source_id == source_id and route.destination_id == destination_id and route.villager_id == villager_id and route.item_id == item_id:
			return false
	for route: Variant in logistics_routes:
		if route.villager_id == villager_id:
			logistics_routes.erase(route)
			break
	var route := PhysicalRouteType.new("route-%04d" % next_route_id, source_id, destination_id, 2.0, villager_id, item_id)
	logistics_routes.append(route)
	villagers[villager_id].assign_transport(route.route_id, source_id, destination_id, item_id)
	next_route_id += 1
	interaction_label.text = "Porter route created"
	queue_redraw()
	return true


func _route_source_inventory(source_id: String) -> Variant:
	if storage_by_entity_id.has(source_id): return storage_by_entity_id[source_id]
	if machines_by_entity_id.has(source_id): return machines_by_entity_id[source_id].output_inventory
	return null


func _destination_accepts(destination_id: String, item_id: String) -> bool:
	if storage_by_entity_id.has(destination_id): return storage_by_entity_id[destination_id].capacity_for(item_id) > 0
	if machines_by_entity_id.has(destination_id): return machines_by_entity_id[destination_id].accepts(item_id)
	return false


func villager_collect(villager: Variant) -> int:
	var source: Variant = _route_source_inventory(str(villager.task.source))
	if source == null: return 0
	var amount := mini(3, source.count(str(villager.task.item)))
	if amount <= 0: return 0
	source.remove(str(villager.task.item), amount)
	villager.carrying_item = str(villager.task.item)
	villager.carrying_amount = amount
	return amount


func villager_deliver(villager: Variant) -> int:
	if villager.carrying_amount <= 0: return 0
	var accepted := 0
	var delivered_item: String = villager.carrying_item
	var destination_id := str(villager.task.destination)
	if machines_by_entity_id.has(destination_id): accepted = machines_by_entity_id[destination_id].add_input(villager.carrying_item, villager.carrying_amount)
	elif storage_by_entity_id.has(destination_id): accepted = storage_by_entity_id[destination_id].add(villager.carrying_item, villager.carrying_amount)
	villager.carrying_amount -= accepted
	if villager.carrying_amount <= 0: villager.carrying_item = ""
	var route_id := str(villager.task.route_id)
	for route: Variant in logistics_routes:
		if route.route_id == route_id and accepted > 0:
			route.trips_completed += 1
			route.last_item_id = delivered_item
	return accepted


func spawn_villagers_for_home(home_id: String, count: int) -> void:
	var existing := 0
	for villager: Variant in villagers.values():
		if villager.home_id == home_id: existing += 1
	var home_target: Variant = placed_targets.get(home_id)
	if home_target == null: return
	for index in range(existing, count):
		var villager_id := "villager-%04d" % next_villager_id
		var display_name := VILLAGER_NAMES[(next_villager_id - 1) % VILLAGER_NAMES.size()]
		var tint: Color = [Color("#f1d8ba"), Color("#d5e6f2"), Color("#f2d4df"), Color("#dce8c2")][(next_villager_id - 1) % 4]
		var villager: Variant = VillagerType.new()
		villager.configure(villager_id, display_name, home_id, home_target.global_position + Vector2((index * 14) - 7, 28), tint)
		add_child(villager)
		villagers[villager_id] = villager
		next_villager_id += 1
	_refresh_population_capacity()
	queue_redraw()


func restore_villager(data: Dictionary) -> Variant:
	var villager_id := str(data.get("id", "villager-%04d" % next_villager_id))
	var home_id := str(data.get("home", ""))
	var home_target: Variant = placed_targets.get(home_id)
	var fallback_position: Vector2 = home_target.global_position if home_target != null else player.global_position
	var values: Array = data.get("position", [fallback_position.x, fallback_position.y])
	var tint_values: Array = data.get("tint", [1.0, 1.0, 1.0, 1.0])
	var villager: Variant = VillagerType.new()
	villager.configure(villager_id, str(data.get("name", "Villager")), home_id, Vector2(float(values[0]), float(values[1])), Color(float(tint_values[0]), float(tint_values[1]), float(tint_values[2]), float(tint_values[3])))
	villager.home_position = Vector2(float(data.get("home_position", [fallback_position.x, fallback_position.y])[0]), float(data.get("home_position", [fallback_position.x, fallback_position.y])[1]))
	villager.hunger = float(data.get("hunger", 100.0))
	villager.energy = float(data.get("energy", 100.0))
	villager.state = str(data.get("state", "available"))
	villager.facing = str(data.get("facing", "south"))
	villager.task = data.get("task", {}).duplicate(true)
	villager.carrying_item = str(data.get("carrying_item", ""))
	villager.carrying_amount = int(data.get("carrying_amount", 0))
	add_child(villager)
	villagers[villager_id] = villager
	next_villager_id = maxi(next_villager_id, int(villager_id.get_slice("-", 1)) + 1)
	return villager


func is_sleep_time() -> bool:
	var fraction := day_time_seconds / DAY_LENGTH_SECONDS
	return fraction >= 0.78 or fraction < 0.16


func find_food_storage_for(villager: Variant) -> Variant:
	var nearest: Variant = null
	var distance := INF
	for instance_id: String in storage_by_entity_id:
		if storage_by_entity_id[instance_id].count("food_ration") <= 0: continue
		var target: Variant = placed_targets.get(instance_id)
		if target == null: continue
		var candidate: float = villager.global_position.distance_squared_to(target.global_position)
		if candidate < distance: nearest = target; distance = candidate
	return nearest


func consume_food_from_storage(storage_id: String) -> bool:
	if not storage_by_entity_id.has(storage_id): return false
	return storage_by_entity_id[storage_id].remove("food_ration", 1) == 1


func assigned_villagers_to(instance_id: String) -> int:
	var count := 0
	for villager: Variant in villagers.values():
		if villager.state == "working" and not villager.task.is_empty() and str(villager.task.get("type", "")) == "work" and str(villager.task.get("target", "")) == instance_id:
			count += 1
	return count


func villager_work(villager: Variant, delta: float) -> void:
	if villager.task.is_empty(): return
	var instance_id := str(villager.task.get("target", ""))
	if construction_by_entity_id.has(instance_id):
		var site: Variant = construction_by_entity_id[instance_id]
		if not site.complete and site.materials_complete():
			apply_construction_work(instance_id, delta)
			if site.complete:
				villager.clear_task()


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
	storage_focus_side = 0
	player.movement_enabled = false
	player.velocity = Vector2.ZERO
	storage_panel.visible = true
	if is_instance_valid(interaction_target):
		interaction_target.set_targeted(false)
	interaction_target = null
	queue_redraw()
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


func set_storage_focus(side: int) -> void:
	storage_focus_side = clampi(side, 0, 1)
	_update_storage_ui("Space moves the selected stack to the other side.")


func select_active_storage_slot(direction: int) -> void:
	if storage_focus_side == 0:
		selected_slot = posmod(selected_slot + direction, inventory.slots.size())
		_update_inventory_hud()
	else:
		select_storage_slot(direction)
	_update_storage_ui()


func transfer_storage_selected() -> int:
	return deposit_selected_stack() if storage_focus_side == 0 else withdraw_selected_stack()


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
	var player_rows: Array[String] = ["▶ PLAYER INVENTORY" if storage_focus_side == 0 else "  PLAYER INVENTORY"]
	for index in range(inventory.slots.size()):
		var slot: Dictionary = inventory.slots[index]
		player_rows.append("%s      [%d] %s" % [">" if storage_focus_side == 0 and index == selected_slot else " ", index + 1, _slot_text(slot)])
		if index < storage_player_icons.size(): _sync_item_icon(storage_player_icons[index], slot)
	storage_player_label.text = "\n".join(player_rows)
	storage_player_label.add_theme_color_override("font_color", Color("#ffe27a") if storage_focus_side == 0 else Color("#b9b3a7"))
	var storage_rows: Array[String] = ["▶ CRATE INVENTORY" if storage_focus_side == 1 else "  CRATE INVENTORY"]
	for index in range(storage.slots.size()):
		storage_rows.append("%s      [%d] %s" % [">" if storage_focus_side == 1 and index == selected_storage_slot else " ", index + 1, _slot_text(storage.slots[index])])
		if index < storage_crate_icons.size(): _sync_item_icon(storage_crate_icons[index], storage.slots[index])
	for index in range(storage.slots.size(), storage_crate_icons.size()): storage_crate_icons[index].visible = false
	storage_contents_label.text = "\n".join(storage_rows)
	storage_contents_label.add_theme_color_override("font_color", Color("#ffe27a") if storage_focus_side == 1 else Color("#b9b3a7"))
	storage_feedback_label.text = feedback


func _slot_text(slot: Dictionary) -> String:
	if slot.is_empty():
		return "--"
	var definition: Variant = item_registry.get_item(slot.item_id)
	return "%s x%d" % [definition.label, int(slot.amount)]


func _update_inventory_hud() -> void:
	if inventory_label == null:
		return
	for index in range(inventory.slots.size()):
		var slot: Dictionary = inventory.slots[index]
		if index < inventory_icons.size(): _sync_item_icon(inventory_icons[index], slot)
		var selected_prefix := "> " if index == selected_slot else ""
		if slot.is_empty():
			if index < inventory_slot_labels.size(): inventory_slot_labels[index].text = "%s%d  Empty" % [selected_prefix, index + 1]
		else:
			var definition: Variant = item_registry.get_item(slot.item_id)
			if index < inventory_slot_labels.size(): inventory_slot_labels[index].text = "%s%d  %s\nx%d" % [selected_prefix, index + 1, definition.label, int(slot.amount)]
		if index < inventory_slot_labels.size():
			inventory_slot_labels[index].add_theme_color_override("font_color", Color("#ffe27a") if index == selected_slot else Color.WHITE)
		if index < inventory_icons.size(): inventory_icons[index].modulate = Color("#ffe27a") if index == selected_slot else Color.WHITE
	_update_population_hud()


func _update_population_hud() -> void:
	if population_label != null and workforce != null:
		var active := 0
		var food := 0
		for villager: Variant in villagers.values():
			if not villager.task.is_empty(): active += 1
		for storage: Variant in storage_by_entity_id.values(): food += storage.count("food_ration")
		var total_minutes := roundi(day_time_seconds / DAY_LENGTH_SECONDS * 24.0 * 60.0)
		population_label.text = "%d people | %d assigned | %d meals | Day %02d:%02d" % [1 + villagers.size(), active, food, (total_minutes / 60) % 24, total_minutes % 60]


func _refresh_population_capacity() -> void:
	workforce.set_population(1 + villagers.size())
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
			if site == null or site.complete:
				_draw_structure_sprite(placed.definition_id, placed.cells)
	if placement_mode:
		var definition: Variant = _selected_placeable_definition()
		if definition != null:
			var validation: Dictionary = _placement_validation(definition)
			for cell: Vector2i in validation.cells:
				var preview_rect := Rect2(Vector2(cell * CELL_SIZE) + Vector2.ONE, Vector2.ONE * (CELL_SIZE - 2))
				draw_rect(preview_rect, Color(0.2, 0.9, 0.4, 0.58) if validation.valid else Color(0.95, 0.2, 0.2, 0.62))
				draw_rect(preview_rect, Color.WHITE, false, 2.0)
			_draw_structure_sprite(definition.entity_id, validation.cells, true, validation.valid)
	for route: Variant in logistics_routes:
		var from_target: Variant = placed_targets.get(route.source_id)
		var to_target: Variant = placed_targets.get(route.destination_id)
		if from_target == null or to_target == null:
			continue
		var start: Vector2 = from_target.global_position
		var finish: Vector2 = to_target.global_position
		draw_line(start, finish, Color("#e1bd62"), 3.0)
		var midpoint := start.lerp(finish, 0.5)
		draw_circle(midpoint, 4.0, Color("#ffe27a"))
	if not route_source_id.is_empty():
		var source_target: Variant = placed_targets.get(route_source_id)
		if source_target != null:
			draw_circle(source_target.global_position, 23.0, Color("#ffe27a"), false, 4.0)


func _draw_structure_sprite(definition_id: String, cells: Array[Vector2i], ghost: bool = false, valid: bool = true) -> void:
	var columns := {"STORAGE_CRATE": 0, "BRICK_KILN": 1, "DWELLING": 2, "SHRINE": 3}
	if not columns.has(definition_id) or cells.is_empty(): return
	var minimum := cells[0]
	var maximum := cells[0]
	for cell: Vector2i in cells:
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	var footprint_size := Vector2(maximum - minimum + Vector2i.ONE) * CELL_SIZE
	var sprite_size := Vector2(maxf(48.0, footprint_size.x + 20.0), maxf(56.0, footprint_size.y + 28.0))
	if definition_id == "SHRINE": sprite_size.y += 20.0
	var bottom_center := Vector2((minimum.x + maximum.x + 1) * CELL_SIZE * 0.5, (maximum.y + 1) * CELL_SIZE)
	var destination := Rect2(bottom_center - Vector2(sprite_size.x * 0.5, sprite_size.y), sprite_size)
	var tint := Color(0.45, 1.0, 0.55, 0.62) if valid else Color(1.0, 0.35, 0.35, 0.62)
	draw_texture_rect_region(BUILDING_TEXTURE, destination, Rect2(int(columns[definition_id]) * 256, 0, 256, 256), tint if ghost else Color.WHITE)
