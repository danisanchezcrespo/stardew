extends SceneTree

const PlayerScene = preload("res://player/player.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	_test_velocity_and_facing(failures)
	await _test_main_scene_and_collision(failures)

	if failures.is_empty():
		print("PASS: player movement")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_velocity_and_facing(failures: Array[String]) -> void:
	var player: CharacterBody2D = PlayerScene.instantiate()
	root.add_child(player)
	player.apply_movement_intent(Vector2(1, 1))
	_expect(is_equal_approx(player.velocity.length(), 128.0), "Diagonal movement should be normalized to walk speed.", failures)
	_expect(player.facing == "south", "Equal diagonal input should resolve to vertical facing.", failures)
	player.apply_movement_intent(Vector2.LEFT)
	_expect(player.facing == "west", "Horizontal input should update facing.", failures)
	player.animation_time = 0.9
	_expect(player.current_animation_frame() == 9, "Lateral walking should use all ten animation frames.", failures)
	player.apply_movement_intent(Vector2.UP)
	player.animation_time = 0.9
	_expect(player.current_animation_frame() == 9, "Vertical walking should use all ten animation frames.", failures)
	player.apply_movement_intent(Vector2.ZERO)
	_expect(player.facing == "north", "Stopping should retain the last facing direction.", failures)
	player.velocity = Vector2.ZERO
	_expect(player.current_animation_frame() == 0, "An idle player should hold the first frame.", failures)
	player.queue_free()


func _test_main_scene_and_collision(failures: Array[String]) -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game_root: Node = scene.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	var player: CharacterBody2D = game.player
	_expect(player != null, "Main scene should contain the physical player.", failures)
	var camera: Camera2D = player.get_node("Camera2D")
	_expect(camera.limit_right == 1600 and camera.limit_bottom == 960, "Camera should be constrained to the authored world.", failures)

	var water_cell := Vector2i.ZERO
	for candidate: Vector2i in game.water_cells:
		if not game.water_cells.has(candidate + Vector2i.LEFT): water_cell = candidate; break
	var water_left := float(water_cell.x * game.CELL_SIZE)
	player.position = Vector2(water_left - 12.0, water_cell.y * game.CELL_SIZE + 16.0)
	Input.action_press("move_right")
	for _index in range(6):
		await physics_frame
	Input.action_release("move_right")
	_expect(player.position.x <= water_left - 9.9, "Player should not cross into water collision.", failures)

	player.position = Vector2(12, 300)
	Input.action_press("move_left")
	for _index in range(6):
		await physics_frame
	Input.action_release("move_left")
	_expect(player.position.x >= 9.9, "Player should not leave the west world boundary.", failures)
	game_root.queue_free()
	await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
