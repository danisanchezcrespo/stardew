extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var scene: PackedScene = load("res://main.tscn")
	var game_root: Node = scene.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	_expect(game.resource_sources.size() >= 2, "Each physical map should include configured renewable sources.", failures)
	var source: Variant = game.resource_sources[0]
	var before: int = source.current_amount
	var collected: int = game.collect_resource_source(source)
	_expect(collected == mini(source.grant_amount, before), "A source should grant its configured amount per visit.", failures)
	_expect(source.current_amount == before - collected, "Gathering should consume the renewable reserve.", failures)
	source.current_amount = source.max_amount - source.regen_amount
	source.regen_elapsed = 0.0
	source.process_source(source.regen_seconds)
	_expect(source.current_amount == source.max_amount, "A configured regeneration interval should replenish up to MAX.", failures)
	source.process_source(source.regen_seconds * 3.0)
	_expect(source.current_amount == source.max_amount, "Renewable sources must never exceed MAX.", failures)
	var snapshot: Dictionary = game.physical_save.capture(game)
	_expect(snapshot.resource_sources.has(source.stable_id), "Save data should persist renewable reserves and timers.", failures)
	game_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: renewable resource sources")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
