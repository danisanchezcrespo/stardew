class_name PlayerController
extends CharacterBody2D

const InputDefaultsType = preload("res://input/input_defaults.gd")
const LATERAL_CHARACTER_TEXTURE = preload("res://assets/generated/character/egyptian_worker_lateral_10frame_sheet.png")
const VERTICAL_CHARACTER_TEXTURE = preload("res://assets/generated/character/egyptian_worker_vertical_10frame_sheet.png")

const WALK_SPEED_PX := 128.0
const COLLISION_RADIUS_PX := 10.0
const WALK_FRAME_COUNT := 10
const WALK_FRAME_RATE := 10.0
const FRAME_SIZE := Vector2(64, 80)

var facing := "south"
var movement_enabled := true
var animation_time := 0.0


func _ready() -> void:
	InputDefaultsType.ensure_actions()
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = COLLISION_RADIUS_PX
		collision.shape = shape
		add_child(collision)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var intent := Vector2.ZERO
	if movement_enabled:
		intent = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	apply_movement_intent(intent)
	move_and_slide()
	if velocity.is_zero_approx():
		animation_time = 0.0
	else:
		animation_time += delta
	queue_redraw()


func apply_movement_intent(intent: Vector2) -> void:
	var normalized := intent.limit_length(1.0)
	velocity = normalized * WALK_SPEED_PX
	if normalized.is_zero_approx():
		return
	if absf(normalized.x) > absf(normalized.y):
		facing = "east" if normalized.x > 0.0 else "west"
	else:
		facing = "south" if normalized.y > 0.0 else "north"
	queue_redraw()


func _draw() -> void:
	_draw_shadow_ellipse(Vector2(0, 9), Vector2(13, 6), Color(0.0, 0.0, 0.0, 0.25))
	var column := current_animation_frame()
	var texture := VERTICAL_CHARACTER_TEXTURE
	var row := 0 if facing == "south" else 1
	if facing == "west" or facing == "east":
		texture = LATERAL_CHARACTER_TEXTURE
		row = 0 if facing == "west" else 1
	draw_texture_rect_region(
		texture,
		Rect2(Vector2(-32, -64), FRAME_SIZE),
		Rect2(Vector2(column * 64, row * 80), FRAME_SIZE)
	)


func current_animation_frame() -> int:
	if velocity.is_zero_approx():
		return 0
	return int(animation_time * WALK_FRAME_RATE) % WALK_FRAME_COUNT


func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
