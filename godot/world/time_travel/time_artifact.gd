class_name TimeArtifact
extends Node2D

var stable_id := ""
var artifact_id := ""
var label := "Artifact"
var target_kind := "artifact"
var targeted := false

func configure(data: Dictionary) -> void:
	artifact_id = str(data.id); stable_id = "artifact-%s" % artifact_id; label = str(data.label); queue_redraw()
func interaction_position() -> Vector2: return global_position
func is_interactable() -> bool: return true
func set_targeted(value: bool) -> void: targeted = value; queue_redraw()
func _draw() -> void:
	draw_circle(Vector2(0, 5), 15, Color(0,0,0,0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-20),Vector2(15,-5),Vector2(9,16),Vector2(-9,16),Vector2(-15,-5)]), Color("#e4bc58"))
	draw_polyline(PackedVector2Array([Vector2(0,-20),Vector2(15,-5),Vector2(9,16),Vector2(-9,16),Vector2(-15,-5),Vector2(0,-20)]), Color("#fff0a5"), 3)
	if targeted: draw_arc(Vector2(0,-2), 26, 0, TAU, 32, Color.WHITE, 3)
