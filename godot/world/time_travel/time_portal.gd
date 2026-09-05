class_name TimePortal
extends Node2D

var stable_id := ""
var slot := 0
var label := "Dormant portal"
var target_kind := "time_portal"
var targeted := false
var powered := false
var bound_era := ""

func configure(index: int, display_label: String, is_powered: bool, era_id: String = "") -> void:
	slot = index; stable_id = "portal-%d" % index; label = display_label; powered = is_powered; bound_era = era_id; queue_redraw()

func interaction_position() -> Vector2: return global_position
func is_interactable() -> bool: return true
func set_targeted(value: bool) -> void: targeted = value; queue_redraw()

func _draw() -> void:
	var glow := Color("#62dcff") if powered else Color("#53606c")
	if powered: draw_circle(Vector2.ZERO, 42.0, Color(glow, 0.16))
	draw_arc(Vector2.ZERO, 34.0, PI, TAU, 32, glow, 8.0)
	draw_line(Vector2(-34, 0), Vector2(-34, 38), glow, 8.0)
	draw_line(Vector2(34, 0), Vector2(34, 38), glow, 8.0)
	draw_line(Vector2(-45, 38), Vector2(45, 38), Color("#3a3340"), 12.0)
	if powered:
		draw_circle(Vector2.ZERO, 26.0, Color("#19295d"))
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 24, Color("#a8f2ff"), 3.0)
	if targeted: draw_arc(Vector2.ZERO, 49.0, 0, TAU, 40, Color.WHITE, 3.0)
