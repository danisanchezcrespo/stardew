class_name EgyptCampaign
extends RefCounted

const OBJECTIVES := [
	{"id": "gather", "label": "Gather wood and clay"},
	{"id": "craft_kiln", "label": "Craft a Brick Kiln plan"},
	{"id": "place_kiln", "label": "Place the Brick Kiln plan"},
	{"id": "build_kiln", "label": "Supply and build the Brick Kiln"},
	{"id": "fire_bricks", "label": "Fire a batch of mud bricks"},
	{"id": "build_home", "label": "Build a Reed Dwelling"},
	{"id": "automate", "label": "Create a porter route"}
]
var completed: Dictionary = {}
var gathered_wood := false
var gathered_clay := false

func record_pickup(item_id: String) -> void:
	if item_id == "wood": gathered_wood = true
	if item_id == "clay": gathered_clay = true
	if gathered_wood and gathered_clay: completed["gather"] = true

func record_craft(recipe_id: String) -> void:
	if recipe_id == "brick_kiln_plan": completed["craft_kiln"] = true

func record_placement(entity_id: String) -> void:
	if entity_id == "BRICK_KILN": completed["place_kiln"] = true

func record_completion(entity_id: String) -> void:
	if entity_id == "BRICK_KILN": completed["build_kiln"] = true
	if entity_id == "DWELLING": completed["build_home"] = true

func refresh(machines: Dictionary, routes: Array) -> void:
	for machine: Variant in machines.values():
		if int(machine.batches_completed) > 0: completed["fire_bricks"] = true
	if not routes.is_empty(): completed["automate"] = true

func current_text() -> String:
	for objective: Dictionary in OBJECTIVES:
		if not completed.has(objective.id):
			return "GOAL  %s  (%d/%d)" % [objective.label, completed.size(), OBJECTIVES.size()]
	return "SETTLEMENT ESTABLISHED  All %d goals complete" % OBJECTIVES.size()

func is_complete() -> bool:
	return completed.size() == OBJECTIVES.size()
