class_name PlayerController
extends CharacterBody2D

const InputDefaultsType = preload("res://input/input_defaults.gd")

const WALK_SPEED_PX := 128.0
const COLLISION_RADIUS_PX := 10.0

var facing := "south"
var movement_enabled := true


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


func _physics_process(_delta: float) -> void:
	var intent := Vector2.ZERO
	if movement_enabled:
		intent = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	apply_movement_intent(intent)
	move_and_slide()


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
	draw_circle(Vector2(0, 1), 11.0, Color("#efe0bd"))
	draw_rect(Rect2(-9, 5, 18, 16), Color("#3274a8"))
	var direction := {
		"north": Vector2.UP,
		"east": Vector2.RIGHT,
		"south": Vector2.DOWN,
		"west": Vector2.LEFT,
	}[facing] as Vector2
	draw_circle(direction * 8.0 + Vector2(0, 1), 2.5, Color("#2b2520"))


func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
