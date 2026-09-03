class_name PhysicalSaveCodec
extends RefCounted

const VERSION := 1
static var pending_reload := false

func capture(game: Node2D) -> Dictionary:
	var entities: Array[Dictionary] = []
	for placed: Variant in game.world_grid.entities_by_id.values():
		var row := {"id": placed.instance_id, "definition_id": placed.definition_id, "origin": [placed.origin.x, placed.origin.y], "rotation": placed.rotation}
		var site: Variant = game.construction_by_entity_id.get(placed.instance_id)
		if site != null:
			row.construction = {"delivered": site.delivered.duplicate(true), "work_done": site.work_done, "complete": site.complete}
		var storage: Variant = game.storage_by_entity_id.get(placed.instance_id)
		if storage != null: row.storage = storage.snapshot()
		var machine: Variant = game.machines_by_entity_id.get(placed.instance_id)
		if machine != null:
			row.machine = {"input": machine.input_inventory.snapshot(), "output": machine.output_inventory.snapshot(), "remaining": machine.remaining_seconds, "batches": machine.batches_completed, "durability": machine.durability, "broken": machine.broken}
		entities.append(row)
	var routes: Array[Dictionary] = []
	for route: Variant in game.logistics_routes:
		routes.append({"id": route.route_id, "source": route.source_id, "destination": route.destination_id, "progress": route.progress_seconds, "trips": route.trips_completed})
	var pickup_amounts: Dictionary = {}
	for pickup: Variant in game.pickups:
		if is_instance_valid(pickup): pickup_amounts[pickup.stable_id] = pickup.amount
	return {"version": VERSION, "player_position": [game.player.position.x, game.player.position.y], "inventory": game.inventory.snapshot(), "entities": entities, "routes": routes, "pickups": pickup_amounts, "campaign": {"completed": game.campaign.completed.duplicate(true), "wood": game.campaign.gathered_wood, "clay": game.campaign.gathered_clay}, "workforce": {"food": game.workforce.food_reserve}}

func save_to_path(game: Node2D, path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(capture(game)))
	return OK

func load_from_path(game: Node2D, path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", -1)) != VERSION: return ERR_INVALID_DATA
	return restore(game, data)

func restore(game: Node2D, data: Dictionary) -> Error:
	if not game.world_grid.entities_by_id.is_empty(): return ERR_ALREADY_IN_USE
	game.inventory.slots = _slots(data.get("inventory", []), game.inventory.slot_count)
	var player_position: Array = data.get("player_position", [208, 208])
	game.player.position = Vector2(float(player_position[0]), float(player_position[1]))
	for pickup: Variant in game.pickups:
		if is_instance_valid(pickup) and data.get("pickups", {}).has(pickup.stable_id):
			pickup.amount = int(data.pickups[pickup.stable_id])
			pickup.visible = pickup.amount > 0
	for row: Dictionary in data.get("entities", []):
		var definition: Variant = game.placement_registry.get_entity(str(row.definition_id))
		if definition == null: return ERR_INVALID_DATA
		var origin := Vector2i(int(row.origin[0]), int(row.origin[1]))
		var result: Variant = game.world_grid.place(str(row.id), definition.entity_id, definition.spatial_footprint, origin, int(row.rotation), definition.allowed_terrain)
		if not result.valid: return ERR_INVALID_DATA
		game._add_placed_collision(str(row.id), result.cells)
		if row.has("construction"):
			var site := ConstructionSite.new(str(row.id), definition.construction_cost, definition.construction_work_seconds)
			site.delivered = row.construction.delivered.duplicate(true)
			site.work_done = float(row.construction.work_done)
			site.complete = bool(row.construction.complete)
			game.construction_by_entity_id[str(row.id)] = site
		game._add_placed_target(str(row.id), definition, origin, int(row.rotation))
		if row.has("storage"):
			var storage := PlayerInventory.new(game.item_registry, definition.storage_slots)
			storage.slots = _slots(row.storage, storage.slot_count)
			game.storage_by_entity_id[str(row.id)] = storage
		if row.has("machine"):
			var machine := PhysicalMachine.new(str(row.id), definition.recipe_inputs, definition.recipe_outputs, definition.process_time_sec, game.item_registry)
			machine.input_inventory.slots = _slots(row.machine.input, machine.input_inventory.slot_count)
			machine.output_inventory.slots = _slots(row.machine.output, machine.output_inventory.slot_count)
			machine.remaining_seconds = float(row.machine.remaining)
			machine.batches_completed = int(row.machine.batches)
			machine.durability = int(row.machine.durability)
			machine.broken = bool(row.machine.broken)
			game.machines_by_entity_id[str(row.id)] = machine
			game.workforce.register_job(str(row.id), ceili(definition.workers_required), definition.worker_priority)
		game.next_placed_id = maxi(game.next_placed_id, int(str(row.id).get_slice("-", 1)) + 1)
	for row: Dictionary in data.get("routes", []):
		var route := PhysicalRoute.new(str(row.id), str(row.source), str(row.destination))
		route.progress_seconds = float(row.progress)
		route.trips_completed = int(row.trips)
		game.logistics_routes.append(route)
	game._refresh_population_capacity()
	var campaign_data: Dictionary = data.get("campaign", {})
	game.campaign.completed = campaign_data.get("completed", {}).duplicate(true)
	game.campaign.gathered_wood = bool(campaign_data.get("wood", false))
	game.campaign.gathered_clay = bool(campaign_data.get("clay", false))
	game.workforce.food_reserve = float(data.get("workforce", {}).get("food", 0.0))
	game._update_inventory_hud()
	game.queue_redraw()
	return OK

func _slots(value: Array, count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(count):
		result.append(value[index].duplicate(true) if index < value.size() and typeof(value[index]) == TYPE_DICTIONARY else {})
	return result
