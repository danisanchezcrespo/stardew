extends SceneTree

const ItemRegistryType = preload("res://items/item_registry.gd")
const PlayerInventoryType = preload("res://player/player_inventory.gd")
const PickupType = preload("res://world/items/world_pickup.gd")
const TargetingType = preload("res://world/interaction/interaction_targeting.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var registry := ItemRegistryType.new()
	var result: Error = registry.load_from_path("res://items/items.json")
	_expect(result == OK, "Item definitions should load: %s" % str(registry.errors), failures)
	_test_inventory_capacity(registry, failures)
	_test_target_selection(registry, failures)
	await _test_gameplay_pickup(failures)

	if failures.is_empty():
		print("PASS: pickup and inventory")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_inventory_capacity(registry: Variant, failures: Array[String]) -> void:
	var inventory := PlayerInventoryType.new(registry, 2)
	_expect(inventory.add("wood", 70) == 70, "Inventory should split items across stacks.", failures)
	_expect(inventory.slots[0].amount == 50 and inventory.slots[1].amount == 20, "Wood should respect its 50 item stack limit.", failures)
	_expect(inventory.add("wood", 40) == 30, "Inventory should accept only remaining capacity.", failures)
	_expect(inventory.count("wood") == 100, "Inventory count should sum every stack.", failures)
	_expect(inventory.add("clay", 1) == 0, "Full inventory should reject another item without mutation.", failures)
	_expect(inventory.remove("wood", 55) == 55 and inventory.count("wood") == 45, "Removal should consume across stacks.", failures)
	_expect(inventory.add("missing", 5) == 0, "Unknown items should be rejected.", failures)


func _test_target_selection(registry: Variant, failures: Array[String]) -> void:
	var definition: Variant = registry.get_item("wood")
	var behind := PickupType.new()
	behind.position = Vector2(-5, 0)
	behind.configure("z-behind", definition, 1)
	var front_b := PickupType.new()
	front_b.position = Vector2(10, 0)
	front_b.configure("b-front", definition, 1)
	var front_a := PickupType.new()
	front_a.position = Vector2(10, 0)
	front_a.configure("a-front", definition, 1)
	var candidates: Array = [behind, front_b, front_a]
	var selected: Variant = TargetingType.select_target(Vector2.ZERO, "east", candidates, 40.0)
	_expect(selected == front_a, "Facing preference, distance and stable ID should select deterministically.", failures)
	selected = TargetingType.select_target(Vector2.ZERO, "west", candidates, 40.0)
	_expect(selected == behind, "Changing facing should change the preferred half-plane.", failures)
	behind.free()
	front_b.free()
	front_a.free()


func _test_gameplay_pickup(failures: Array[String]) -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game_root: Node = scene.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	_expect(game.pickups[0].z_index > 0 and game.pickups[0].z_index < game.player.z_index, "Pickup sprites should render above terrain and behind the player.", failures)
	_expect(game.resource_sources[0].z_index > 0 and game.resource_sources[0].z_index < game.player.z_index, "Renewable resource sprites should render above terrain and behind the player.", failures)
	game._update_interaction_target()
	_expect(game.interaction_target != null and game.interaction_target.item_id == "wood", "Nearby wood should become the contextual target.", failures)
	_expect(game.interaction_label.text.contains("Space = Pick up"), "Pickup hover should show the Space control.", failures)
	_expect(game.interaction_target.ItemIconAtlasType.CELLS.has("wood"), "Pickups should use the shared item sprite atlas.", failures)
	_expect(game.inventory_icons.size() == 8 and game.inventory_slot_labels.size() == 8, "Every visible quick slot should align an item icon and label.", failures)
	_expect(game.crafting_recipe_buttons[0].icon != null, "Crafting recipes should expose their output sprite.", failures)
	var pickup_action := InputEventAction.new()
	pickup_action.action = "use_selected"
	pickup_action.pressed = true
	game._unhandled_input(pickup_action)
	_expect(game.inventory.count("wood") == 18, "Collected wood should enter player inventory.", failures)
	_expect(game.interaction_target == null, "Exhausted pickup should clear the target.", failures)

	game.inventory = PlayerInventoryType.new(game.item_registry, 1)
	game.inventory.add("wood", 45)
	var remainder_pickup: Variant = game._spawn_pickup("pickup-partial", "wood", 10, game.player.position)
	game._update_interaction_target()
	var collected: int = game.collect_target()
	_expect(collected == 5 and game.inventory.count("wood") == 50, "Pickup should accept only available inventory capacity.", failures)
	_expect(remainder_pickup.amount == 5 and is_instance_valid(remainder_pickup), "Unaccepted pickup remainder should stay in the world.", failures)
	game_root.queue_free()
	await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
