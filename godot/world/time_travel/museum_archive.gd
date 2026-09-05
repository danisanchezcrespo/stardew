class_name MuseumArchive
extends Node2D

var stable_id := "museum-archive"
var label := "Museum archive"
var target_kind := "museum_archive"
var targeted := false

func interaction_position() -> Vector2: return global_position
func is_interactable() -> bool: return true
func set_targeted(value: bool) -> void: targeted = value; queue_redraw()
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-34,10),Vector2(34,10),Vector2(26,34),Vector2(-26,34)]), Color("#17232e"))
	draw_rect(Rect2(-29,-22,58,34), Color("#7fa8b9")); draw_rect(Rect2(-25,-18,50,26), Color(0.35,0.75,0.9,0.2))
	draw_line(Vector2(-29,-22),Vector2(29,-22),Color("#d8bf72"),3)
	draw_string(ThemeDB.fallback_font, Vector2(-35,55), "ARCHIVE", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, Color("#eaf7ff"))
	if targeted: draw_rect(Rect2(-42,-30,84,92), Color.WHITE, false, 3)
