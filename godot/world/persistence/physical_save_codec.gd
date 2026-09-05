class_name PhysicalSaveCodec
extends RefCounted

const VERSION := 4
static var pending_reload := false
static var pending_reload_path := "user://physical_save.json"

func capture(game: Node2D) -> Dictionary:
	var entities: Array[Dictionary] = []
	for placed: Variant in game.world_grid.entities_by_id.values():
		var row := {"id": placed.instance_id, "definition_id": placed.definition_id, "origin": [placed.origin.x, placed.origin.y], "rotation": placed.rotation}
		if placed.definition_id == "TREE_CROP":
			for crop: Variant in game.crops:
				if is_instance_valid(crop) and crop.stable_id == placed.instance_id:
					row.crop = {"stage": crop.stage, "elapsed": crop.growth_elapsed, "watered": crop.watered}
					break
		var site: Variant = game.construction_by_entity_id.get(placed.instance_id)
		if site != null:
			row.construction = {"delivered": site.delivered.duplicate(true), "work_done_seconds": site.work_done_seconds, "complete": site.complete}
		var storage: Variant = game.storage_by_entity_id.get(placed.instance_id)
		if storage != null: row.storage = storage.snapshot()
		var machine: Variant = game.machines_by_entity_id.get(placed.instance_id)
		if machine != null:
			row.machine = {"input": machine.input_inventory.snapshot(), "output": machine.output_inventory.snapshot(), "remaining": machine.remaining_seconds, "batches": machine.batches_completed, "durability": machine.durability, "max_durability":machine.max_durability, "broken": machine.broken, "manually_activated": machine.manually_activated}
		entities.append(row)
	var routes: Array[Dictionary] = []
	for route: Variant in game.logistics_routes:
		routes.append({"id": route.route_id, "source": route.source_id, "destination": route.destination_id, "villager": route.villager_id, "item": route.item_id, "progress": route.progress_seconds, "trips": route.trips_completed, "enabled": route.enabled, "priority": route.priority})
	var villagers: Array[Dictionary] = []
	for villager: Variant in game.villagers.values():
		villagers.append({"id": villager.stable_id, "name": villager.villager_name, "appearance": villager.appearance_id, "priority": villager.work_priority, "profession": villager.profession, "experience": villager.experience.duplicate(true), "inside_workplace": villager.inside_workplace, "home": villager.home_id, "home_position": [villager.home_position.x, villager.home_position.y], "position": [villager.position.x, villager.position.y], "hunger": villager.hunger, "energy": villager.energy, "state": villager.state, "facing": villager.facing, "task": villager.task.duplicate(true), "task_queue": villager.task_queue.duplicate(true), "carrying_item": villager.carrying_item, "carrying_amount": villager.carrying_amount, "tint": [villager.color_tint.r, villager.color_tint.g, villager.color_tint.b, villager.color_tint.a]})
	var pickup_amounts: Dictionary = {}
	for pickup: Variant in game.pickups:
		if is_instance_valid(pickup): pickup_amounts[pickup.stable_id] = pickup.amount
	var source_states: Dictionary = {}
	for source: Variant in game.resource_sources:
		if is_instance_valid(source): source_states[source.stable_id] = {"amount": source.current_amount, "regen_elapsed": source.regen_elapsed}
	var dependents: Array[Dictionary] = []
	for actor: Variant in game.dependents.values():
		dependents.append({"id":actor.stable_id,"species":actor.species_id,"home":actor.home_id,"position":[actor.position.x,actor.position.y],"hunger":actor.hunger,"thirst":actor.thirst,"health":actor.health,"age":actor.age_seconds,"product_elapsed":actor.product_elapsed,"stored_product":actor.stored_product})
	return {"version": VERSION, "scenario_id":game.scenario.scenario_id, "player_position": [game.player.position.x, game.player.position.y], "inventory": game.inventory.snapshot(), "entities": entities, "routes": routes, "villagers": villagers, "dependents":dependents, "day_time": game.day_time_seconds, "pickups": pickup_amounts, "resource_sources": source_states, "campaign": {"completed": game.campaign.completed.duplicate(true), "gathered": game.campaign.gathered_items.duplicate(true), "crafted": game.campaign.crafted_recipes.duplicate(true), "placed": game.campaign.placed_entities.duplicate(true), "buildings": game.campaign.completed_entities.duplicate(true), "wood": game.campaign.gathered_wood, "clay": game.campaign.gathered_clay}, "progression":game.meta_progression.snapshot(), "workforce": {"food": game.workforce.food_reserve}}

func save_to_path(game: Node2D, path: String) -> Error:
	var absolute_path := ProjectSettings.globalize_path(path)
	var temporary_path := absolute_path + ".tmp"
	var backup_path := absolute_path + ".bak"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(capture(game)))
	file.flush()
	file.close()
	if FileAccess.file_exists(backup_path): DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(absolute_path):
		var backup_result := DirAccess.rename_absolute(absolute_path, backup_path)
		if backup_result != OK: return backup_result
	var result := DirAccess.rename_absolute(temporary_path, absolute_path)
	if result != OK and FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(backup_path, absolute_path)
		return result
	if FileAccess.file_exists(backup_path): DirAccess.remove_absolute(backup_path)
	return OK

func load_from_path(game: Node2D, path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return FileAccess.get_open_error()
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", -1)) not in [1, 2, 3, VERSION]: return ERR_INVALID_DATA
	if data.has("scenario_id") and str(data.scenario_id) != game.scenario.scenario_id: return ERR_INVALID_DATA
	return restore(game, data)

func restore(game: Node2D, data: Dictionary) -> Error:
	game.meta_progression.restore(data.get("progression", {}))
	for tech: Dictionary in game.meta_progression.tech_nodes():
		if int(tech.get("cost", 1)) == 0 and not game.meta_progression.unlocked_tech.has(str(tech.id)): game.meta_progression.unlock(str(tech.id))
	for dependent: Variant in game.dependents.values():
		if is_instance_valid(dependent): dependent.queue_free()
	game.dependents.clear()
	for crop: Variant in game.crops:
		if is_instance_valid(crop):
			game.world_grid.remove(crop.stable_id)
			crop.queue_free()
	game.crops.clear()
	if not game.world_grid.entities_by_id.is_empty(): return ERR_ALREADY_IN_USE
	game.inventory.slots = _slots(data.get("inventory", []), game.inventory.slot_count)
	var player_position: Array = data.get("player_position", [208, 208])
	game.player.position = Vector2(float(player_position[0]), float(player_position[1]))
	for pickup: Variant in game.pickups:
		if is_instance_valid(pickup) and data.get("pickups", {}).has(pickup.stable_id):
			pickup.amount = int(data.pickups[pickup.stable_id])
			pickup.visible = pickup.amount > 0
	for source: Variant in game.resource_sources:
		var state: Dictionary = data.get("resource_sources", {}).get(source.stable_id, {})
		if not state.is_empty():
			source.current_amount = clampi(int(state.get("amount", source.current_amount)), 0, source.max_amount)
			source.regen_elapsed = float(state.get("regen_elapsed", 0.0))
			source.queue_redraw()
	var legacy_completed_entities: Array[String] = []
	for row: Dictionary in data.get("entities", []):
		var definition: Variant = game.placement_registry.get_entity(str(row.definition_id))
		if definition == null: return ERR_INVALID_DATA
		var origin := Vector2i(int(row.origin[0]), int(row.origin[1]))
		var result: Variant = game.world_grid.place(str(row.id), definition.entity_id, definition.spatial_footprint, origin, int(row.rotation), definition.allowed_terrain)
		if not result.valid: return ERR_INVALID_DATA
		if definition.entity_id == "TREE_CROP":
			var crop: Variant = game._spawn_crop(str(row.id), origin, int(row.get("crop", {}).get("stage", 0)), false)
			crop.growth_elapsed = float(row.get("crop", {}).get("elapsed", 0.0))
			crop.watered = bool(row.get("crop", {}).get("watered", false))
			if str(row.id).begins_with("placed-"): game.next_placed_id = maxi(game.next_placed_id, int(str(row.id).get_slice("-", 1)) + 1)
			continue
		game._add_placed_collision(str(row.id), result.cells)
		if row.has("construction"):
			var site := ConstructionSite.new(str(row.id), definition.construction_cost, definition.construction_work_seconds)
			site.delivered = row.construction.delivered.duplicate(true)
			site.work_done_seconds = float(row.construction.get("work_done_seconds", row.construction.get("work_done", 0.0)))
			site.complete = bool(row.construction.complete)
			game.construction_by_entity_id[str(row.id)] = site
		elif not definition.construction_cost.is_empty() or definition.construction_work_seconds > 0.0:
			# A definition may gain a blueprint phase after an older save already
			# placed it as a finished building. Preserve it and credit its quest.
			legacy_completed_entities.append(definition.entity_id)
		if row.has("storage"):
			var storage := PlayerInventory.new(game.item_registry, maxi(definition.storage_slots, row.storage.size()))
			storage.slots = _slots(row.storage, storage.slot_count)
			game.storage_by_entity_id[str(row.id)] = storage
		if row.has("machine"):
			var machine := PhysicalMachine.new(str(row.id), definition.recipe_inputs, definition.recipe_outputs, definition.process_time_sec, game.item_registry)
			machine.input_inventory.slots = _slots(row.machine.input, machine.input_inventory.slot_count)
			machine.output_inventory.slots = _slots(row.machine.output, machine.output_inventory.slot_count)
			machine.remaining_seconds = float(row.machine.remaining)
			machine.batches_completed = int(row.machine.batches)
			machine.durability = int(row.machine.durability)
			machine.max_durability = int(row.machine.get("max_durability", 3 + 2 * (game.meta_progression.building_level(str(row.id)) - 1)))
			machine.broken = bool(row.machine.broken)
			machine.manually_activated = bool(row.machine.get("manually_activated", false))
			game.machines_by_entity_id[str(row.id)] = machine
			game.workforce.register_job(str(row.id), ceili(definition.workers_required), definition.worker_priority)
		game._add_placed_target(str(row.id), definition, origin, int(row.rotation))
		var restored_site: Variant = game.construction_by_entity_id.get(str(row.id))
		if restored_site == null or restored_site.complete:
			game.placed_targets[str(row.id)].target_kind = "storage" if row.has("storage") else ("machine" if row.has("machine") else "building")
			game._add_structure_visual(str(row.id), definition.entity_id, result.cells)
		game.next_placed_id = maxi(game.next_placed_id, int(str(row.id).get_slice("-", 1)) + 1)
	for villager_data: Dictionary in data.get("villagers", []):
		game.restore_villager(villager_data)
	for dependent_data: Dictionary in data.get("dependents", []):
		game.restore_dependent(dependent_data)
	if data.get("villagers", []).is_empty():
		for placed: Variant in game.world_grid.entities_by_id.values():
			var definition: Variant = game.placement_registry.get_entity(placed.definition_id)
			var site: Variant = game.construction_by_entity_id.get(placed.instance_id)
			if definition != null and definition.population_capacity > 0 and site != null and site.complete:
				game.spawn_villagers_for_home(placed.instance_id, definition.population_capacity)
	for row: Dictionary in data.get("routes", []):
		game.restore_water_route_target(str(row.source))
		var route := PhysicalRoute.new(str(row.id), str(row.source), str(row.destination), 2.0, str(row.get("villager", "")), str(row.get("item", "")))
		route.progress_seconds = float(row.progress)
		route.trips_completed = int(row.trips)
		route.enabled = bool(row.get("enabled", true))
		route.priority = clampi(int(row.get("priority", 1)), 0, 2)
		game.logistics_routes.append(route)
		game.next_route_id = maxi(game.next_route_id, int(str(row.id).get_slice("-", 1)) + 1)
	game.day_time_seconds = float(data.get("day_time", 180.0))
	if int(data.get("version", VERSION)) < 4: game.day_time_seconds *= 3.0
	game._refresh_population_capacity()
	var campaign_data: Dictionary = data.get("campaign", {})
	game.campaign.completed = campaign_data.get("completed", {}).duplicate(true)
	game.campaign.gathered_items = campaign_data.get("gathered", {}).duplicate(true)
	game.campaign.crafted_recipes = campaign_data.get("crafted", {}).duplicate(true)
	game.campaign.placed_entities = campaign_data.get("placed", {}).duplicate(true)
	game.campaign.completed_entities = campaign_data.get("buildings", {}).duplicate(true)
	for entity_id: String in legacy_completed_entities: game.campaign.completed_entities[entity_id] = true
	game.campaign.gathered_wood = bool(campaign_data.get("wood", false))
	game.campaign.gathered_clay = bool(campaign_data.get("clay", false))
	if game.campaign.gathered_wood: game.campaign.gathered_items["wood"] = true
	if game.campaign.gathered_clay: game.campaign.gathered_items["clay"] = true
	game.workforce.food_reserve = float(data.get("workforce", {}).get("food", 0.0))
	game._update_inventory_hud()
	game.queue_redraw()
	return OK

func _slots(value: Array, count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(count):
		result.append(value[index].duplicate(true) if index < value.size() and typeof(value[index]) == TYPE_DICTIONARY else {})
	return result
