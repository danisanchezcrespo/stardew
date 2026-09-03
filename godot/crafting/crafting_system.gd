class_name CraftingSystem
extends RefCounted

const OK := "OK"
const UNKNOWN_RECIPE := "UNKNOWN_RECIPE"
const MISSING_INGREDIENTS := "MISSING_INGREDIENTS"
const OUTPUT_FULL := "OUTPUT_FULL"

var registry: Variant


func _init(recipe_registry: Variant) -> void:
	registry = recipe_registry


func query(inventory: Variant, recipe_id: String) -> Dictionary:
	var recipe: Variant = registry.get_recipe(recipe_id)
	if recipe == null:
		return {"valid": false, "reason": UNKNOWN_RECIPE, "missing": {}}
	var missing: Dictionary = {}
	for item_id: String in recipe.inputs:
		var absent := maxi(0, int(recipe.inputs[item_id]) - inventory.count(item_id))
		if absent > 0:
			missing[item_id] = absent
	if not missing.is_empty():
		return {"valid": false, "reason": MISSING_INGREDIENTS, "missing": missing}
	for item_id: String in recipe.outputs:
		if inventory.capacity_for(item_id) < int(recipe.outputs[item_id]):
			return {"valid": false, "reason": OUTPUT_FULL, "missing": {}}
	return {"valid": true, "reason": OK, "missing": {}}


func craft(inventory: Variant, recipe_id: String) -> Dictionary:
	var result := query(inventory, recipe_id)
	if not result.valid:
		return result
	var recipe: Variant = registry.get_recipe(recipe_id)
	for item_id: String in recipe.inputs:
		inventory.remove(item_id, int(recipe.inputs[item_id]))
	for item_id: String in recipe.outputs:
		var accepted: int = inventory.add(item_id, int(recipe.outputs[item_id]))
		assert(accepted == int(recipe.outputs[item_id]), "Validated crafting output must fit.")
	return result
