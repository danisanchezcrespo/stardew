extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	var scene: PackedScene = load("res://main.tscn")
	var lab: Node = scene.instantiate()
	root.add_child(lab)
	await process_frame

	_expect(lab.world != null, "Debug lab should create a physical world.", failures)
	_expect(lab.blueprints.size() == 3, "Debug lab should expose three footprint shapes.", failures)
	var initial_cell: Vector2i = lab.cursor_cell
	_expect(lab.place_selected(), "Default crate should place on sand.", failures)
	_expect(not lab.place_selected(), "Second object should not overlap the first.", failures)
	_expect(lab.remove_at_cursor(), "Placed object should be removable.", failures)
	lab.select_blueprint(1)
	lab.rotate_selected()
	_expect(lab.blueprint_rotation == 1, "Selected blueprint should rotate.", failures)
	lab.move_cursor(Vector2i(12, 0))
	_expect(lab.cursor_cell != initial_cell, "Cursor should move through an input intent.", failures)
	_expect(not lab.place_selected(), "Sand-only blueprint should be rejected on water.", failures)

	lab.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: world debug scene")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
