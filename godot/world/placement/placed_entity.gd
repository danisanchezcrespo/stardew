class_name PlacedEntity
extends RefCounted

var instance_id: String = ""
var definition_id: String = ""
var origin: Vector2i = Vector2i.ZERO
var rotation: int = 0
var cells: Array[Vector2i] = []


func _init(id: String, type_id: String, placed_origin: Vector2i, placed_rotation: int, occupied_cells: Array[Vector2i]) -> void:
	instance_id = id
	definition_id = type_id
	origin = placed_origin
	rotation = placed_rotation
	cells = occupied_cells.duplicate()
