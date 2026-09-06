extends SceneTree

const LivingType = preload("res://world/progression/living_timeline.gd")
const InventoryType = preload("res://player/player_inventory.gd")
const RegistryType = preload("res://items/item_registry.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var living := LivingType.new(); living.configure("medieval", 1)
	_expect(living.enabled and living.weather == "Clear" and not living.current_request.is_empty(), "Medieval day one should initialize its living timeline.", failures)
	_expect(living.spend_energy(25.0) and living.player_energy == 75.0, "Manual actions should consume daily energy.", failures)
	_expect(not living.spend_energy(80.0), "An exhausted player should not overspend energy.", failures)
	var registry := RegistryType.new(); registry.load_from_path("res://scenarios/medieval/items.json")
	var inventory := InventoryType.new(registry, 8)
	var requested_item := str(living.current_request.item); inventory.add(requested_item, int(living.current_request.amount))
	var result: Dictionary = living.try_complete_request(inventory)
	_expect(not result.is_empty() and living.community > 0 and not living.friendship.is_empty(), "Optional requests should reward relationships and settlement identity.", failures)
	living.begin_day(8); inventory.add("loaf", 8); living.contribute_feast(inventory); living.contribute_feast(inventory)
	_expect(living.feast_food >= 8 and living.day_story(8).contains("abundance"), "Feast preparation should affect the authored Day 8 outcome.", failures)
	living.begin_day(6); inventory.add("coin", 2)
	var purchase: Dictionary = living.buy_merchant_offer(6, inventory)
	_expect(str(purchase.get("item", "")) == "village_lantern" and inventory.count("village_lantern") == 1, "The Day 6 merchant should sell an optional placeable decoration.", failures)
	_expect(living.discover("ruin_fragment").contains("portal") and living.discover("ruin_fragment").is_empty(), "Northern ruin lore should be discovered once and remain persistent.", failures)
	var restored := LivingType.new(); restored.configure("medieval", 1); restored.restore(living.snapshot())
	_expect(restored.feast_food == living.feast_food and restored.community == living.community, "Living timeline state should survive save/load.", failures)
	if failures.is_empty(): print("PASS: living timeline"); quit(0); return
	for failure: String in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
