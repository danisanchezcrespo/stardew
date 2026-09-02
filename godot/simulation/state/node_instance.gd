class_name SimulationNodeInstance
extends RefCounted

const STATE_UNDER_CONSTRUCTION := "UNDER_CONSTRUCTION"
const STATE_READY := "READY"
const STATE_RUNNING := "RUNNING"

var id: int = 0
var entity_type: String = ""
var world_x: float = 0.0
var world_y: float = 0.0
var state: String = STATE_READY
var inventory: Dictionary = {}
var construction_progress: Dictionary = {}
var active_process_total_sec: float = 0.0
var active_process_remaining_sec: float = 0.0
var active_process_output_name: Variant = null
var workers_assigned: float = 0.0
var worker_efficiency: float = 1.0


func _init(node_id: int = 0, type_id: String = "", x: float = 0.0, y: float = 0.0) -> void:
	id = node_id
	entity_type = type_id
	world_x = x
	world_y = y
