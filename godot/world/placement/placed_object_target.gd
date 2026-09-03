class_name PlacedObjectTarget
extends Node2D

var stable_id := ""
var item_label := ""
var target_kind := "storage"
var targeted := false
var interaction_offset := Vector2.ZERO


func configure(instance_id: String, label: String, world_position: Vector2, use_position: Vector2, kind: String = "storage") -> void:
	stable_id = instance_id
	item_label = label
	target_kind = kind
	global_position = world_position
	interaction_offset = use_position - world_position
	queue_redraw()


func interaction_position() -> Vector2:
	return global_position + interaction_offset


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
