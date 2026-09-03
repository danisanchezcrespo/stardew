class_name WorldPickup
extends Node2D

var stable_id := ""
var item_id := ""
var amount := 0
var item_label := ""
var item_color := Color.WHITE
var targeted := false


func configure(id: String, definition: Variant, stack_amount: int) -> void:
	stable_id = id
	item_id = definition.item_id
	item_label = definition.label
	item_color = definition.color
	amount = stack_amount
	queue_redraw()


func interaction_position() -> Vector2:
	return global_position


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
	draw_circle(Vector2.ZERO, 10.0, item_color)
	draw_circle(Vector2.ZERO, 13.0, Color.WHITE if targeted else Color(0, 0, 0, 0), false, 3.0)
	if targeted:
		draw_line(Vector2(0, -18), Vector2(0, -12), Color.WHITE, 2.0)
