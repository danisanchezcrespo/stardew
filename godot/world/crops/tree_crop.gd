class_name TreeCrop
extends Node2D

const GROWTH_TEXTURE = preload("res://assets/generated/crops/tree_growth_v2.png")
const STAGE_SECONDS := 60.0
var stable_id := ""
var target_kind := "crop"
var item_label := "Tree seed"
var stage := 0
var growth_elapsed := 0.0
var watered := false
var targeted := false
var grid_cell := Vector2i.ZERO

func configure(id: String, cell: Vector2i, initial_stage: int = 0) -> void:
	stable_id = id; grid_cell = cell; stage = clampi(initial_stage, 0, 3)
	item_label = stage_label(); queue_redraw()
func process_growth(delta: float) -> bool:
	if not watered or stage >= 3: return false
	growth_elapsed += maxf(delta, 0.0)
	if growth_elapsed < STAGE_SECONDS: return false
	stage += 1; growth_elapsed = 0.0; watered = false; item_label = stage_label(); queue_redraw(); return true
func water() -> bool:
	if stage >= 3 or watered: return false
	watered = true; growth_elapsed = 0.0; queue_redraw(); return true
func progress() -> float: return clampf(growth_elapsed / STAGE_SECONDS, 0.0, 1.0) if watered else 0.0
func stage_label() -> String: return ["Seed", "Sprout", "Young tree", "Mature tree"][stage]
func interaction_position() -> Vector2: return global_position
func interaction_position_for(_player_position: Vector2) -> Vector2: return global_position
func is_interactable() -> bool: return true
func set_targeted(value: bool) -> void: targeted = value; queue_redraw()
func _draw() -> void:
	var cell_width := GROWTH_TEXTURE.get_width() / 4.0
	var size := Vector2([56.0, 66.0, 86.0, 112.0][stage], [42.0, 58.0, 76.0, 104.0][stage])
	draw_texture_rect_region(GROWTH_TEXTURE, Rect2(Vector2(-size.x * 0.5, -size.y + 13.0), size), Rect2(stage * cell_width, 0, cell_width, GROWTH_TEXTURE.get_height()))
	if targeted: draw_circle(Vector2(0, 2), 20.0, Color.WHITE, false, 2.0)
