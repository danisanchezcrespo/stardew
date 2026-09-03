class_name WorldOverlay
extends Node2D

const ItemIconAtlasType = preload("res://items/item_icon_atlas.gd")
var game: Node2D

func configure(owner_game: Node2D) -> void:
	game = owner_game
	z_index = 1000
	z_as_relative = false

func _draw() -> void:
	if game == null or game.player == null: return
	if game.placement_mode:
		var definition: Variant = game._selected_placeable_definition()
		if definition != null:
			var item: Variant = game.item_registry.get_item(game.inventory.slots[game.selected_slot].item_id)
			_draw_hint(Vector2(game.placement_cursor * game.CELL_SIZE) + Vector2(16, -22), [item.label, "Space to place"])
		return
	var target: Variant = game.interaction_target
	if target == null: return
	var anchor: Vector2 = target.global_position + Vector2(0, -34)
	if target.target_kind == "pickup":
		_draw_hint(anchor, ["%s x%d" % [target.item_label, target.amount], "Space to pick up"])
	elif target.target_kind == "construction":
		_draw_construction(anchor, target)
	elif target.target_kind == "storage":
		_draw_hint(anchor, [target.item_label, "Space to open", "Click for details"])
	elif target.target_kind == "machine":
		var machine: Variant = game.machines_by_entity_id.get(target.stable_id)
		var state := "Broken" if machine != null and machine.broken else ("Working %d%%" % roundi(machine.progress() * 100.0) if machine != null and machine.is_running() else "Ready")
		_draw_hint(anchor, [target.item_label, state, "Space to open · Click for details"])
	else:
		_draw_hint(anchor, [target.item_label, "Click for details"])

func _draw_construction(anchor: Vector2, target: Variant) -> void:
	var site: Variant = game.construction_by_entity_id.get(target.stable_id)
	if site == null: return
	if not site.materials_complete():
		var needs: Array[Dictionary] = []
		for item_id: String in site.requirements:
			var remaining: int = site.receivable(item_id)
			if remaining > 0: needs.append({"item": item_id, "amount": remaining})
		_draw_requirement_hint(anchor, target.item_label, needs)
		return
	_draw_progress_hint(anchor, site.work_progress())

func _draw_hint(anchor: Vector2, lines: Array[String]) -> void:
	var font := ThemeDB.fallback_font
	var width := 0.0
	for line: String in lines: width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x)
	var size := Vector2(width + 18, lines.size() * 16 + 10)
	var rect := Rect2(anchor - Vector2(size.x * 0.5, size.y), size)
	_panel(rect)
	for index in range(lines.size()): draw_string(font, rect.position + Vector2(9, 17 + index * 16), lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _draw_requirement_hint(anchor: Vector2, title: String, needs: Array[Dictionary]) -> void:
	var width := 190.0
	var height := 58.0 + needs.size() * 28.0
	var rect := Rect2(anchor - Vector2(width * 0.5, height), Vector2(width, height))
	_panel(rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 17), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 33), "Needs", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f0cc72"))
	for index in range(needs.size()):
		var row: Dictionary = needs[index]
		var pos := rect.position + Vector2(12, 38 + index * 28)
		draw_texture_rect_region(ItemIconAtlasType.TEXTURE, Rect2(pos, Vector2(22, 22)), ItemIconAtlasType.region(str(row.item)))
		var definition: Variant = game.item_registry.get_item(str(row.item))
		draw_string(ThemeDB.fallback_font, pos + Vector2(29, 16), "%s  x%d" % [definition.label, int(row.amount)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, height - 8), "Space to open", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

func _draw_progress_hint(anchor: Vector2, progress: float) -> void:
	var rect := Rect2(anchor - Vector2(85, 48), Vector2(170, 48))
	_panel(rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 17), "Space to build", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var bar := Rect2(rect.position + Vector2(9, 27), Vector2(152, 12))
	draw_rect(bar, Color("#2b211b"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(progress, 0.0, 1.0), bar.size.y)), Color("#e5b84b"))
	draw_rect(bar, Color.WHITE, false, 1.0)

func _panel(rect: Rect2) -> void:
	draw_rect(rect, Color(0.04, 0.035, 0.025, 0.94))
	draw_rect(rect, Color("#f0cc72"), false, 1.0)
