class_name EntityDefinition
extends RefCounted

const SpatialFootprintType = preload("res://world/spatial/spatial_footprint.gd")

var entity_id: String = ""
var label: String = ""
var color: String = "#888888"

var construction_cost: Dictionary = {}
var initial_amounts: Dictionary = {}
var max_amounts: Dictionary = {}
var recipe_inputs: Dictionary = {}
var recipe_outputs: Dictionary = {}

var source_rate_per_sec: float = 0.0
var process_time_sec: float = 0.0
var shared_resource_modifiers: Dictionary = {}
var workers_required: float = 0.0
var worker_priority: int = 0
var min_worker_efficiency: float = 0.0

var spatial_footprint: RefCounted = null
var allowed_terrain: Array[String] = []


func is_placeable() -> bool:
	return spatial_footprint != null
