extends SceneTree

const ItemRegistryType = preload("res://items/item_registry.gd")
const RecipeRegistryType = preload("res://crafting/recipe_registry.gd")
const CraftingSystemType = preload("res://crafting/crafting_system.gd")
const PlayerInventoryType = preload("res://player/player_inventory.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var items := ItemRegistryType.new()
	var result: Error = items.load_from_path("res://items/items.json")
	_expect(result == OK, "Item definitions must load for crafting.", failures)
	var recipes := RecipeRegistryType.new()
	result = recipes.load_from_path("res://crafting/recipes.json", items)
	_expect(result == OK, "Recipe definitions should load: %s" % str(recipes.errors), failures)
	_test_transactional_crafting(items, recipes, failures)
	_test_output_capacity(items, recipes, failures)
	await _test_crafting_scene(failures)

	if failures.is_empty():
		print("PASS: crafting")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_transactional_crafting(items: Variant, recipes: Variant, failures: Array[String]) -> void:
	var inventory := PlayerInventoryType.new(items, 3)
	var system := CraftingSystemType.new(recipes)
	var missing: Dictionary = system.craft(inventory, "storage_crate")
	_expect(not missing.valid and missing.reason == CraftingSystemType.MISSING_INGREDIENTS, "Unavailable recipe should report missing ingredients.", failures)
	_expect(inventory.count("wood") == 0 and inventory.count("storage_crate") == 0, "Failed craft must not mutate inventory.", failures)
	inventory.add("wood", 18)
	var crafted: Dictionary = system.craft(inventory, "storage_crate")
	_expect(crafted.valid, "Recipe should craft when ingredients and output space exist.", failures)
	_expect(inventory.count("wood") == 8 and inventory.count("storage_crate") == 1, "Craft should atomically exchange inputs for outputs.", failures)


func _test_output_capacity(items: Variant, recipes: Variant, failures: Array[String]) -> void:
	var inventory := PlayerInventoryType.new(items, 2)
	inventory.add("wood", 10)
	inventory.add("storage_crate", 10)
	var system := CraftingSystemType.new(recipes)
	var result: Dictionary = system.craft(inventory, "storage_crate")
	_expect(not result.valid and result.reason == CraftingSystemType.OUTPUT_FULL, "Full output stack should block crafting.", failures)
	_expect(inventory.count("wood") == 10 and inventory.count("storage_crate") == 10, "Blocked output must preserve ingredients.", failures)


func _test_crafting_scene(failures: Array[String]) -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game_root: Node = scene.instantiate()
	root.add_child(game_root)
	await process_frame
	var game: Node2D = game_root.get_node("MainGame")
	game.inventory.add("wood", 10)
	game.set_crafting_open(true)
	_expect(game.crafting_open and not game.player.movement_enabled and game.crafting_panel.visible, "Opening crafting should show the submenu and stop player movement.", failures)
	_expect(game.crafting_recipe_buttons.size() == game.recipe_registry.recipe_order.size(), "Crafting should expose one clickable button per recipe.", failures)
	_expect(game.crafting_resource_icons[0].visible and game.crafting_resource_icons[0].texture != null, "Crafting ingredients should display their resource icons.", failures)
	_expect(game.crafting_recipe_buttons[0].get_theme_color("font_color") == Color("#fffaf0"), "Craftable recipes should appear bright white.", failures)
	_expect(game.crafting_recipe_buttons[1].get_theme_color("font_color") == Color("#777777"), "Unavailable recipes should appear grey.", failures)
	game.crafting_recipe_buttons[1].mouse_entered.emit()
	_expect(game.selected_recipe_index == 1, "Hovering a recipe should preview it without crafting.", failures)
	_expect(game.crafting_detail_label.text.contains("#d83232") and game.crafting_detail_label.text.contains("Clay: 0 / 2"), "Missing hovered ingredients should appear red in the detail panel.", failures)
	game.crafting_recipe_buttons[0].mouse_entered.emit()
	_expect(game.crafting_panel.color == Color("#d8bd83"), "Crafting should use a readable parchment panel instead of an opaque black screen.", failures)
	var interact_key := InputEventKey.new()
	interact_key.physical_keycode = KEY_E
	interact_key.pressed = true
	game._unhandled_input(interact_key)
	_expect(game.inventory.count("wood") == 10, "E should not craft while the crafting panel is open.", failures)
	var space_key := InputEventKey.new()
	space_key.physical_keycode = KEY_SPACE
	space_key.pressed = true
	game._unhandled_input(space_key)
	_expect(game.inventory.count("storage_crate") == 1, "Space should craft the selected recipe.", failures)
	_expect(game.inventory.count("wood") == 0 and game.inventory.count("storage_crate") == 1, "Scene crafting should update the shared player inventory.", failures)
	game.select_recipe(1)
	var before: Array[Dictionary] = game.inventory.snapshot()
	_expect(not game.craft_selected_recipe(), "Unavailable mud brick recipe should fail.", failures)
	_expect(game.inventory.snapshot() == before, "Failed scene craft should not change slots.", failures)
	game.set_crafting_open(false)
	_expect(game.player.movement_enabled and not game.crafting_panel.visible, "Closing crafting should restore movement.", failures)
	game_root.queue_free()
	await process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
