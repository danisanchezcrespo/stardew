class_name ResourceSource
extends Node2D

const ItemIconAtlasType = preload("res://items/item_icon_atlas.gd")

var stable_id := ""
var item_id := ""
var item_label := ""
var current_amount := 0
var max_amount := 0
var grant_amount := 1
var regen_amount := 1
var regen_seconds := 10.0
var regen_elapsed := 0.0
var targeted := false
var target_kind := "resource_source"

func configure(id: String, definition: Variant, initial: int, maximum: int, grant: int, regenerate: int, interval: float) -> void:
	stable_id = id
	item_id = definition.item_id
	item_label = definition.label
	max_amount = maxi(1, maximum)
	current_amount = clampi(initial, 0, max_amount)
	grant_amount = maxi(1, grant)
	regen_amount = maxi(1, regenerate)
	regen_seconds = maxf(0.1, interval)
	queue_redraw()

func process_source(delta: float) -> void:
	if current_amount >= max_amount: return
	regen_elapsed += maxf(0.0, delta)
	while regen_elapsed >= regen_seconds and current_amount < max_amount:
		regen_elapsed -= regen_seconds
		current_amount = mini(max_amount, current_amount + regen_amount)
		queue_redraw()

func available_grant() -> int:
	return mini(grant_amount, current_amount)

func take(amount: int) -> int:
	var taken := mini(maxi(amount, 0), current_amount)
	current_amount -= taken
	queue_redraw()
	return taken

func interaction_position() -> Vector2: return global_position
func is_interactable() -> bool: return true
func set_targeted(value: bool) -> void:
	targeted = value
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0, 7), 18.0, Color(0, 0, 0, 0.25))
	draw_circle(Vector2.ZERO, 19.0, Color("#4d8fbd"))
	draw_circle(Vector2.ZERO, 15.0, Color("#d8bd83"))
	draw_texture_rect_region(ItemIconAtlasType.TEXTURE, Rect2(Vector2(-14, -16), Vector2(28, 28)), ItemIconAtlasType.region(item_id))
	if targeted: draw_circle(Vector2.ZERO, 23.0, Color.WHITE, false, 3.0)
