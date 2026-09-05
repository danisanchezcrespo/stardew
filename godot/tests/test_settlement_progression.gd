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
		var collection_entry: Dictionary = progression.collection_items()[0]
		var points_before: int = progression.research_points
		_expect(progression.donate(str(collection_entry.item)), "A catalog item should be donatable once.", failures)
		_expect(not progression.donate(str(collection_entry.item)), "A catalog item must not be donated twice.", failures)
		_expect(progression.research_points > points_before, "Donation should award knowledge.", failures)
		for unused in range(ProgressionType.DAYS_PER_SEASON): progression.advance_day()
		_expect(progression.season_index == 1 and progression.day == 1, "Calendar should advance season after eight days.", failures)
		progression.upgrade_building("test-building")
		var copy := ProgressionType.new(); copy.load_catalog("res://world/progression/progression_catalog.json", scenario_id); copy.restore(progression.snapshot())
		_expect(copy.building_level("test-building") == 2 and copy.donated_items.has(str(collection_entry.item)), "Progression should round-trip.", failures)
	if failures.is_empty(): print("PASS: settlement progression"); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
