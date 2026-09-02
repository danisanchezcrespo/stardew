class_name SimulationEdgeInstance
extends RefCounted

var from_id: int = 0
var to_id: int = 0
var edge_type_id: String = ""
var packet: Variant = null
var return_progress: Variant = null


func _init(source_id: int = 0, target_id: int = 0, type_id: String = "") -> void:
	from_id = source_id
	to_id = target_id
	edge_type_id = type_id
