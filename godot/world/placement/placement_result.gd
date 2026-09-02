class_name PlacementResult
extends RefCounted

const OK := "OK"
const OUT_OF_BOUNDS := "OUT_OF_BOUNDS"
const OCCUPIED := "OCCUPIED"
const INVALID_TERRAIN := "INVALID_TERRAIN"
const ROTATION_NOT_ALLOWED := "ROTATION_NOT_ALLOWED"
const INVALID_ENTITY_ID := "INVALID_ENTITY_ID"

var valid: bool = false
var reason: String = OK
var cells: Array[Vector2i] = []
var blocking_cell: Vector2i = Vector2i.ZERO


func _init(is_valid: bool, reason_code: String, transformed_cells: Array[Vector2i], blocked_at: Vector2i = Vector2i.ZERO) -> void:
	valid = is_valid
	reason = reason_code
	cells = transformed_cells.duplicate()
	blocking_cell = blocked_at
