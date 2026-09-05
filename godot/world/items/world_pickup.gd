class_name WorldPickup
extends Node2D

const ItemIconAtlasType = preload("res://items/item_icon_atlas.gd")

var stable_id := ""
var item_id := ""
var amount := 0
var item_label := ""
var item_color := Color.WHITE
var targeted := false
var target_kind := "pickup"


func configure(id: String, definition: Variant, stack_amount: int) -> void:
	z_as_relative = false
	z_index = -4096
	stable_id = id
	item_id = definition.item_id
	item_label = definition.label
	item_color = definition.color
	amount = stack_amount
	queue_redraw()


func interaction_position() -> Vector2:
	return global_position


func is_interactable() -> bool:
	return amount > 0


func set_targeted(value: bool) -> void:
	if targeted == value:
		return
	targeted = value
	queue_redraw()


func take(maximum: int) -> int:
	var taken := mini(maximum, amount)
	amount -= taken
	queue_redraw()
	return taken


func _draw() -> void:
	draw_circle(Vector2(0, 7), 11.0, Color(0, 0, 0, 0.22))
	draw_texture_rect_region(ItemIconAtlasType.texture(item_id), Rect2(Vector2(-16, -18), Vector2(32, 32)), ItemIconAtlasType.region(item_id))
	draw_circle(Vector2(0, -2), 19.0, Color.WHITE if targeted else Color(0, 0, 0, 0), false, 3.0)
