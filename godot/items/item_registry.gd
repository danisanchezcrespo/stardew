class_name ItemRegistry
extends RefCounted

const ItemDefinitionType = preload("res://items/item_definition.gd")

var items_by_id: Dictionary = {}
var item_order: Array[String] = []
var errors: Array[String] = []


func load_from_path(path: String) -> Error:
	items_by_id.clear()
	item_order.clear()
	errors.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Unable to open item definitions '%s'." % path)
		return FileAccess.get_open_error()
	var parser := JSON.new()
	var result := parser.parse(file.get_as_text())
	if result != OK:
		errors.append("Invalid item JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return result
	if typeof(parser.data) != TYPE_DICTIONARY or typeof(parser.data.get("items")) != TYPE_ARRAY:
		errors.append("Item definition root must contain an 'items' array.")
		return ERR_INVALID_DATA
	for index in range(parser.data.items.size()):
		var data: Variant = parser.data.items[index]
		if typeof(data) != TYPE_DICTIONARY:
			errors.append("Item at index %d must be an object." % index)
			return ERR_INVALID_DATA
		var definition: Variant = _parse_item(data, index)
		if definition == null:
			return ERR_INVALID_DATA
		items_by_id[definition.item_id] = definition
		item_order.append(definition.item_id)
	return OK


func get_item(item_id: String) -> Variant:
	return items_by_id.get(item_id)


func _parse_item(data: Dictionary, index: int) -> Variant:
	var item_id := str(data.get("id", ""))
	if item_id.is_empty() or items_by_id.has(item_id):
		errors.append("Item at index %d has an empty or duplicate ID '%s'." % [index, item_id])
		return null
	var max_stack := int(data.get("max_stack", 99))
	if max_stack <= 0:
		errors.append("Item '%s' must have a positive max_stack." % item_id)
		return null
	var color_value := str(data.get("color", "#ffffff"))
	if not Color.html_is_valid(color_value):
		errors.append("Item '%s' has invalid color '%s'." % [item_id, color_value])
		return null
	var definition := ItemDefinitionType.new()
	definition.item_id = item_id
	definition.label = str(data.get("label", item_id))
	definition.color = Color(color_value)
	definition.max_stack = max_stack
	definition.placeable_entity_id = str(data.get("placeable_entity_id", ""))
	return definition
