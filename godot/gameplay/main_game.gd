class_name MainGame
extends Node2D

const PlayerScene = preload("res://player/player.tscn")
const ItemRegistryType = preload("res://items/item_registry.gd")
const PlayerInventoryType = preload("res://player/player_inventory.gd")
const PickupType = preload("res://world/items/world_pickup.gd")
const ResourceSourceType = preload("res://world/items/resource_source.gd")
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
const ECONOMY_BUILDING_TEXTURE = preload("res://assets/generated/buildings/egypt_economy_buildings_sheet.png")
const SHRINE_TEXTURE = preload("res://assets/generated/buildings/egypt_shrine_v2.png")
const INDUSTRY_BUILDING_TEXTURE = preload("res://assets/generated/buildings/egypt_industry_buildings.png")
const PhysicalMachineType = preload("res://world/machines/physical_machine.gd")
const PhysicalRouteType = preload("res://world/logistics/physical_route.gd")
const PhysicalWorkforceType = preload("res://world/population/physical_workforce.gd")
const VillagerType = preload("res://world/population/villager.gd")
const DependentActorType = preload("res://world/population/dependent_actor.gd")
const ItemIconAtlasType = preload("res://items/item_icon_atlas.gd")
const WorldOverlayType = preload("res://world/interaction/world_overlay.gd")
const TerrainRendererType = preload("res://world/terrain/terrain_renderer.gd")
const TreeCropType = preload("res://world/crops/tree_crop.gd")
const StructureVisualType = preload("res://world/placement/structure_visual.gd")
const GameThemeType = preload("res://ui/game_theme.gd")
const SAND_TEXTURE = preload("res://assets/generated/terrain/sand_v2.png")
const WATER_TEXTURE = preload("res://assets/generated/terrain/water_v2.png")
const SHORELINE_TEXTURE = preload("res://assets/generated/terrain/shoreline_v2.png")
const SHORELINE_CORNER_TEXTURE = preload("res://assets/generated/terrain/shoreline_inner_corners_v2.png")
const TREE_GROWTH_TEXTURE = preload("res://assets/generated/crops/tree_growth_v3.png")
const PICKUP_SOUND = preload("res://assets/audio/pickup.wav")
const CRAFT_SOUND = preload("res://assets/audio/craft.wav")
const BUILD_SOUND = preload("res://assets/audio/build_complete.wav")

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
var path_cells: Dictionary = {}
var item_registry: Variant
var inventory: Variant
var pickups: Array = []
var resource_sources: Array = []
var crops: Array = []
var water_interaction_target: Variant
var interaction_target: Variant = null
var recipe_registry: Variant
var crafting: Variant
var crafting_open := false
var selected_recipe_index := 0
var crafting_panel: Control
var crafting_list_label: Label
var crafting_detail_label: RichTextLabel
var crafting_recipe_buttons: Array[Button] = []
var crafting_resource_icons: Array[TextureRect] = []
var crafting_recipe_scroll: ScrollContainer
var placement_registry: Variant
var world_grid: Variant
var selected_slot := 0
var placement_mode := false
var placement_cursor := Vector2i.ZERO
var placement_rotation := 0
var next_placed_id := 1
var placement_feedback := ""
var placed_targets: Dictionary = {}
var structure_visuals: Dictionary = {}
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
var storage_player_rows: Array[ColorRect] = []
var storage_crate_rows: Array[ColorRect] = []
var storage_player_slot_labels: Array[Label] = []
var storage_crate_slot_labels: Array[Label] = []
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
var ground_texture: Texture2D
var path_texture: Texture2D
var scenario_panel: Control
var scenario_select_open := false
var pause_panel: Control
var pause_open := false
var logistics_panel: Control
var logistics_open := false
var logistics_list: ItemList
var logistics_detail: Label
var selected_route_index := 0
var autosave_elapsed := 0.0
const AUTOSAVE_INTERVAL_SECONDS := 90.0
var machine_open := false
var active_machine_id := ""
var machine_panel: Control
var machine_status_label: Label
var machine_title_label: Label
var machine_worker_icon: TextureRect
var machine_remove_worker_button: Button
var villagers: Dictionary = {}
var dependents: Dictionary = {}
var next_dependent_id := 1
var next_villager_id := 1
var selected_villager_id := ""
var villager_panel: Control
var villager_name_edit: LineEdit
var villager_appearance_option: OptionButton
var villager_priority_option: OptionButton
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
var building_details_controls: Label
var construction_delivery_popup: ColorRect
var construction_delivery_label: Label
var construction_delivery_icons: Array[TextureRect] = []
var world_overlay: Node2D
var terrain_renderer: Node2D
var active_player_build_id := ""
var day_time_seconds := 60.0
const DAY_LENGTH_SECONDS := 240.0
const VILLAGER_NAMES: Array[String] = ["Nefru", "Merit", "Hori", "Tia", "Bek", "Kiya", "Sabu", "Ipu", "Nebet", "Dagi"]
var feedback_audio: AudioStreamPlayer


func _ready() -> void:
	scenario = PhysicalScenarioType.new()
	var auto_start := PhysicalScenarioType.requested_autostart
	PhysicalScenarioType.requested_autostart = false
	if not PhysicalScenarioType.requested_path.is_empty():
		scenario_path = PhysicalScenarioType.requested_path
		PhysicalScenarioType.requested_path = ""
	assert(scenario.load_from_path(scenario_path) == OK, "Physical scenario must load")
	get_tree().root.theme = GameThemeType.create(scenario.theme)
	ground_texture = load(scenario.ground_texture_path) as Texture2D
	path_texture = load(scenario.path_texture_path) as Texture2D if not scenario.path_texture_path.is_empty() else null
	sand_color = scenario.sand_color
	water_color = scenario.water_color
	workforce = PhysicalWorkforceType.new()
	campaign = EgyptCampaignType.new(scenario.campaign_path)
	physical_save = PhysicalSaveCodecType.new()
	feedback_audio = AudioStreamPlayer.new()
	add_child(feedback_audio)
	_build_terrain()
	terrain_renderer = TerrainRendererType.new()
	terrain_renderer.configure(self)
	add_child(terrain_renderer)
	_build_boundaries()
	_build_player()
	_build_items()
	_build_hud()
	world_overlay = WorldOverlayType.new()
	world_overlay.configure(self)
	add_child(world_overlay)
	if DisplayServer.get_name() != "headless" and not auto_start:
		set_scenario_select_open(true)
	if PhysicalSaveCodecType.pending_reload:
		PhysicalSaveCodecType.pending_reload = false
		physical_save.load_from_path(self, PhysicalSaveCodecType.pending_reload_path)
		PhysicalSaveCodecType.pending_reload_path = _manual_save_path()
	queue_redraw()


func _process(delta: float) -> void:
	if pause_open: return
	day_time_seconds = fmod(day_time_seconds + maxf(delta, 0.0), DAY_LENGTH_SECONDS)
	autosave_elapsed += maxf(delta, 0.0)
	if autosave_elapsed >= AUTOSAVE_INTERVAL_SECONDS and not scenario_select_open:
		autosave_elapsed = 0.0
		physical_save.save_to_path(self, _autosave_path())
	workforce.process(delta)
	for villager: Variant in villagers.values():
		villager.environment_speed_multiplier = environment_multiplier("worker_speed")
		villager.process_life(self, delta)
	for dependent: Variant in dependents.values():
		if is_instance_valid(dependent): dependent.process_life(self, delta)
	for source: Variant in resource_sources:
		if is_instance_valid(source): source.process_source(delta)
	for crop: Variant in crops:
		if is_instance_valid(crop) and crop.process_growth(delta):
			queue_redraw()
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
		var build_site: Variant = construction_by_entity_id.get(active_player_build_id)
		if build_site == null or build_site.complete:
			active_player_build_id = ""
		else:
			apply_construction_work(active_player_build_id, delta)
	for machine: Variant in machines_by_entity_id.values():
		var definition: Variant = definition_for_instance(machine.instance_id)
		var required_workers := ceili(definition.workers_required) if definition != null else 1
		machine.staffed = required_workers <= 0 or assigned_villagers_to(machine.instance_id) >= required_workers
		machine.process(delta * worker_efficiency_at(machine.instance_id) * environment_multiplier("production_speed"))
		if structure_visuals.has(machine.instance_id):
			structure_visuals[machine.instance_id].set_machine_state(machine.is_running(), machine.broken, delta)
	campaign.refresh(machines_by_entity_id, logistics_routes, world_grid, villagers)
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
	# Window shortcuts must be handled before any focused UI Control consumes them.
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
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
	if pause_open:
		if event.is_action_pressed("cancel"):
			set_pause_open(false)
		return
	if logistics_open:
		if event.is_action_pressed("cancel") or event.is_action_pressed("open_logistics"):
			set_logistics_open(false)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _handle_villager_world_click(event.position):
			get_viewport().set_input_as_handled()
			return
	if not selected_villager_id.is_empty() and event.is_action_pressed("cancel"):
		close_villager_panel()
		return
	if not selected_villager_id.is_empty() and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right") or event.is_action_pressed("move_up") or event.is_action_pressed("move_down")):
		close_villager_panel()
	if event.is_action_pressed("zoom_in"):
		adjust_camera_zoom(1)
		return
	if event.is_action_pressed("zoom_out"):
		adjust_camera_zoom(-1)
		return
	if event.is_action_pressed("next_villager") and not villagers.is_empty():
		cycle_villager_selection()
		return
	if event.is_action_pressed("open_logistics"):
		set_logistics_open(true)
		return
	if building_details_open:
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right") or event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
			close_building_details()
			return
		if event.is_action_pressed("cancel"):
			close_building_details()
		elif event.is_action_pressed("use_selected"):
			building_details_context_action()
		return
	if scenario_select_open:
		if event.is_action_pressed("quick_slot_1"):
			select_scenario("res://scenarios/physical/prehistory.json")
		elif event.is_action_pressed("quick_slot_2"):
			select_scenario("res://scenarios/physical/ancient_egypt.json")
		elif event.is_action_pressed("quick_slot_3"):
			select_scenario("res://scenarios/physical/medieval.json")
		elif event.is_action_pressed("quick_slot_4"):
			select_scenario("res://scenarios/physical/mars_colony.json")
		return
	if machine_open:
		if event.is_action_pressed("cancel") or event.is_action_pressed("open_crafting"):
			close_machine()
		elif event.is_action_pressed("use_selected"):
			machine_context_action(active_machine_id)
		return
	if event.is_action_pressed("save_game"):
		var result: Error = physical_save.save_to_path(self, _manual_save_path())
		interaction_label.text = "Game saved" if result == OK else "Save failed"
		return
	if event.is_action_pressed("load_game"):
		if world_grid.entities_by_id.is_empty():
			var result: Error = physical_save.load_from_path(self, _manual_save_path())
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
		elif interaction_target != null and interaction_target.target_kind == "resource_source":
			collect_resource_source(interaction_target)
		elif interaction_target != null and interaction_target.target_kind == "water":
			collect_water()
		elif interaction_target != null and interaction_target.target_kind == "crop":
			interact_with_crop(interaction_target)
		elif interaction_target != null and interaction_target.target_kind == "dependent":
			interact_with_dependent(interaction_target)
		elif interaction_target != null and interaction_target.target_kind == "construction":
			open_building_details(interaction_target.stable_id)
		elif interaction_target != null and interaction_target.target_kind == "machine":
			open_machine(interaction_target.stable_id)
		elif interaction_target != null and interaction_target.target_kind == "storage":
			open_storage(interaction_target.stable_id)
		elif interaction_target != null and interaction_target.target_kind == "building":
			open_building_details(interaction_target.stable_id)
		elif interaction_target != null and interaction_target.target_kind == "villager":
			select_villager(interaction_target.stable_id)
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
		if event.is_action_pressed("cancel"):
			set_pause_open(true)


func _build_terrain() -> void:
	world_grid = WorldGridType.new(WORLD_SIZE, "sand")
	for values: Array in scenario.path_rects:
		for local_y in range(int(values[3])):
			for local_x in range(int(values[2])):
				var path_cell := Vector2i(int(values[0]) + local_x, int(values[1]) + local_y)
				if world_grid.contains(path_cell): path_cells[path_cell] = true
	for values: Array in scenario.water_rects:
		var origin_x := int(values[0]); var origin_y := int(values[1])
		var width := int(values[2]); var height := int(values[3])
		for local_y in range(height):
			var shift := roundi(sin(float(local_y + origin_y) * 0.72) * 0.85) if width >= 4 and height >= 4 else 0
			var end_rounding := maxi(0, 2 - mini(local_y, height - 1 - local_y)) if width >= 5 and height >= 4 else 0
			for local_x in range(end_rounding, width - end_rounding):
				var cell := Vector2i(origin_x + local_x + shift, origin_y + local_y)
				if world_grid.contains(cell): water_cells[cell] = true
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
	player.configure_character(scenario.character_sheet_path)
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
	var result: Error = item_registry.load_from_path(scenario.items_path)
	assert(result == OK, "Item definitions must load: %s" % str(item_registry.errors))
	inventory = PlayerInventoryType.new(item_registry, 12)
	recipe_registry = RecipeRegistryType.new()
	result = recipe_registry.load_from_path(scenario.recipes_path, item_registry)
	assert(result == OK, "Recipe definitions must load: %s" % str(recipe_registry.errors))
	crafting = CraftingSystemType.new(recipe_registry)
	placement_registry = DefinitionRegistryType.new()
	result = placement_registry.load_from_path(scenario.placeables_path)
	assert(result == OK, "Placeable definitions must load: %s" % str(placement_registry.errors))
	for pickup: Dictionary in scenario.pickups:
		_spawn_pickup(str(pickup.id), str(pickup.item), int(pickup.amount), Vector2(float(pickup.cell[0]), float(pickup.cell[1])) * CELL_SIZE)
	for source: Dictionary in scenario.resource_sources:
		_spawn_resource_source(source)
	for crop_data: Dictionary in scenario.crops:
		_spawn_crop(str(crop_data.id), Vector2i(int(crop_data.cell[0]), int(crop_data.cell[1])), int(crop_data.get("stage", 3)))
	for wildlife_data: Dictionary in scenario.wildlife:
		_spawn_wildlife(wildlife_data)
	water_interaction_target = PlacedTargetType.new()
	water_interaction_target.configure("water-body", "Water", Vector2.ZERO, Vector2.ZERO, "water")
	water_interaction_target.visible = false
	add_child(water_interaction_target)


func _spawn_pickup(stable_id: String, item_id: String, amount: int, world_position: Vector2) -> Variant:
	var definition: Variant = item_registry.get_item(item_id)
	assert(definition != null, "Pickup item must exist: %s" % item_id)
	var pickup := PickupType.new()
	pickup.position = world_position
	pickup.configure(stable_id, definition, amount)
	add_child(pickup)
	pickups.append(pickup)
	return pickup


func _spawn_resource_source(data: Dictionary) -> Variant:
	var definition: Variant = item_registry.get_item(str(data.item))
	assert(definition != null, "Resource source item must exist: %s" % str(data.item))
	var source := ResourceSourceType.new()
	source.position = Vector2(float(data.cell[0]), float(data.cell[1])) * CELL_SIZE
	source.configure(str(data.id), definition, int(data.get("initial", data.max)), int(data.max), int(data.grant), int(data.regen_amount), float(data.regen_seconds))
	add_child(source)
	resource_sources.append(source)
	return source


func _spawn_crop(stable_id: String, cell: Vector2i, stage: int = 0, occupy_grid: bool = true) -> Variant:
	var crop := TreeCropType.new()
	crop.position = Vector2(cell * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5)
	crop.configure(stable_id, cell, stage)
	add_child(crop)
	crops.append(crop)
	if occupy_grid and world_grid.occupant_at(cell).is_empty():
		var definition: Variant = placement_registry.get_entity("TREE_CROP")
		world_grid.place(stable_id, "TREE_CROP", definition.spatial_footprint, cell, 0, definition.allowed_terrain)
	return crop


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
	objective_label.size = Vector2(670, 58)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	_build_pause_panel(layer)
	_build_logistics_panel(layer)
	_build_mobile_controls(layer)
	for panel: Control in [crafting_panel, storage_panel, machine_panel, villager_panel, building_details_panel, scenario_panel, pause_panel, logistics_panel]:
		GameThemeType.decorate_panel(panel, panel == scenario_panel)
		_apply_scenario_panel_palette(panel)
	GameThemeType.decorate_panel(inventory_background, true)
	GameThemeType.emphasize_headings(layer)
	var help := Label.new()
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(22, -118)
	help.text = "Move: WASD    Action: Space    Villagers: click/Tab    Crafting: C    Routes: G    Menu: Esc"
	help.add_theme_color_override("font_color", Color.WHITE)
	help.add_theme_font_size_override("font_size", 16)
	layer.add_child(help)


func _apply_scenario_panel_palette(node: Node) -> void:
	var panel_color := Color(str(scenario.theme.get("panel", "#d8bd83")))
	var ink_color := Color(str(scenario.theme.get("ink", "#30241d")))
	if node is ColorRect and node != scenario_panel and node != pause_panel:
		(node as ColorRect).color = panel_color
	if node is Label or node is RichTextLabel:
		(node as Control).add_theme_color_override("font_color", ink_color)
	for child: Node in node.get_children(): _apply_scenario_panel_palette(child)


func _build_mobile_controls(layer: CanvasLayer) -> void:
	if not OS.has_feature("mobile"): return
	var directions := {
		"move_left": Vector2(24, 548), "move_right": Vector2(152, 548),
		"move_up": Vector2(88, 492), "move_down": Vector2(88, 604)
	}
	for action: String in directions:
		var button := Button.new()
		button.position = directions[action]
		button.size = Vector2(62, 52)
		button.text = {"move_left": "◀", "move_right": "▶", "move_up": "▲", "move_down": "▼"}[action]
		button.modulate.a = 0.82
		button.button_down.connect(func() -> void: Input.action_press(action))
		button.button_up.connect(func() -> void: Input.action_release(action))
		layer.add_child(button)
	var actions: Array[Dictionary] = [
		{"label": "ACTION", "action": "use_selected", "position": Vector2(1085, 548)},
		{"label": "CRAFT", "action": "open_crafting", "position": Vector2(950, 590)},
		{"label": "MENU", "action": "cancel", "position": Vector2(1090, 485)}
	]
	for row: Dictionary in actions:
		var button := Button.new()
		button.position = row.position
		button.size = Vector2(112, 52)
		button.text = row.label
		button.modulate.a = 0.86
		button.pressed.connect(func() -> void: _emit_action(str(row.action)))
		layer.add_child(button)


func _emit_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


func _build_pause_panel(layer: CanvasLayer) -> void:
	pause_panel = ColorRect.new()
	pause_panel.position = Vector2(430, 118)
	pause_panel.size = Vector2(420, 554)
	pause_panel.color = Color(0.05, 0.06, 0.08, 0.97)
	pause_panel.visible = false
	layer.add_child(pause_panel)
	var title := Label.new()
	title.position = Vector2(46, 34)
	title.size = Vector2(328, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "SETTLEMENT PAUSED"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#f0cc72"))
	pause_panel.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(46, 82)
	subtitle.size = Vector2(328, 42)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = "Your progress autosaves every 90 seconds"
	subtitle.add_theme_color_override("font_color", Color("#fff3d2"))
	pause_panel.add_child(subtitle)
	var actions: Array[Dictionary] = [
		{"label": "Continue", "call": func() -> void: set_pause_open(false)},
		{"label": "Save game", "call": func() -> void: _save_from_menu()},
		{"label": "Load last save", "call": func() -> void: _load_from_menu(_manual_save_path())},
		{"label": "Load autosave", "call": func() -> void: _load_from_menu(_autosave_path())},
		{"label": "Toggle fullscreen", "call": func() -> void: toggle_fullscreen()},
		{"label": "Back to main menu", "call": func() -> void: _back_to_main_menu()},
		{"label": "Quit to desktop", "call": func() -> void: get_tree().quit()}
	]
	for index in range(actions.size()):
		var button := Button.new()
		button.position = Vector2(70, 134 + index * 54)
		button.size = Vector2(280, 42)
		button.text = str(actions[index].label)
		button.pressed.connect(actions[index].call)
		pause_panel.add_child(button)


func _build_logistics_panel(layer: CanvasLayer) -> void:
	logistics_panel = ColorRect.new()
	logistics_panel.position = Vector2(180, 105)
	logistics_panel.size = Vector2(920, 500)
	logistics_panel.color = Color("#d8bd83")
	logistics_panel.visible = false
	layer.add_child(logistics_panel)
	var title := Label.new()
	title.position = Vector2(30, 20)
	title.text = "SETTLEMENT LOGISTICS"
	title.add_theme_font_size_override("font_size", 28)
	logistics_panel.add_child(title)
	logistics_list = ItemList.new()
	logistics_list.position = Vector2(30, 72)
	logistics_list.size = Vector2(510, 350)
	logistics_list.item_selected.connect(_select_route)
	logistics_panel.add_child(logistics_list)
	logistics_detail = Label.new()
	logistics_detail.position = Vector2(570, 78)
	logistics_detail.size = Vector2(320, 270)
	logistics_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	logistics_detail.add_theme_color_override("font_color", Color("#30241d"))
	logistics_panel.add_child(logistics_detail)
	var pause_route := Button.new()
	pause_route.position = Vector2(570, 360)
	pause_route.size = Vector2(145, 42)
	pause_route.text = "Pause / resume"
	pause_route.pressed.connect(_toggle_selected_route)
	logistics_panel.add_child(pause_route)
	var remove_route := Button.new()
	remove_route.position = Vector2(735, 360)
	remove_route.size = Vector2(145, 42)
	remove_route.text = "Delete route"
	remove_route.pressed.connect(_delete_selected_route)
	logistics_panel.add_child(remove_route)
	var hint := Label.new()
	hint.position = Vector2(30, 442)
	hint.text = "G / Esc: close    Routes wait safely when a source is empty or a destination is full."
	hint.add_theme_color_override("font_color", Color("#6b3e20"))
	logistics_panel.add_child(hint)


func set_logistics_open(value: bool) -> void:
	logistics_open = value
	if logistics_panel != null: logistics_panel.visible = value
	if player != null:
		player.movement_enabled = not value
		player.velocity = Vector2.ZERO
	if value: _refresh_logistics_panel()


func _refresh_logistics_panel() -> void:
	if logistics_list == null: return
	logistics_list.clear()
	for route: Variant in logistics_routes:
		var worker: Variant = villagers.get(route.villager_id)
		var item: Variant = item_registry.get_item(route.item_id)
		var state_text: String = "paused" if not route.enabled else (worker.status_text() if worker != null else "worker missing")
		logistics_list.add_item("%s  ·  %s  ·  %s" % [worker.villager_name if worker != null else "Unassigned", item.label if item != null else route.item_id, state_text])
	if logistics_routes.is_empty():
		logistics_detail.text = "No routes yet.\n\nSelect a villager, choose Assign transport, then click a source and a destination."
		return
	selected_route_index = clampi(selected_route_index, 0, logistics_routes.size() - 1)
	logistics_list.select(selected_route_index)
	_select_route(selected_route_index)


func _select_route(index: int) -> void:
	if index < 0 or index >= logistics_routes.size(): return
	selected_route_index = index
	var route: Variant = logistics_routes[index]
	var source: Variant = placed_targets.get(route.source_id)
	var destination: Variant = placed_targets.get(route.destination_id)
	var worker: Variant = villagers.get(route.villager_id)
	logistics_detail.text = "%s\n\n%s  →  %s\nResource: %s\nTrips completed: %d\n\nStatus: %s" % [worker.villager_name if worker != null else "Missing worker", source.item_label if source != null else "Missing source", destination.item_label if destination != null else "Missing destination", item_registry.get_item(route.item_id).label, route.trips_completed, "Paused" if not route.enabled else (worker.status_text() if worker != null else "Blocked")]


func _toggle_selected_route() -> void:
	if selected_route_index < 0 or selected_route_index >= logistics_routes.size(): return
	logistics_routes[selected_route_index].enabled = not logistics_routes[selected_route_index].enabled
	_refresh_logistics_panel()
	queue_redraw()


func _delete_selected_route() -> void:
	if selected_route_index < 0 or selected_route_index >= logistics_routes.size(): return
	var route: Variant = logistics_routes[selected_route_index]
	if villagers.has(route.villager_id): villagers[route.villager_id].clear_task()
	logistics_routes.remove_at(selected_route_index)
	selected_route_index = maxi(0, selected_route_index - 1)
	_refresh_logistics_panel()
	queue_redraw()


func set_pause_open(value: bool) -> void:
	pause_open = value
	if pause_panel != null: pause_panel.visible = value
	if player != null:
		player.movement_enabled = not value
		player.velocity = Vector2.ZERO


func _save_from_menu() -> void:
	var result: Error = physical_save.save_to_path(self, _manual_save_path())
	interaction_label.text = "Game saved" if result == OK else "Save failed"
	set_pause_open(false)


func _load_from_menu(path: String) -> void:
	if not FileAccess.file_exists(path):
		interaction_label.text = "No saved game found"
		set_pause_open(false)
		return
	PhysicalSaveCodecType.pending_reload = true
	PhysicalSaveCodecType.pending_reload_path = path
	get_tree().reload_current_scene()


func _back_to_main_menu() -> void:
	set_pause_open(false)
	set_scenario_select_open(true)


func _manual_save_path() -> String:
	return "user://%s_save.json" % scenario.save_key


func _autosave_path() -> String:
	return "user://%s_autosave.json" % scenario.save_key


func _build_scenario_panel(layer: CanvasLayer) -> void:
	scenario_panel = ColorRect.new()
	scenario_panel.position = Vector2(250, 82)
	scenario_panel.size = Vector2(780, 570)
	scenario_panel.color = Color(0.05, 0.06, 0.08, 0.97)
	scenario_panel.visible = false
	layer.add_child(scenario_panel)
	var title := Label.new()
	title.position = Vector2(44, 36)
	title.size = Vector2(612, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "WHERE DO YOU WANT TO GO TODAY?"
	title.add_theme_font_size_override("font_size", 28)
	scenario_panel.add_child(title)
	var intro := Label.new()
	intro.position = Vector2(70, 92)
	intro.size = Vector2(560, 70)
	intro.text = "One traveller. Four eras. Build a society whose resources, professions, dangers and survival rules belong to its time."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", Color("#fff3d2"))
	scenario_panel.add_child(intro)
	var destinations: Array[Dictionary] = [
		{"label":"1  PREHISTORY\nMaster fire, tools and the hunt", "path":"res://scenarios/physical/prehistory.json", "save":"user://prehistory_save.json"},
		{"label":"2  ANCIENT EGYPT\nFound a settlement on the Nile", "path":"res://scenarios/physical/ancient_egypt.json", "save":"user://ancient_egypt_save.json"},
		{"label":"3  MEDIEVAL\nGrow a village of skilled trades", "path":"res://scenarios/physical/medieval.json", "save":"user://medieval_save.json"},
		{"label":"4  MARS COLONY\nSurvive the first sols", "path":"res://scenarios/physical/mars_colony.json", "save":"user://mars_colony_save.json"}
	]
	for index in range(destinations.size()):
		var row: Dictionary = destinations[index]
		var column := index % 2
		var line := index / 2
		var destination := Button.new()
		destination.position = Vector2(42 + column * 364, 170 + line * 142)
		destination.size = Vector2(332, 76)
		destination.text = str(row.label)
		destination.pressed.connect(func() -> void: select_scenario(str(row.path)))
		scenario_panel.add_child(destination)
		var resume := Button.new()
		resume.position = Vector2(92 + column * 364, 252 + line * 142)
		resume.size = Vector2(232, 34)
		resume.text = "Continue this timeline"
		resume.disabled = not FileAccess.file_exists(str(row.save))
		resume.pressed.connect(func() -> void: continue_scenario(str(row.path), str(row.save)))
		scenario_panel.add_child(resume)
	var shortcut := Label.new()
	shortcut.position = Vector2(80, 510)
	shortcut.size = Vector2(620, 28)
	shortcut.text = "Keyboard: 1 Prehistory  ·  2 Egypt  ·  3 Medieval  ·  4 Mars"
	shortcut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shortcut.add_theme_color_override("font_color", Color("#f0cc72"))
	scenario_panel.add_child(shortcut)


func _build_machine_panel(layer: CanvasLayer) -> void:
	machine_panel = ColorRect.new()
	machine_panel.position = Vector2(835, 120)
	machine_panel.size = Vector2(420, 560)
	machine_panel.color = Color("#d8bd83")
	machine_panel.visible = false
	layer.add_child(machine_panel)
	machine_title_label = Label.new()
	machine_title_label.position = Vector2(26, 22)
	machine_title_label.text = "MACHINE"
	machine_title_label.add_theme_font_size_override("font_size", 25)
	machine_title_label.add_theme_color_override("font_color", Color("#3b281b"))
	machine_panel.add_child(machine_title_label)
	machine_status_label = Label.new()
	machine_status_label.position = Vector2(28, 72)
	machine_status_label.size = Vector2(248, 390)
	machine_status_label.add_theme_font_size_override("font_size", 18)
	machine_status_label.add_theme_color_override("font_color", Color("#3b281b"))
	machine_panel.add_child(machine_status_label)
	machine_worker_icon = TextureRect.new()
	machine_worker_icon.position = Vector2(292, 72)
	machine_worker_icon.size = Vector2(80, 100)
	machine_worker_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	machine_worker_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	machine_worker_icon.visible = false
	machine_panel.add_child(machine_worker_icon)
	machine_remove_worker_button = Button.new()
	machine_remove_worker_button.position = Vector2(278, 180)
	machine_remove_worker_button.size = Vector2(112, 42)
	machine_remove_worker_button.text = "Remove"
	machine_remove_worker_button.pressed.connect(_remove_machine_worker)
	machine_remove_worker_button.visible = false
	machine_panel.add_child(machine_remove_worker_button)
	var controls := Label.new()
	controls.position = Vector2(28, 504)
	controls.size = Vector2(364, 40)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.text = "Space: add compatible selected item, otherwise collect    Esc: close"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("#6b3e20"))
	machine_panel.add_child(controls)


func _build_villager_panel(layer: CanvasLayer) -> void:
	villager_panel = ColorRect.new()
	villager_panel.position = Vector2(835, 55)
	villager_panel.size = Vector2(420, 610)
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
	villager_name_edit.size = Vector2(376, 38)
	villager_name_edit.placeholder_text = "Name"
	villager_name_edit.text_submitted.connect(_rename_selected_villager)
	villager_name_edit.focus_exited.connect(_commit_villager_name)
	villager_panel.add_child(villager_name_edit)
	villager_appearance_option = OptionButton.new()
	villager_appearance_option.position = Vector2(22, 106)
	villager_appearance_option.size = Vector2(376, 36)
	var appearance_names: Array[String] = ["Woman · Nile blue", "Man · Nile blue", "Woman · Desert ochre", "Man · Desert ochre", "Woman · Reed green", "Man · Reed green"]
	if not scenario.character_sheet_paths.is_empty():
		appearance_names = ["Man · Azure", "Woman · Azure", "Man · Ochre", "Woman · Ochre", "Man · Green", "Woman · Green"]
	for option_name: String in appearance_names:
		villager_appearance_option.add_item(option_name)
	villager_appearance_option.item_selected.connect(_change_selected_villager_appearance)
	villager_panel.add_child(villager_appearance_option)
	villager_priority_option = OptionButton.new()
	villager_priority_option.position = Vector2(22, 148)
	villager_priority_option.size = Vector2(376, 36)
	for option_name: String in ["Relaxed priority", "Normal priority", "Urgent priority"]:
		villager_priority_option.add_item(option_name)
	villager_priority_option.item_selected.connect(_change_selected_villager_priority)
	villager_panel.add_child(villager_priority_option)
	villager_status_label = Label.new()
	villager_status_label.position = Vector2(22, 194)
	villager_status_label.size = Vector2(376, 126)
	villager_status_label.add_theme_font_size_override("font_size", 16)
	villager_status_label.add_theme_color_override("font_color", Color("#3b281b"))
	villager_panel.add_child(villager_status_label)
	villager_resource_option = OptionButton.new()
	villager_resource_option.position = Vector2(22, 326)
	villager_resource_option.size = Vector2(376, 36)
	villager_resource_option.visible = false
	villager_panel.add_child(villager_resource_option)
	var assign := Button.new()
	assign.position = Vector2(22, 374)
	assign.size = Vector2(376, 42)
	assign.text = "Assign transport"
	assign.pressed.connect(begin_villager_transport_order)
	villager_panel.add_child(assign)
	var work := Button.new()
	work.position = Vector2(22, 424)
	work.size = Vector2(376, 42)
	work.text = "Assign work"
	work.pressed.connect(begin_villager_work_order)
	villager_panel.add_child(work)
	var stop := Button.new()
	stop.position = Vector2(22, 474)
	stop.size = Vector2(376, 42)
	stop.text = "Stop task"
	stop.pressed.connect(stop_selected_villager_task)
	villager_panel.add_child(stop)
	villager_order_feedback = Label.new()
	villager_order_feedback.position = Vector2(22, 530)
	villager_order_feedback.size = Vector2(376, 62)
	villager_order_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	villager_order_feedback.add_theme_color_override("font_color", Color("#6b3e20"))
	villager_panel.add_child(villager_order_feedback)


func _build_building_details_panel(layer: CanvasLayer) -> void:
	building_details_panel = ColorRect.new()
	building_details_panel.position = Vector2(835, 120)
	building_details_panel.size = Vector2(420, 480)
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
	building_details_body.size = Vector2(372, 330)
	building_details_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_details_body.add_theme_font_size_override("font_size", 17)
	building_details_body.add_theme_color_override("font_color", Color("#3b281b"))
	building_details_panel.add_child(building_details_body)
	building_details_controls = Label.new()
	building_details_controls.position = Vector2(24, 438)
	building_details_controls.text = "Esc: close"
	building_details_controls.add_theme_color_override("font_color", Color("#6b3e20"))
	building_details_panel.add_child(building_details_controls)
	construction_delivery_popup = ColorRect.new()
	construction_delivery_popup.position = Vector2(18, 248)
	construction_delivery_popup.size = Vector2(384, 174)
	construction_delivery_popup.color = Color("#f1dda9")
	construction_delivery_popup.visible = false
	building_details_panel.add_child(construction_delivery_popup)
	construction_delivery_label = Label.new()
	construction_delivery_label.position = Vector2(18, 12)
	construction_delivery_label.size = Vector2(348, 150)
	construction_delivery_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	construction_delivery_label.add_theme_font_size_override("font_size", 16)
	construction_delivery_label.add_theme_color_override("font_color", Color("#3b281b"))
	construction_delivery_popup.add_child(construction_delivery_label)
	for index in range(4):
		var icon := _make_item_icon(Vector2(20, 48 + index * 27), Vector2(22, 22))
		construction_delivery_popup.add_child(icon)
		construction_delivery_icons.append(icon)


func _hide_subject_panels() -> void:
	if villagers.has(selected_villager_id):
		villagers[selected_villager_id].selected = false
		villagers[selected_villager_id].queue_redraw()
	selected_villager_id = ""
	villager_order_mode = ""
	pending_order_source_id = ""
	building_details_open = false
	building_details_id = ""
	storage_open = false
	active_storage_id = ""
	machine_open = false
	active_machine_id = ""
	if villager_panel != null: villager_panel.visible = false
	if building_details_panel != null: building_details_panel.visible = false
	if storage_panel != null: storage_panel.visible = false
	if machine_panel != null: machine_panel.visible = false
	if construction_delivery_popup != null: construction_delivery_popup.visible = false


func open_building_details(instance_id: String) -> bool:
	if not placed_targets.has(instance_id): return false
	_hide_subject_panels()
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


func building_details_context_action() -> void:
	var site: Variant = construction_by_entity_id.get(building_details_id)
	if site == null or site.complete:
		var placed: Variant = world_grid.entities_by_id.get(building_details_id)
		if placed != null and placed.definition_id == "CHICKEN_COOP":
			_raise_chicken(building_details_id)
			_update_building_details()
			return
		close_building_details()
		return
	if construction_delivery_popup.visible:
		for row: Dictionary in _construction_deliverable(site):
			var accepted: int = site.deliver(str(row.item), int(row.amount))
			if accepted > 0: inventory.remove(str(row.item), accepted)
		_update_inventory_hud()
	elif site.materials_complete():
		active_player_build_id = building_details_id
	else:
		deliver_selected_to_construction(building_details_id)
	_update_building_details()


func _construction_deliverable(site: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id: String in site.requirements:
		var amount := mini(inventory.count(item_id), site.receivable(item_id))
		if amount > 0: result.append({"item": item_id, "amount": amount})
	return result


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
		var deliverable := _construction_deliverable(site)
		construction_delivery_popup.visible = not deliverable.is_empty()
		if not deliverable.is_empty():
			var delivery_rows: Array[String] = []
			for index in range(deliverable.size()):
				var row: Dictionary = deliverable[index]
				delivery_rows.append("      %s  x%d" % [item_registry.get_item(str(row.item)).label, int(row.amount)])
				if index < construction_delivery_icons.size():
					construction_delivery_icons[index].texture = ItemIconAtlasType.icon(str(row.item))
					construction_delivery_icons[index].visible = true
			for index in range(deliverable.size(), construction_delivery_icons.size()): construction_delivery_icons[index].visible = false
			construction_delivery_label.text = "DELIVER MATERIALS\n\n%s\n\nSPACE  Deliver all available" % "\n".join(delivery_rows)
		building_details_controls.text = "Space: %s    Esc: close" % ("deliver shown materials" if not deliverable.is_empty() else ("start building" if site.materials_complete() else "select a required material"))
		return
	construction_delivery_popup.visible = false
	building_details_controls.text = "Space / Esc: close"
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
	if placed.definition_id == "CHICKEN_COOP":
		var chicken_count := _dependent_count(building_details_id, "chicken")
		building_details_body.text = "CHICKEN COOP\n\nChickens: %d / 3\n\nAssign an animal keeper. Feed each chicken Grain and Water. Adults lay eggs every 35 seconds; collect them with Space.\n\nNew chicken cost: Grain x5" % chicken_count
		building_details_controls.text = "Space: raise chicken (Grain x5)    Esc: close" if chicken_count < 3 else "Coop full    Esc: close"
		return
	if definition.population_capacity > 0:
		var resident_rows: Array[String] = []
		for villager: Variant in villagers.values():
			if villager.home_id == building_details_id:
				resident_rows.append("• %s — %s | Hunger %d%% | Energy %d%%" % [villager.villager_name, villager.status_text(), roundi(villager.hunger), roundi(villager.energy)])
		building_details_body.text = "HOME\n\nBeds: %d / %d occupied\n\nResidents\n%s\n\nHealth: good" % [resident_rows.size(), definition.population_capacity, "\n".join(resident_rows) if not resident_rows.is_empty() else "None"]
		return
	building_details_body.text = "Status: complete\n\nHealth: good\n\nNo active production."


func select_villager(villager_id: String) -> bool:
	if not villagers.has(villager_id): return false
	_hide_subject_panels()
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
	if villager_appearance_option != null and villager_appearance_option.selected != villager.appearance_id:
		villager_appearance_option.select(villager.appearance_id)
	if villager_priority_option != null and villager_priority_option.selected != villager.work_priority:
		villager_priority_option.select(villager.work_priority)
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
	var skill_seconds := float(villager.experience.get(villager.profession, 0.0))
	var level := 1 + floori(skill_seconds / 120.0)
	villager_status_label.text = "Home: %s\nStatus: %s\nRole: %s · level %d\nHunger %d%%  Energy %d%%\nTask: %s\nCarrying: %s" % [villager.home_id, villager.status_text(), villager.profession.capitalize(), level, roundi(villager.hunger), roundi(villager.energy), task_text, "nothing" if villager.carrying_amount == 0 else "%s x%d" % [villager.carrying_item, villager.carrying_amount]]


func _change_selected_villager_appearance(index: int) -> void:
	if not villagers.has(selected_villager_id): return
	var villager: Variant = villagers[selected_villager_id]
	villager.appearance_id = posmod(index, 6)
	villager.color_tint = _villager_appearance_tint(villager.appearance_id)
	villager.queue_redraw()


func _change_selected_villager_priority(index: int) -> void:
	if not villagers.has(selected_villager_id): return
	villagers[selected_villager_id].work_priority = clampi(index, 0, 2)
	_update_villager_panel()


func _villager_appearance_tint(appearance: int) -> Color:
	match floori(posmod(appearance, 6) / 2.0):
		1: return Color("#f3d2a2")
		2: return Color("#cce0b2")
	return Color.WHITE


func begin_villager_transport_order() -> void:
	if not villagers.has(selected_villager_id): return
	villager_order_mode = "source"
	pending_order_source_id = ""
	villager_resource_option.clear()
	villager_resource_option.visible = false
	villager_order_feedback.text = "Click water, a completed crate, or a machine as SOURCE."


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
		if endpoint == null and villager_order_mode == "source":
			var water_cell := _water_cell_at_world(world_position)
			if water_cell != Vector2i(-1, -1): endpoint = _ensure_water_route_target(water_cell)
		if endpoint == null:
			villager_order_feedback.text = "Select water, a completed crate, or a machine."
			return true
		return _handle_order_endpoint(endpoint.stable_id)
	var clicked_object: Variant = _any_placed_target_at(world_position)
	if clicked_object != null:
		return true
	var nearest: Variant = null
	var distance := 28.0
	for villager: Variant in villagers.values():
		var candidate: float = villager.global_position.distance_to(world_position)
		if candidate < distance: nearest = villager; distance = candidate
	if nearest != null:
		return true
	if villagers.has(selected_villager_id):
		var villager: Variant = villagers[selected_villager_id]
		if Input.is_key_pressed(KEY_SHIFT):
			villager.enqueue_move(world_position)
			villager_order_feedback.text = "Waypoint queued (%d)." % villager.queued_task_count()
		else:
			villager.assign_move(world_position)
			villager_order_feedback.text = "Moving to selected point. Shift-click queues waypoints."
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
			var work_definition: Variant = definition_for_instance(target.stable_id)
			if target.target_kind != "construction" and target.target_kind != "machine" and (work_definition == null or work_definition.workers_required <= 0): continue
		elif villager_order_mode == "source":
			if target.target_kind != "storage" and target.target_kind != "machine" and target.target_kind != "water": continue
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
		if _is_water_source_id(instance_id):
			villager_resource_option.add_item(item_registry.get_item("water").label)
			villager_resource_option.set_item_metadata(0, "water")
		elif machines_by_entity_id.has(instance_id):
			for output_id: String in machines_by_entity_id[instance_id].recipe_outputs:
				villager_resource_option.add_item(item_registry.get_item(output_id).label)
				villager_resource_option.set_item_metadata(villager_resource_option.item_count - 1, output_id)
		elif storage_by_entity_id.has(instance_id):
			var added: Dictionary = {}
			for slot: Dictionary in storage_by_entity_id[instance_id].slots:
				if slot.is_empty() or added.has(slot.item_id): continue
				var definition: Variant = item_registry.get_item(str(slot.item_id))
				if definition == null or not definition.placeable_entity_id.is_empty(): continue
				villager_resource_option.add_item(definition.label)
				villager_resource_option.set_item_metadata(villager_resource_option.item_count - 1, str(slot.item_id))
				added[slot.item_id] = true
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
	var source_id := pending_order_source_id
	var created := create_logistics_route(source_id, instance_id, selected_villager_id, item_id)
	if not created:
		villager_order_feedback.text = "That transport order already exists or is no longer valid."
		return true
	villager_order_mode = ""
	pending_order_source_id = ""
	villager_resource_option.visible = false
	var source_inventory: Variant = _route_source_inventory(source_id)
	var currently_available: bool = _is_water_source_id(source_id) or (source_inventory != null and source_inventory.count(item_id) > 0)
	villager_order_feedback.text = "Transport order assigned." if currently_available else "Transport assigned; waiting for source output."
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
	PhysicalScenarioType.requested_autostart = true
	get_tree().reload_current_scene()


func continue_scenario(path: String, save_path: String) -> void:
	PhysicalSaveCodecType.pending_reload = true
	PhysicalSaveCodecType.pending_reload_path = save_path
	if path != scenario_path: PhysicalScenarioType.requested_path = path
	PhysicalScenarioType.requested_autostart = true
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
	crafting_recipe_scroll = ScrollContainer.new()
	crafting_recipe_scroll.position = Vector2(22, 74)
	crafting_recipe_scroll.size = Vector2(320, 304)
	crafting_recipe_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	crafting_recipe_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	crafting_panel.add_child(crafting_recipe_scroll)
	var recipe_list := VBoxContainer.new()
	recipe_list.custom_minimum_size = Vector2(296, maxi(304, recipe_registry.recipe_order.size() * 43 - 5))
	recipe_list.add_theme_constant_override("separation", 5)
	crafting_recipe_scroll.add_child(recipe_list)
	for index in range(recipe_registry.recipe_order.size()):
		var recipe: Variant = recipe_registry.get_recipe(recipe_registry.recipe_order[index])
		var button := Button.new()
		button.custom_minimum_size = Vector2(292, 38)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%d.  %s" % [index + 1, recipe.label]
		if not recipe.outputs.is_empty(): button.icon = ItemIconAtlasType.icon(str(recipe.outputs.keys()[0]))
		button.add_theme_constant_override("icon_max_width", 30)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_recipe_button_pressed.bind(index))
		button.mouse_entered.connect(_on_recipe_button_hovered.bind(index))
		recipe_list.add_child(button)
		crafting_recipe_buttons.append(button)
	crafting_list_label.visible = false
	crafting_detail_label = RichTextLabel.new()
	crafting_detail_label.position = Vector2(375, 78)
	crafting_detail_label.size = Vector2(295, 300)
	crafting_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crafting_detail_label.bbcode_enabled = true
	crafting_detail_label.scroll_active = false
	crafting_detail_label.add_theme_font_size_override("normal_font_size", 17)
	crafting_detail_label.add_theme_color_override("default_color", Color("#3b281b"))
	crafting_panel.add_child(crafting_detail_label)
	for index in range(8):
		var resource_icon := _make_item_icon(Vector2(345, 142 + index * 25), Vector2(23, 23))
		crafting_panel.add_child(resource_icon)
		crafting_resource_icons.append(resource_icon)
	var controls := Label.new()
	controls.position = Vector2(24, 405)
	controls.text = "SPACE to craft"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("#3b281b"))
	crafting_panel.add_child(controls)
	_update_crafting_ui()


func _build_storage_panel(layer: CanvasLayer) -> void:
	storage_panel = ColorRect.new()
	storage_panel.position = Vector2(835, 120)
	storage_panel.size = Vector2(420, 480)
	storage_panel.color = Color("#d8bd83")
	storage_panel.visible = false
	layer.add_child(storage_panel)
	var title := Label.new()
	title.position = Vector2(24, 18)
	title.text = "STORAGE CRATE"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#3b281b"))
	storage_panel.add_child(title)
	storage_player_label = Label.new()
	storage_player_label.position = Vector2(18, 58)
	storage_player_label.size = Vector2(188, 26)
	storage_player_label.add_theme_font_size_override("font_size", 15)
	storage_player_label.add_theme_color_override("font_color", Color("#3b281b"))
	storage_panel.add_child(storage_player_label)
	for index in range(inventory.slot_count):
		var row := ColorRect.new()
		row.position = Vector2(18, 86 + index * 23)
		row.size = Vector2(188, 21)
		storage_panel.add_child(row)
		storage_player_rows.append(row)
		var player_icon := _make_item_icon(Vector2(22, 87 + index * 23), Vector2(19, 19))
		storage_panel.add_child(player_icon)
		storage_player_icons.append(player_icon)
		var slot_label := Label.new()
		slot_label.position = Vector2(45, 86 + index * 23)
		slot_label.size = Vector2(157, 21)
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 12)
		storage_panel.add_child(slot_label)
		storage_player_slot_labels.append(slot_label)
	storage_contents_label = Label.new()
	storage_contents_label.position = Vector2(214, 58)
	storage_contents_label.size = Vector2(188, 26)
	storage_contents_label.add_theme_font_size_override("font_size", 15)
	storage_contents_label.add_theme_color_override("font_color", Color("#3b281b"))
	storage_panel.add_child(storage_contents_label)
	for index in range(12):
		var row := ColorRect.new()
		row.position = Vector2(214, 86 + index * 23)
		row.size = Vector2(188, 21)
		storage_panel.add_child(row)
		storage_crate_rows.append(row)
		var crate_icon := _make_item_icon(Vector2(218, 87 + index * 23), Vector2(19, 19))
		storage_panel.add_child(crate_icon)
		storage_crate_icons.append(crate_icon)
		var slot_label := Label.new()
		slot_label.position = Vector2(241, 86 + index * 23)
		slot_label.size = Vector2(157, 21)
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 12)
		storage_panel.add_child(slot_label)
		storage_crate_slot_labels.append(slot_label)
	storage_feedback_label = Label.new()
	storage_feedback_label.position = Vector2(24, 370)
	storage_feedback_label.size = Vector2(372, 36)
	storage_feedback_label.add_theme_font_size_override("font_size", 16)
	storage_feedback_label.add_theme_color_override("font_color", Color("#6b3e20"))
	storage_panel.add_child(storage_feedback_label)
	var controls := Label.new()
	controls.position = Vector2(24, 420)
	controls.size = Vector2(372, 48)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.text = "Left/Right: choose inventory    Up/Down: choose item    Space: move stack    Esc: close"
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color("#3b281b"))
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
	if definition.entity_id == "TREE_CROP":
		_spawn_crop(instance_id, placement_cursor, 0, false)
		cancel_placement()
		_update_inventory_hud()
		interaction_label.text = "Planted Tree seed"
		queue_redraw()
		return true
	_add_placed_collision(instance_id, result.cells)
	if not definition.construction_cost.is_empty() or definition.construction_work_seconds > 0.0:
		construction_by_entity_id[instance_id] = ConstructionSiteType.new(
			instance_id,
			definition.construction_cost,
			definition.construction_work_seconds
		)
	_add_placed_target(instance_id, definition, placement_cursor, placement_rotation)
	if not construction_by_entity_id.has(instance_id):
		_add_structure_visual(instance_id, definition.entity_id, result.cells)
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


func _add_structure_visual(instance_id: String, definition_id: String, cells: Array[Vector2i]) -> void:
	if structure_visuals.has(instance_id) or cells.is_empty(): return
	var visual := StructureVisualType.new()
	var definition: Variant = placement_registry.get_entity(definition_id)
	visual.configure(definition_id, cells, definition.visual if definition != null else {})
	add_child(visual)
	structure_visuals[instance_id] = visual


func _water_cell_at_world(world_position: Vector2) -> Vector2i:
	var direct := Vector2i(floori(world_position.x / CELL_SIZE), floori(world_position.y / CELL_SIZE))
	if water_cells.has(direct): return direct
	var nearest := Vector2i(-1, -1)
	var nearest_distance := CELL_SIZE * 0.75
	for y in range(direct.y - 1, direct.y + 2):
		for x in range(direct.x - 1, direct.x + 2):
			var candidate := Vector2i(x, y)
			if not water_cells.has(candidate): continue
			var distance := world_position.distance_to(Vector2(candidate * CELL_SIZE) + Vector2.ONE * 16.0)
			if distance < nearest_distance: nearest = candidate; nearest_distance = distance
	return nearest


func _ensure_water_route_target(cell: Vector2i) -> Variant:
	var instance_id := "water-%d-%d" % [cell.x, cell.y]
	if placed_targets.has(instance_id): return placed_targets[instance_id]
	var position := Vector2(cell * CELL_SIZE) + Vector2.ONE * 16.0
	var target := PlacedTargetType.new()
	target.configure(instance_id, "Water source", position, position, "water", [position])
	target.visible = false
	add_child(target)
	placed_targets[instance_id] = target
	return target


func _is_water_source_id(instance_id: String) -> bool:
	return instance_id.begins_with("water-")


func restore_water_route_target(instance_id: String) -> bool:
	if not _is_water_source_id(instance_id): return false
	var parts := instance_id.split("-")
	if parts.size() != 3: return false
	var cell := Vector2i(int(parts[1]), int(parts[2]))
	if not water_cells.has(cell): return false
	_ensure_water_route_target(cell)
	return true


func select_recipe(direction: int) -> void:
	selected_recipe_index = posmod(selected_recipe_index + direction, recipe_registry.recipe_order.size())
	_update_crafting_ui()
	_scroll_selected_recipe_into_view()


func _scroll_selected_recipe_into_view() -> void:
	if crafting_recipe_scroll == null or selected_recipe_index < 0 or selected_recipe_index >= crafting_recipe_buttons.size(): return
	crafting_recipe_scroll.ensure_control_visible(crafting_recipe_buttons[selected_recipe_index])


func _on_recipe_button_pressed(index: int) -> void:
	selected_recipe_index = index
	_scroll_selected_recipe_into_view()
	craft_selected_recipe()


func _on_recipe_button_hovered(index: int) -> void:
	selected_recipe_index = index
	_update_crafting_ui()


func craft_selected_recipe() -> bool:
	var recipe_id: String = recipe_registry.recipe_order[selected_recipe_index]
	var recipe: Variant = recipe_registry.get_recipe(recipe_id)
	if not campaign.is_unlocked(recipe.unlock_after):
		_update_crafting_ui("Locked — advance the current campaign chapter first.")
		return false
	var result: Dictionary = crafting.craft(inventory, recipe_id)
	if result.valid:
		_play_feedback(CRAFT_SOUND)
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
		var button := crafting_recipe_buttons[index]
		var recipe: Variant = recipe_registry.get_recipe(recipe_registry.recipe_order[index])
		var unlocked: bool = campaign.is_unlocked(recipe.unlock_after)
		var available: bool = unlocked and crafting.query(inventory, recipe.recipe_id).valid
		var text_color := Color("#fffaf0") if available else (Color("#777777") if unlocked else Color("#665e58"))
		button.text = "%s%d.  %s" % ["▶ " if index == selected_recipe_index else "   ", index + 1, recipe.label]
		button.modulate = Color.WHITE
		button.add_theme_color_override("font_color", text_color)
		button.add_theme_color_override("font_hover_color", text_color)
		button.add_theme_color_override("font_pressed_color", text_color)
		button.add_theme_color_override("font_focus_color", text_color)
	var selected: Variant = recipe_registry.get_recipe(recipe_registry.recipe_order[selected_recipe_index])
	var selected_unlocked: bool = campaign.is_unlocked(selected.unlock_after)
	var ingredients: Array[String] = []
	var icon_index := 0
	for icon: TextureRect in crafting_resource_icons: icon.visible = false
	for item_id: String in selected.inputs:
		var definition: Variant = item_registry.get_item(item_id)
		var owned: int = inventory.count(item_id)
		var required: int = int(selected.inputs[item_id])
		var ingredient_color := "#fffaf0" if owned >= required else "#d83232"
		ingredients.append("[color=%s]%s: %d / %d[/color]" % [ingredient_color, definition.label, owned, required])
		if icon_index < crafting_resource_icons.size():
			crafting_resource_icons[icon_index].position.y = 139 + icon_index * 22
			crafting_resource_icons[icon_index].texture = ItemIconAtlasType.icon(item_id)
			crafting_resource_icons[icon_index].modulate = Color("#fffaf0") if owned >= required else Color("#d83232")
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
	var status := ("Ready to craft" if query.valid else _crafting_failure_text(query)) if selected_unlocked else "LOCKED — complete an earlier campaign chapter"
	if not feedback.is_empty():
		status = feedback
	crafting_detail_label.text = "[color=#3b281b]%s\n\nNeeds:\n[/color]%s[color=#3b281b]\n\nProduces:\n%s\n\n%s[/color]" % [selected.label, "\n".join(ingredients), "\n".join(outputs), status]


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
	for source: Variant in resource_sources:
		if is_instance_valid(source): active.append(source)
	for crop: Variant in crops:
		if is_instance_valid(crop): active.append(crop)
	_update_water_interaction_target()
	if water_interaction_target != null and water_interaction_target.visible: active.append(water_interaction_target)
	for target: Variant in placed_targets.values():
		if is_instance_valid(target):
			active.append(target)
	for villager: Variant in villagers.values():
		if is_instance_valid(villager): active.append(villager)
	for dependent: Variant in dependents.values():
		if is_instance_valid(dependent): active.append(dependent)
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
		elif interaction_target.target_kind == "resource_source":
			interaction_label.text = "%s source %d/%d | Space to gather" % [interaction_target.item_label, interaction_target.current_amount, interaction_target.max_amount]
		elif interaction_target.target_kind == "water":
			interaction_label.text = "Water | Space to gather"
		elif interaction_target.target_kind == "crop":
			interaction_label.text = _crop_prompt(interaction_target)
		elif interaction_target.target_kind == "construction":
			interaction_label.text = _construction_prompt(interaction_target.stable_id)
		elif interaction_target.target_kind == "machine":
			interaction_label.text = _machine_prompt(interaction_target.stable_id)
		elif interaction_target.target_kind == "villager":
			interaction_label.text = "%s | Space to open" % interaction_target.villager_name
		elif interaction_target.target_kind == "dependent":
			interaction_label.text = "%s | Space to interact" % interaction_target.display_name
		else:
			interaction_label.text = "Space to Open %s" % interaction_target.item_label
		if not route_source_id.is_empty() and interaction_target != null:
			interaction_label.text = "ROUTE SOURCE SET | Approach destination and press R | " + interaction_label.text


func _update_water_interaction_target() -> void:
	if water_interaction_target == null: return
	var best_cell := Vector2i(-999, -999)
	var best_distance := INF
	for cell: Vector2i in water_cells:
		var center := Vector2(cell * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5)
		var distance := player.global_position.distance_to(center)
		if distance <= INTERACTION_REACH_PX and distance < best_distance:
			best_cell = cell; best_distance = distance
	water_interaction_target.visible = best_distance < INF
	if water_interaction_target.visible:
		water_interaction_target.global_position = Vector2(best_cell * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5)


func collect_water() -> int:
	var accepted: int = inventory.add("water", 12)
	if accepted > 0:
		campaign.record_pickup("water")
		_update_inventory_hud()
	return accepted


func _crop_prompt(crop: Variant) -> String:
	if crop.stage >= 3: return "Mature tree | Space to harvest"
	if crop.watered: return "%s growing %d%%" % [crop.stage_label(), roundi(crop.progress() * 100.0)]
	return "%s | Select Water and press Space" % crop.stage_label()


func interact_with_crop(crop: Variant) -> bool:
	if crop == null: return false
	if crop.stage >= 3:
		if inventory.capacity_for("wood") < 8 or inventory.capacity_for("tree_seed") < 2:
			interaction_label.text = "Need inventory room for Wood x8 and Tree seed x2"
			return false
		inventory.add("wood", 8); inventory.add("tree_seed", 2)
		world_grid.remove(crop.stable_id)
		crops.erase(crop)
		crop.queue_free()
		interaction_target = null
		_update_inventory_hud(); queue_redraw()
		return true
	if crop.watered:
		interaction_label.text = "This plant is already watered"
		return false
	if inventory.slots[selected_slot].get("item_id", "") != "water":
		interaction_label.text = "Select Water first"
		return false
	inventory.remove("water", 1)
	crop.water()
	_update_inventory_hud()
	return true


func collect_target() -> int:
	_update_interaction_target()
	if interaction_target == null:
		return 0
	if interaction_target.target_kind == "storage":
		open_storage(interaction_target.stable_id)
		return 0
	if interaction_target.target_kind == "water": return collect_water()
	if interaction_target.target_kind == "crop": return 1 if interact_with_crop(interaction_target) else 0
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
	_play_feedback(PICKUP_SOUND)
	campaign.record_pickup(interaction_target.item_id)
	if interaction_target.amount == 0:
		interaction_target.set_targeted(false)
		interaction_target.queue_free()
		interaction_target = null
	_update_inventory_hud()
	queue_redraw()
	return accepted


func collect_resource_source(source: Variant) -> int:
	if source == null: return 0
	var requested: int = source.available_grant()
	if requested <= 0: return 0
	var accepted: int = inventory.add(source.item_id, requested)
	if accepted <= 0: return 0
	source.take(accepted)
	_play_feedback(PICKUP_SOUND)
	campaign.record_pickup(source.item_id)
	_update_inventory_hud()
	if world_overlay != null: world_overlay.queue_redraw()
	return accepted


func feed_settlement() -> int:
	if inventory.slots[selected_slot].is_empty(): return 0
	var slot: Dictionary = inventory.slots[selected_slot]
	if slot.item_id != scenario.food_item_id:
		interaction_label.text = "Select a Food ration to support the settlement"
		return 0
	var amount := int(slot.amount)
	inventory.remove(scenario.food_item_id, amount)
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
		_play_feedback(BUILD_SOUND)
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
			_add_structure_visual(instance_id, definition.entity_id, placed.cells)
			campaign.record_completion(definition.entity_id)
			if definition.population_capacity > 0:
				spawn_villagers_for_home(instance_id, definition.population_capacity)
			for dependent_id: Variant in definition.dependent_spawns:
				spawn_dependent(str(dependent_id), instance_id)
		_refresh_population_capacity()
		interaction_label.text = "%s completed" % (target.item_label if target != null else "Building")
	else:
		interaction_label.text = _construction_prompt(instance_id)
	queue_redraw()
	return applied


func spawn_dependent(species_id: String, home_id: String) -> Variant:
	var definition: Dictionary = {}
	for row: Dictionary in scenario.dependents:
		if str(row.get("id", "")) == species_id: definition = row; break
	if definition.is_empty() or not placed_targets.has(home_id): return null
	var actor: Variant = DependentActorType.new()
	var dependent_id := "dependent-%04d" % next_dependent_id
	actor.configure(dependent_id, definition, home_id, placed_targets[home_id].global_position + Vector2(next_dependent_id % 3 * 12 - 12, 30))
	add_child(actor)
	dependents[dependent_id] = actor
	next_dependent_id += 1
	return actor


func _spawn_wildlife(data: Dictionary) -> Variant:
	var species_id := str(data.get("species", ""))
	var definition: Dictionary = {}
	for row: Dictionary in scenario.dependents:
		if str(row.get("id", "")) == species_id: definition = row; break
	if definition.is_empty(): return null
	var cell: Array = data.get("cell", [10, 10])
	var actor: Variant = DependentActorType.new()
	var dependent_id := str(data.get("id", "wild-%04d" % next_dependent_id))
	actor.configure(dependent_id, definition, "", Vector2(float(cell[0]), float(cell[1])) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5)
	actor.age_seconds = actor.mature_seconds
	add_child(actor)
	dependents[dependent_id] = actor
	next_dependent_id += 1
	return actor


func restore_dependent(data: Dictionary) -> Variant:
	var saved_id := str(data.get("id", ""))
	var actor: Variant = dependents.get(saved_id)
	if actor == null:
		var home_id := str(data.get("home", ""))
		if home_id.is_empty():
			var species_id := str(data.get("species", ""))
			var definition: Dictionary = {}
			for row: Dictionary in scenario.dependents:
				if str(row.get("id", "")) == species_id: definition = row; break
			if not definition.is_empty():
				actor = DependentActorType.new()
				actor.configure(saved_id, definition, "", Vector2.ZERO)
				add_child(actor)
		else:
			actor = spawn_dependent(str(data.get("species", "")), home_id)
	if actor == null: return null
	dependents.erase(actor.stable_id)
	actor.stable_id = str(data.get("id", actor.stable_id))
	var values: Array = data.get("position", [actor.position.x, actor.position.y])
	actor.position = Vector2(float(values[0]), float(values[1]))
	actor.hunger = float(data.get("hunger", 70.0))
	actor.thirst = float(data.get("thirst", 70.0))
	actor.health = float(data.get("health", 100.0))
	actor.age_seconds = float(data.get("age", 0.0))
	actor.product_elapsed = float(data.get("product_elapsed", 0.0))
	actor.stored_product = int(data.get("stored_product", 0))
	dependents[actor.stable_id] = actor
	if actor.stable_id.begins_with("dependent-"): next_dependent_id = maxi(next_dependent_id, int(actor.stable_id.get_slice("-", 1)) + 1)
	return actor


func interact_with_dependent(actor: Variant) -> int:
	if actor == null: return 0
	var selected_item := ""
	if not inventory.slots[selected_slot].is_empty(): selected_item = str(inventory.slots[selected_slot].item_id)
	if actor.wild and not actor.required_tool.is_empty() and selected_item != actor.required_tool:
		actor.harvest_armed = false
		interaction_label.text = "%s requires %s selected" % [actor.display_name, item_registry.get_item(actor.required_tool).label]
		return 0
	var consumed: int = actor.feed(selected_item, inventory.count(selected_item))
	if consumed > 0:
		inventory.remove(selected_item, consumed)
		interaction_label.text = "%s cared for · food %d%% · water %d%%" % [actor.display_name, roundi(actor.hunger), roundi(actor.thirst)]
		_update_inventory_hud()
		return consumed
	if actor.stored_product > 0:
		var accepted: int = inventory.add(actor.product_item, actor.stored_product)
		actor.stored_product -= accepted
		if accepted > 0: campaign.record_pickup(actor.product_item)
		interaction_label.text = "Collected %s x%d" % [item_registry.get_item(actor.product_item).label, accepted]
		_update_inventory_hud()
		return accepted
	if actor.is_mature() and actor.harvest_armed and (actor.wild or actor.required_tool.is_empty() or selected_item == actor.required_tool):
		var produced := 0
		for item_id: String in actor.harvest_outputs:
			var accepted: int = inventory.add(item_id, int(actor.harvest_outputs[item_id]))
			produced += accepted
			if accepted > 0: campaign.record_pickup(item_id)
		actor.set_targeted(false)
		dependents.erase(actor.stable_id)
		actor.queue_free()
		interaction_target = null
		interaction_label.text = "%s · %d items recovered" % ["Hunt complete" if actor.wild else "Animal processed", produced]
		_update_inventory_hud()
		return produced
	if actor.is_mature() and (actor.wild or (not actor.required_tool.is_empty() and selected_item == actor.required_tool)):
		actor.harvest_armed = true
		interaction_label.text = actor.status_text() + (" · Space again to hunt" if actor.wild else " · Space again to process into meat")
		return 0
	interaction_label.text = actor.status_text() + " · select %s or %s to care" % [item_registry.get_item(actor.feed_item).label, item_registry.get_item(actor.drink_item).label]
	return 0


func _dependent_count(home_id: String, species_id: String) -> int:
	var count := 0
	for actor: Variant in dependents.values():
		if actor.home_id == home_id and actor.species_id == species_id: count += 1
	return count


func _raise_chicken(home_id: String) -> bool:
	if _dependent_count(home_id, "chicken") >= 3:
		interaction_label.text = "Chicken coop is full"
		return false
	if inventory.count("grain") < 5:
		interaction_label.text = "Need Grain x5 to raise a chicken"
		return false
	inventory.remove("grain", 5)
	spawn_dependent("chicken", home_id)
	_update_inventory_hud()
	interaction_label.text = "A new young chicken joined the coop"
	return true


func _play_feedback(stream: AudioStream) -> void:
	if feedback_audio == null or DisplayServer.get_name() == "headless": return
	feedback_audio.stream = stream
	feedback_audio.play()


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
		machine.manually_activated = true
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
	var machine_name := _placed_definition_label(instance_id)
	if machine.broken:
		return "%s broken | Space to open" % machine_name
	var output_count := 0
	for item_id: String in machine.recipe_outputs:
		output_count += machine.output_inventory.count(item_id)
	if machine.is_running():
		return "%s working %d%% | Output %d | Space to open" % [machine_name, roundi(machine.progress() * 100.0), output_count]
	return "%s ready | Output %d | Space to open" % [machine_name, output_count]


func _placed_definition_label(instance_id: String) -> String:
	var placed: Variant = world_grid.entities_by_id.get(instance_id)
	if placed == null: return "Machine"
	var definition: Variant = placement_registry.get_entity(placed.definition_id)
	return definition.label if definition != null else "Machine"


func open_machine(instance_id: String) -> bool:
	if not machines_by_entity_id.has(instance_id): return false
	_hide_subject_panels()
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
	machine_title_label.text = _placed_definition_label(active_machine_id).to_upper()
	var input_rows: Array[String] = []
	for item_id: String in machine.recipe_inputs:
		input_rows.append("%s: %d / %d" % [item_registry.get_item(item_id).label, machine.input_inventory.count(item_id), int(machine.recipe_inputs[item_id])])
	var output_rows: Array[String] = []
	for item_id: String in machine.recipe_outputs:
		output_rows.append("%s: %d" % [item_registry.get_item(item_id).label, machine.output_inventory.count(item_id)])
	var state := "BROKEN - needs Wood x2" if machine.broken else ("UNSTAFFED" if not machine.staffed else ("FIRING %d%%" % roundi(machine.progress() * 100.0) if machine.is_running() else "READY / WAITING FOR INPUT"))
	var worker_names: Array[String] = []
	var assigned_worker: Variant = null
	for villager: Variant in villagers.values():
		if not villager.task.is_empty() and str(villager.task.get("type", "")) == "work" and str(villager.task.get("target", "")) == active_machine_id:
			worker_names.append(villager.villager_name)
			if assigned_worker == null: assigned_worker = villager
	machine_status_label.text = "State: %s\nHealth: %d / %d\nWorker: %s\nProgress: %d%%\n\nINPUT\n%s\n\nACCUMULATED OUTPUT\n%s" % [state, machine.durability, machine.max_durability, ", ".join(worker_names) if not worker_names.is_empty() else "none", roundi(machine.progress() * 100.0), "\n".join(input_rows), "\n".join(output_rows)]
	machine_worker_icon.visible = assigned_worker != null
	machine_remove_worker_button.visible = assigned_worker != null
	if assigned_worker != null:
		var worker_texture: Texture2D = assigned_worker.scenario_character_sheet
		if not assigned_worker.scenario_character_sheets.is_empty(): worker_texture = assigned_worker.scenario_character_sheets[assigned_worker.appearance_id % assigned_worker.scenario_character_sheets.size()]
		var portrait := AtlasTexture.new()
		portrait.atlas = worker_texture
		portrait.region = Rect2(0, 160, 64, 80)
		machine_worker_icon.texture = portrait


func _remove_machine_worker() -> void:
	for villager: Variant in villagers.values():
		if not villager.task.is_empty() and str(villager.task.get("type", "")) == "work" and str(villager.task.get("target", "")) == active_machine_id:
			villager.clear_task()
	_update_machine_panel()


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
	var source_valid := storage_by_entity_id.has(source_id) or machines_by_entity_id.has(source_id) or _is_water_source_id(source_id)
	var destination_valid := storage_by_entity_id.has(destination_id) or machines_by_entity_id.has(destination_id)
	if not source_valid or not destination_valid:
		return false
	if villager_id.is_empty():
		villager_id = selected_villager_id
	if not villagers.has(villager_id):
		interaction_label.text = "Select a villager before creating a route"
		return false
	if item_id.is_empty():
		if _is_water_source_id(source_id):
			item_id = "water"
		else:
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


func is_route_enabled(route_id: String) -> bool:
	for route: Variant in logistics_routes:
		if route.route_id == route_id: return route.enabled
	return false


func _route_source_inventory(source_id: String) -> Variant:
	if storage_by_entity_id.has(source_id): return storage_by_entity_id[source_id]
	if machines_by_entity_id.has(source_id): return machines_by_entity_id[source_id].output_inventory
	return null


func _destination_accepts(destination_id: String, item_id: String) -> bool:
	if storage_by_entity_id.has(destination_id): return storage_by_entity_id[destination_id].capacity_for(item_id) > 0
	if machines_by_entity_id.has(destination_id): return machines_by_entity_id[destination_id].accepts(item_id)
	return false


func villager_collect(villager: Variant) -> int:
	if _is_water_source_id(str(villager.task.source)) and str(villager.task.item) == "water":
		villager.carrying_item = "water"
		villager.carrying_amount = 3
		return 3
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
	if machines_by_entity_id.has(destination_id):
		accepted = machines_by_entity_id[destination_id].add_input(villager.carrying_item, villager.carrying_amount)
		if accepted > 0: machines_by_entity_id[destination_id].manually_activated = true
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
		var name_pool: Array[String] = scenario.resident_names if not scenario.resident_names.is_empty() else VILLAGER_NAMES
		var display_name := name_pool[(next_villager_id - 1) % name_pool.size()]
		var appearance := (next_villager_id - 1) % 6
		var tint: Color = _villager_appearance_tint(appearance)
		var villager: Variant = VillagerType.new()
		var character_options: Variant = scenario.character_sheet_paths if not scenario.character_sheet_paths.is_empty() else scenario.character_sheet_path
		villager.configure(villager_id, display_name, home_id, home_target.global_position + Vector2((index * 14) - 7, 28), tint, appearance, character_options)
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
	var character_options: Variant = scenario.character_sheet_paths if not scenario.character_sheet_paths.is_empty() else scenario.character_sheet_path
	villager.configure(villager_id, str(data.get("name", "Villager")), home_id, Vector2(float(values[0]), float(values[1])), Color(float(tint_values[0]), float(tint_values[1]), float(tint_values[2]), float(tint_values[3])), int(data.get("appearance", 0)), character_options)
	villager.home_position = Vector2(float(data.get("home_position", [fallback_position.x, fallback_position.y])[0]), float(data.get("home_position", [fallback_position.x, fallback_position.y])[1]))
	villager.hunger = float(data.get("hunger", 100.0))
	villager.energy = float(data.get("energy", 100.0))
	villager.state = str(data.get("state", "available"))
	villager.work_priority = clampi(int(data.get("priority", 1)), 0, 2)
	villager.profession = str(data.get("profession", "generalist"))
	villager.experience = data.get("experience", {}).duplicate(true)
	villager.inside_workplace = bool(data.get("inside_workplace", false))
	villager.visible = not villager.inside_workplace
	villager.facing = str(data.get("facing", "south"))
	villager.task = data.get("task", {}).duplicate(true)
	villager.task_queue.assign(data.get("task_queue", []))
	villager.carrying_item = str(data.get("carrying_item", ""))
	villager.carrying_amount = int(data.get("carrying_amount", 0))
	add_child(villager)
	villagers[villager_id] = villager
	next_villager_id = maxi(next_villager_id, int(villager_id.get_slice("-", 1)) + 1)
	return villager


func is_sleep_time() -> bool:
	var fraction := day_time_seconds / DAY_LENGTH_SECONDS
	return fraction >= 0.78 or fraction < 0.16


func active_environment_event() -> Dictionary:
	var fraction := day_time_seconds / DAY_LENGTH_SECONDS
	for event: Dictionary in scenario.environmental_events:
		var start := float(event.get("starts_at", 0.0))
		var duration := float(event.get("duration", 0.0))
		if fraction >= start and fraction < start + duration: return event
	return {}


func environment_multiplier(property_name: String) -> float:
	var event := active_environment_event()
	return float(event.get(property_name, 1.0)) if not event.is_empty() else 1.0


func is_work_time() -> bool:
	var fraction := day_time_seconds / DAY_LENGTH_SECONDS
	return fraction >= 0.18 and fraction < 0.75


func definition_for_instance(instance_id: String) -> Variant:
	var placed: Variant = world_grid.entities_by_id.get(instance_id)
	return placement_registry.get_entity(placed.definition_id) if placed != null else null


func find_food_storage_for(villager: Variant) -> Variant:
	var nearest: Variant = null
	var distance := INF
	for instance_id: String in storage_by_entity_id:
		if storage_by_entity_id[instance_id].count(scenario.food_item_id) <= 0: continue
		var target: Variant = placed_targets.get(instance_id)
		if target == null: continue
		var candidate: float = villager.global_position.distance_squared_to(target.global_position)
		if candidate < distance: nearest = target; distance = candidate
	return nearest


func consume_food_from_storage(storage_id: String) -> bool:
	if not storage_by_entity_id.has(storage_id): return false
	return storage_by_entity_id[storage_id].remove(scenario.food_item_id, 1) == 1


func assigned_villagers_to(instance_id: String) -> int:
	var count := 0
	for villager: Variant in villagers.values():
		if villager.state == "working" and not villager.task.is_empty() and str(villager.task.get("type", "")) == "work" and str(villager.task.get("target", "")) == instance_id:
			count += 1
	return count


func worker_efficiency_at(instance_id: String) -> float:
	var total := 0.0
	var count := 0
	for villager: Variant in villagers.values():
		if villager.state != "working" or villager.task.is_empty() or str(villager.task.get("target", "")) != instance_id: continue
		var skill := float(villager.experience.get(villager.profession, 0.0))
		total += 1.0 + minf(0.5, floorf(skill / 120.0) * 0.1)
		count += 1
	return total / count if count > 0 else 1.0


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
	_hide_subject_panels()
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
	storage_player_label.text = "▶  PLAYER" if storage_focus_side == 0 else "PLAYER"
	for index in range(inventory.slots.size()):
		var slot: Dictionary = inventory.slots[index]
		var selected := storage_focus_side == 0 and index == selected_slot
		storage_player_rows[index].color = Color("#6b3e20") if selected else Color("#ead39f")
		storage_player_slot_labels[index].text = "%d   %s" % [index + 1, _slot_text(slot)]
		storage_player_slot_labels[index].add_theme_color_override("font_color", Color.WHITE if selected else Color("#3b281b"))
		if index < storage_player_icons.size(): _sync_item_icon(storage_player_icons[index], slot)
	storage_player_label.add_theme_color_override("font_color", Color("#6b3e20") if storage_focus_side == 0 else Color("#3b281b"))
	storage_contents_label.text = "▶  CRATE" if storage_focus_side == 1 else "CRATE"
	for index in range(storage.slots.size()):
		var selected := storage_focus_side == 1 and index == selected_storage_slot
		storage_crate_rows[index].visible = true
		storage_crate_rows[index].color = Color("#6b3e20") if selected else Color("#ead39f")
		storage_crate_slot_labels[index].visible = true
		storage_crate_slot_labels[index].text = "%d   %s" % [index + 1, _slot_text(storage.slots[index])]
		storage_crate_slot_labels[index].add_theme_color_override("font_color", Color.WHITE if selected else Color("#3b281b"))
		if index < storage_crate_icons.size(): _sync_item_icon(storage_crate_icons[index], storage.slots[index])
	for index in range(storage.slots.size(), storage_crate_icons.size()):
		storage_crate_icons[index].visible = false
		storage_crate_rows[index].visible = false
		storage_crate_slot_labels[index].visible = false
	storage_contents_label.add_theme_color_override("font_color", Color("#6b3e20") if storage_focus_side == 1 else Color("#3b281b"))
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
		for storage: Variant in storage_by_entity_id.values(): food += storage.count(scenario.food_item_id)
		var total_minutes := roundi(day_time_seconds / DAY_LENGTH_SECONDS * 24.0 * 60.0)
		var people_word := str(scenario.terminology.get("people", "people"))
		var event := active_environment_event()
		var event_text := " | ⚠ %s" % str(event.label) if not event.is_empty() else ""
		population_label.text = "%d %s | %d assigned | %d meals | %02d:%02d%s" % [1 + villagers.size(), people_word, active, food, (total_minutes / 60) % 24, total_minutes % 60, event_text]


func _refresh_population_capacity() -> void:
	workforce.set_population(1 + villagers.size())
	_update_population_hud()


func _draw() -> void:
	if world_grid != null:
		for placed: Variant in world_grid.entities_by_id.values():
			if placed.definition_id == "TREE_CROP": continue
			var site: Variant = construction_by_entity_id.get(placed.instance_id)
			if site != null and not site.complete:
				for cell: Vector2i in placed.cells:
					var placed_rect := Rect2(Vector2(cell * CELL_SIZE) + Vector2.ONE * 2.0, Vector2.ONE * (CELL_SIZE - 4))
					draw_rect(placed_rect, Color("#8c7a66"))
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
			_draw_structure_sprite(definition.entity_id, validation.cells, true, validation.valid)
	for route: Variant in logistics_routes:
		var from_target: Variant = placed_targets.get(route.source_id)
		var to_target: Variant = placed_targets.get(route.destination_id)
		if from_target == null or to_target == null:
			continue
		var start: Vector2 = from_target.global_position
		var finish: Vector2 = to_target.global_position
		var worker: Variant = villagers.get(route.villager_id)
		var route_color: Color = Color("#75808a") if not route.enabled else Color("#e1bd62")
		if worker != null and (worker.state.begins_with("blocked") or worker.state.begins_with("waiting")):
			route_color = Color("#cf6b4d")
		draw_dashed_line(start, finish, route_color, 3.0, 10.0 if route.enabled else 5.0)
		var midpoint := start.lerp(finish, 0.5)
		var direction: Vector2 = (finish - start).normalized()
		var side := direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([midpoint + direction * 9.0, midpoint - direction * 7.0 + side * 6.0, midpoint - direction * 7.0 - side * 6.0]), route_color)
	if not route_source_id.is_empty():
		var source_target: Variant = placed_targets.get(route_source_id)
		if source_target != null:
			draw_circle(source_target.global_position, 23.0, Color("#ffe27a"), false, 4.0)


func _draw_shoreline(cell: Vector2i, destination: Rect2) -> void:
	var bits := 0
	if not water_cells.has(cell + Vector2i.UP): bits |= 1
	if not water_cells.has(cell + Vector2i.RIGHT): bits |= 2
	if not water_cells.has(cell + Vector2i.DOWN): bits |= 4
	if not water_cells.has(cell + Vector2i.LEFT): bits |= 8
	if bits > 0:
		draw_texture_rect_region(SHORELINE_TEXTURE, destination, Rect2((bits % 4) * 64, floori(bits / 4.0) * 64, 64, 64))
	var diagonals := [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]
	var adjacent_pairs := [[Vector2i.UP, Vector2i.LEFT], [Vector2i.UP, Vector2i.RIGHT], [Vector2i.DOWN, Vector2i.RIGHT], [Vector2i.DOWN, Vector2i.LEFT]]
	for index in range(4):
		if not water_cells.has(cell + diagonals[index]) and water_cells.has(cell + adjacent_pairs[index][0]) and water_cells.has(cell + adjacent_pairs[index][1]):
			draw_texture_rect_region(SHORELINE_CORNER_TEXTURE, destination, Rect2(index * 64, 0, 64, 64))


func _draw_path_cell(cell: Vector2i, destination: Rect2) -> void:
	if path_texture != null:
		var source_position := Vector2((cell.x * CELL_SIZE) % path_texture.get_width(), (cell.y * CELL_SIZE) % path_texture.get_height())
		draw_texture_rect_region(path_texture, destination, Rect2(source_position, Vector2.ONE * CELL_SIZE))
		return
	draw_rect(destination, Color("#b89559") if (cell.x + cell.y) % 2 == 0 else Color("#bea064"))
	var seed_value := cell.x * 92821 + cell.y * 68917
	for index in range(3):
		var px := float(posmod(seed_value + index * 11, 25) + 4)
		var py := float(posmod(seed_value / 7 + index * 17, 23) + 5)
		draw_circle(destination.position + Vector2(px, py), 1.5, Color("#836c47"), false, 1.0)


func _draw_structure_sprite(definition_id: String, cells: Array[Vector2i], ghost: bool = false, valid: bool = true) -> void:
	if definition_id == "TREE_CROP" and not cells.is_empty():
		var center := Vector2(cells[0] * CELL_SIZE) + Vector2(CELL_SIZE * 0.5, CELL_SIZE)
		var crop_tint := Color(0.45, 1.0, 0.55, 0.72) if valid else Color(1.0, 0.35, 0.35, 0.72)
		draw_texture_rect_region(TREE_GROWTH_TEXTURE, Rect2(center - Vector2(28, 42), Vector2(56, 42)), Rect2(0, 0, TREE_GROWTH_TEXTURE.get_width() / 4.0, TREE_GROWTH_TEXTURE.get_height()), crop_tint if ghost else Color.WHITE)
		return
	var columns := {"STORAGE_CRATE": 0, "BRICK_KILN": 1, "DWELLING": 2, "SHRINE": 3}
	var economy_columns := {"GRAIN_FARM": 0, "BAKERY": 1, "BREWERY": 2, "KITCHEN": 3, "SAWMILL": 4}
	var industry_columns := {"QUARRY": 0, "COPPER_MINE": 1, "COPPER_SMELTER": 2, "WEAVER": 3, "PAPYRUS_WORKSHOP": 4}
	var definition: Variant = placement_registry.get_entity(definition_id)
	var visual: Dictionary = definition.visual if definition != null else {}
	if (not columns.has(definition_id) and not economy_columns.has(definition_id) and not industry_columns.has(definition_id) and visual.is_empty()) or cells.is_empty(): return
	var minimum := cells[0]
	var maximum := cells[0]
	for cell: Vector2i in cells:
		minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
		maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
	var footprint_size := Vector2(maximum - minimum + Vector2i.ONE) * CELL_SIZE
	var sprite_size := Vector2(maxf(48.0, footprint_size.x + 20.0), maxf(56.0, footprint_size.y + 28.0))
	if definition_id == "GRAIN_FARM": sprite_size = Vector2(128, 112)
	elif definition_id in ["DWELLING", "BAKERY", "BREWERY", "KITCHEN", "SAWMILL", "QUARRY", "COPPER_MINE", "COPPER_SMELTER", "WEAVER", "PAPYRUS_WORKSHOP"]: sprite_size *= 2.0
	elif definition_id == "SHRINE": sprite_size = Vector2(maxf(112.0, footprint_size.x + 36.0), maxf(116.0, footprint_size.y + 20.0)) * 2.0
	var bottom_center := Vector2((minimum.x + maximum.x + 1) * CELL_SIZE * 0.5, (maximum.y + 1) * CELL_SIZE)
	if visual.has("scale"): sprite_size *= float(visual.scale)
	var destination := Rect2(bottom_center - Vector2(sprite_size.x * 0.5, sprite_size.y), sprite_size)
	var tint := Color(0.45, 1.0, 0.55, 0.62) if valid else Color(1.0, 0.35, 0.35, 0.62)
	if not visual.is_empty():
		var texture := load(str(visual.texture)) as Texture2D
		var columns_count := maxi(1, int(visual.get("columns", 1)))
		var rows_count := maxi(1, int(visual.get("rows", 1)))
		var region_size := Vector2(texture.get_width() / float(columns_count), texture.get_height() / float(rows_count))
		var source := Rect2(Vector2(int(visual.get("column", 0)), int(visual.get("row", 0))) * region_size, region_size)
		draw_texture_rect_region(texture, destination, source, tint if ghost else Color.WHITE)
	elif industry_columns.has(definition_id):
		var cell_width := INDUSTRY_BUILDING_TEXTURE.get_width() / 5.0
		draw_texture_rect_region(INDUSTRY_BUILDING_TEXTURE, destination, Rect2(int(industry_columns[definition_id]) * cell_width, 0, cell_width, INDUSTRY_BUILDING_TEXTURE.get_height()), tint if ghost else Color.WHITE)
	elif economy_columns.has(definition_id):
		var cell_width := ECONOMY_BUILDING_TEXTURE.get_width() / 5.0
		draw_texture_rect_region(ECONOMY_BUILDING_TEXTURE, destination, Rect2(int(economy_columns[definition_id]) * cell_width, 0, cell_width, ECONOMY_BUILDING_TEXTURE.get_height()), tint if ghost else Color.WHITE)
	elif definition_id == "SHRINE":
		draw_texture_rect(SHRINE_TEXTURE, destination, false, tint if ghost else Color.WHITE)
	else:
		draw_texture_rect_region(BUILDING_TEXTURE, destination, Rect2(int(columns[definition_id]) * 256, 0, 256, 256), tint if ghost else Color.WHITE)
