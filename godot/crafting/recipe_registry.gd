class_name RecipeRegistry
extends RefCounted

const RecipeDefinitionType = preload("res://crafting/recipe_definition.gd")

var recipes_by_id: Dictionary = {}
var recipe_order: Array[String] = []
var errors: Array[String] = []


func load_from_path(path: String, item_registry: Variant) -> Error:
	recipes_by_id.clear()
	recipe_order.clear()
	errors.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Unable to open recipe definitions '%s'." % path)
		return FileAccess.get_open_error()
	var parser := JSON.new()
	var result := parser.parse(file.get_as_text())
	if result != OK:
		errors.append("Invalid recipe JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return result
	if typeof(parser.data) != TYPE_DICTIONARY or typeof(parser.data.get("recipes")) != TYPE_ARRAY:
		errors.append("Recipe definition root must contain a 'recipes' array.")
		return ERR_INVALID_DATA
	for index in range(parser.data.recipes.size()):
		var value: Variant = parser.data.recipes[index]
		if typeof(value) != TYPE_DICTIONARY:
			errors.append("Recipe at index %d must be an object." % index)
			return ERR_INVALID_DATA
		var recipe: Variant = _parse_recipe(value, index, item_registry)
		if recipe == null:
			return ERR_INVALID_DATA
		recipes_by_id[recipe.recipe_id] = recipe
		recipe_order.append(recipe.recipe_id)
	return OK


func get_recipe(recipe_id: String) -> Variant:
	return recipes_by_id.get(recipe_id)


func _parse_recipe(data: Dictionary, index: int, item_registry: Variant) -> Variant:
	var recipe_id := str(data.get("id", ""))
	if recipe_id.is_empty() or recipes_by_id.has(recipe_id):
		errors.append("Recipe at index %d has an empty or duplicate ID '%s'." % [index, recipe_id])
		return null
	var inputs: Variant = _item_amounts(data.get("inputs"), recipe_id, "inputs", item_registry)
	var outputs: Variant = _item_amounts(data.get("outputs"), recipe_id, "outputs", item_registry)
	if inputs == null or outputs == null or inputs.is_empty() or outputs.is_empty():
		if inputs != null and outputs != null:
			errors.append("Recipe '%s' must contain inputs and outputs." % recipe_id)
		return null
	var recipe := RecipeDefinitionType.new()
	recipe.recipe_id = recipe_id
	recipe.label = str(data.get("label", recipe_id))
	recipe.inputs = inputs
	recipe.outputs = outputs
	return recipe


func _item_amounts(value: Variant, recipe_id: String, field_name: String, item_registry: Variant) -> Variant:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("Recipe '%s.%s' must be an object." % [recipe_id, field_name])
		return null
	var converted: Dictionary = {}
	for key: Variant in value:
		var item_id := str(key)
		var amount: Variant = value[key]
		var is_number := typeof(amount) == TYPE_INT or typeof(amount) == TYPE_FLOAT
		var is_positive_integer := is_number and float(amount) == float(int(amount)) and int(amount) > 0
		if item_registry.get_item(item_id) == null or not is_positive_integer:
			errors.append("Recipe '%s.%s.%s' must reference an item with a positive integer amount." % [recipe_id, field_name, item_id])
			return null
		converted[item_id] = int(amount)
	return converted
