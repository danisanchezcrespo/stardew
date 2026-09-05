class_name Villager
extends Node2D

const LATERAL_TEXTURE = preload("res://assets/generated/character/egyptian_worker_lateral_10frame_sheet.png")
const VERTICAL_TEXTURE = preload("res://assets/generated/character/egyptian_worker_vertical_10frame_sheet.png")
const FRAME_SIZE := Vector2(64, 80)
const WALK_SPEED := 72.0
const FRAME_RATE := 10.0

var stable_id := ""
var villager_name := "Villager"
var home_id := ""
var home_position := Vector2.ZERO
var hunger := 100.0
var energy := 100.0
var state := "available"
var facing := "south"
var animation_time := 0.0
var task: Dictionary = {}
var carrying_item := ""
var carrying_amount := 0
var selected := false
var targeted := false
var target_kind := "villager"
var color_tint := Color.WHITE


func configure(id: String, display_name: String, dwelling_id: String, spawn_position: Vector2, tint: Color = Color.WHITE) -> void:
	stable_id = id
	villager_name = display_name
	home_id = dwelling_id
	home_position = spawn_position
	position = spawn_position
	z_as_relative = false
	z_index = roundi(global_position.y + 10.0)
	color_tint = tint
	queue_redraw()


func assign_transport(route_id: String, source_id: String, destination_id: String, item_id: String) -> void:
	task = {"type": "transport", "route_id": route_id, "source": source_id, "destination": destination_id, "item": item_id, "repeat": true}
	state = "to_source"


func assign_work(target_id: String) -> void:
	task = {"type": "work", "target": target_id}
	state = "to_work"

func assign_move(destination: Vector2) -> void:
	task = {"type": "move", "position": [destination.x, destination.y]}
	state = "moving"


func clear_task() -> void:
	task.clear()
	carrying_item = ""
	carrying_amount = 0
	state = "available"

func interaction_position() -> Vector2:
	return global_position

func is_interactable() -> bool:
	return true

func set_targeted(value: bool) -> void:
	targeted = value
	queue_redraw()


func process_life(game: Node2D, delta: float) -> void:
	z_index = roundi(global_position.y + 10.0)
	hunger = maxf(0.0, hunger - delta * (0.16 if state == "available" or state == "sleeping" else 0.28))
	energy = maxf(0.0, energy - delta * (0.03 if state == "available" else 0.12))
	if state == "sleeping":
		energy = minf(100.0, energy + delta * 5.0)
		if not game.is_sleep_time() and energy >= 75.0:
			state = _resume_state()
		queue_redraw()
		return
	if (game.is_sleep_time() or energy <= 12.0) and carrying_amount == 0:
		state = "going_home"
	if hunger <= 30.0 and carrying_amount == 0 and game.find_food_storage_for(self) != null:
		state = "seeking_food"
	elif hunger <= 0.0 and carrying_amount == 0:
		state = "hungry"
		queue_redraw()
		return
	if state == "going_home":
		if _move_to(home_position, delta): state = "sleeping"
	elif state == "seeking_food":
		var food_target: Variant = game.find_food_storage_for(self)
		if food_target == null:
			state = "hungry"
		elif _move_to(food_target.global_position, delta):
			if game.consume_food_from_storage(food_target.stable_id):
				hunger = minf(100.0, hunger + 70.0)
			state = _resume_state()
	elif not task.is_empty() and str(task.get("type", "transport")) == "move":
		var destination: Array = task.get("position", [position.x, position.y])
		if _move_to(Vector2(float(destination[0]), float(destination[1])), delta):
			task = {}
			state = "available"
	elif not task.is_empty() and str(task.get("type", "transport")) == "work":
		_process_work(game, delta)
	elif not task.is_empty():
		_process_transport(game, delta)
	queue_redraw()


func _process_transport(game: Node2D, delta: float) -> void:
	var source: Variant = game.placed_targets.get(str(task.source))
	var destination: Variant = game.placed_targets.get(str(task.destination))
	if source == null or destination == null:
		state = "blocked: endpoint missing"
		return
	if state == "to_destination":
		if _move_to(destination.global_position, delta):
			var delivered: int = game.villager_deliver(self)
			state = "to_source" if delivered > 0 else "blocked: destination full"
		return
	if state.begins_with("blocked"):
		state = "to_destination" if carrying_amount > 0 else "to_source"
	if _move_to(source.global_position, delta):
		var collected: int = game.villager_collect(self)
		state = "to_destination" if collected > 0 else "waiting: source empty"


func _process_work(game: Node2D, delta: float) -> void:
	var target: Variant = game.placed_targets.get(str(task.target))
	if target == null:
		state = "blocked: workplace missing"
		return
	if _move_to(target.interaction_position_for(position), delta):
		state = "working"
		game.villager_work(self, delta)


func _resume_state() -> String:
	if task.is_empty(): return "available"
	if str(task.get("type", "transport")) == "move": return "moving"
	return "to_work" if str(task.get("type", "transport")) == "work" else ("to_destination" if carrying_amount > 0 else "to_source")


func _move_to(target: Vector2, delta: float) -> bool:
	var offset := target - position
	if offset.length() <= 5.0:
		position = target
		return true
	var direction := offset.normalized()
	var speed := WALK_SPEED * (0.6 if hunger < 30.0 else 1.0)
	position += direction * minf(speed * delta, offset.length())
	if absf(direction.x) > absf(direction.y): facing = "east" if direction.x > 0 else "west"
	else: facing = "south" if direction.y > 0 else "north"
	animation_time += delta
	return false


func status_text() -> String:
	return state.capitalize().replace("_", " ")


func _draw() -> void:
	_draw_shadow_ellipse(Vector2(0, 9), Vector2(12, 5), Color(0, 0, 0, 0.22))
	var texture := VERTICAL_TEXTURE
	var row := 0 if facing == "south" else 1
	if facing == "west" or facing == "east":
		texture = LATERAL_TEXTURE
		row = 0 if facing == "west" else 1
	var moving := state in ["to_source", "to_destination", "to_work", "going_home", "seeking_food"]
	var frame := int(animation_time * FRAME_RATE) % 10 if moving else 0
	draw_texture_rect_region(texture, Rect2(-32, -64, 64, 80), Rect2(frame * 64, row * 80, 64, 80), color_tint)
	if selected or targeted:
		draw_circle(Vector2(0, 11), 18.0, Color("#ffe27a"), false, 3.0)
	if carrying_amount > 0:
		draw_circle(Vector2(19, -24), 7.0, Color("#dca763"))
		draw_string(ThemeDB.fallback_font, Vector2(16, -31), str(carrying_amount), HORIZONTAL_ALIGNMENT_CENTER, 12, 11, Color.WHITE)


func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
