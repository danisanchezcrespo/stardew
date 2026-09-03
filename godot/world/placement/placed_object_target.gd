class_name PlacedObjectTarget
extends Node2D

var stable_id := ""
var item_label := ""
var target_kind := "storage"
var targeted := false
var interaction_offset := Vector2.ZERO
var interaction_points: Array[Vector2] = []


func configure(instance_id: String, label: String, world_position: Vector2, use_position: Vector2, kind: String = "storage", footprint_points: Array[Vector2] = []) -> void:
	stable_id = instance_id
	item_label = label
	target_kind = kind
	global_position = world_position
	interaction_offset = use_position - world_position
	interaction_points = footprint_points.duplicate()
	if not interaction_points.has(use_position):
		interaction_points.append(use_position)
	queue_redraw()


func interaction_position() -> Vector2:
	return global_position + interaction_offset


func interaction_position_for(player_position: Vector2) -> Vector2:
	var best := interaction_position()
	var best_distance := player_position.distance_squared_to(best)
	for point: Vector2 in interaction_points:
		var distance := player_position.distance_squared_to(point)
		if distance < best_distance:
			best = point
			best_distance = distance
	return best


func is_interactable() -> bool:
	return true


func set_targeted(value: bool) -> void:
	if targeted == value:
		return
	targeted = value
	queue_redraw()


func _draw() -> void:
	if targeted:
		draw_rect(Rect2(-15, -15, 30, 30), Color.WHITE, false, 3.0)
