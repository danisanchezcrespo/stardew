extends SceneTree

const ProgressionType = preload("res://world/progression/settlement_progression.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	for scenario_id: String in ["ancient_egypt", "prehistory", "medieval", "mars_colony"]:
		var progression := ProgressionType.new()
		_expect(progression.load_catalog("res://world/progression/progression_catalog.json", scenario_id) == OK, "%s should have progression data." % scenario_id, failures)
		_expect(not progression.tech_nodes().is_empty(), "%s should have a technology tree." % scenario_id, failures)
		_expect(not progression.collection_items().is_empty(), "%s should have a collection." % scenario_id, failures)
		var root: Dictionary = progression.tech_nodes()[0]
		_expect(progression.unlock(str(root.id)), "%s root technology should unlock for free." % scenario_id, failures)
		for recipe_id: Variant in root.get("recipes", []): _expect(progression.recipe_unlocked(str(recipe_id)), "Root recipe should become available.", failures)
		if progression.tech_nodes().size() > 1:
			var next_layer: Dictionary = progression.tech_nodes()[1]
			progression.research_points = 100
			_expect(not progression.can_unlock(str(next_layer.id)), "%s next knowledge layer should wait for its object discoveries." % scenario_id, failures)
			for required_item: Variant in next_layer.get("discover", []): progression.discover(str(required_item))
			_expect(progression.can_unlock(str(next_layer.id)), "%s next knowledge layer should become available after automatic discoveries." % scenario_id, failures)
		var collection_entry: Dictionary = {}
		for candidate: Dictionary in progression.collection_items():
			if not progression.donated_items.has(str(candidate.item)): collection_entry = candidate; break
		_expect(not collection_entry.is_empty(), "%s should retain another discoverable catalog object." % scenario_id, failures)
		var points_before: int = progression.research_points
		_expect(progression.discover(str(collection_entry.item)), "A newly obtained catalog item should be recorded automatically.", failures)
		_expect(not progression.discover(str(collection_entry.item)), "A catalog discovery must not be recorded twice.", failures)
		_expect(progression.research_points > points_before, "A first discovery should award knowledge.", failures)
		for unused in range(ProgressionType.DAYS_PER_SEASON): progression.advance_day()
		_expect(progression.season_index == 1 and progression.day == 1, "Calendar should advance season after four seven-day weeks.", failures)
		progression.upgrade_building("test-building")
		var copy := ProgressionType.new(); copy.load_catalog("res://world/progression/progression_catalog.json", scenario_id); copy.restore(progression.snapshot())
		_expect(copy.building_level("test-building") == 2 and copy.donated_items.has(str(collection_entry.item)), "Progression should round-trip.", failures)
	if failures.is_empty(): print("PASS: settlement progression"); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
