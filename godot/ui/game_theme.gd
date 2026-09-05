class_name GameTheme
extends RefCounted

const REGULAR = preload("res://assets/fonts/AlegreyaSans-Regular.ttf")
const BOLD = preload("res://assets/fonts/AlegreyaSans-Bold.ttf")
const PIXEL = preload("res://assets/fonts/settlement_pixel_font.fnt")
const INK := Color("#30241d")
const CREAM := Color("#fff3d2")
const GOLD := Color("#d9ae54")
const BLUE := Color("#17637a")
const NIGHT := Color("#171b22")


static func create(palette: Dictionary = {}) -> Theme:
	var ink: Color = Color(str(palette.get("ink", INK.to_html())))
	var cream: Color = Color(str(palette.get("text", CREAM.to_html())))
	var gold: Color = Color(str(palette.get("accent", GOLD.to_html())))
	var blue: Color = Color(str(palette.get("button", BLUE.to_html())))
	var night: Color = Color(str(palette.get("dark", NIGHT.to_html())))
	var result := Theme.new()
	# One visual language everywhere: the bitmap typeface is used for both
	# headings and body copy; hierarchy comes from size, not a second family.
	result.default_font = PIXEL
	result.default_font_size = 17
	result.set_font("font", "Button", PIXEL)
	result.set_font("font", "OptionButton", PIXEL)
	result.set_font_size("font_size", "Button", 19)
	result.set_font_size("font_size", "OptionButton", 18)
	result.set_font("font", "LineEdit", PIXEL)
	result.set_color("font_color", "Button", cream)
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_pressed_color", "Button", Color.WHITE)
	result.set_color("font_color", "LineEdit", ink)
	result.set_color("font_placeholder_color", "LineEdit", Color(0.3, 0.24, 0.2, 0.55))
	result.set_color("font_color", "OptionButton", cream)
	result.set_stylebox("normal", "Button", _box(blue, blue.darkened(0.35), 2, 7))
	result.set_stylebox("hover", "Button", _box(blue.lightened(0.12), gold, 2, 7))
	result.set_stylebox("pressed", "Button", _box(Color("#114d60"), Color("#ffe09a"), 2, 7))
	result.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), Color("#ffe09a"), 2, 7))
	result.set_stylebox("normal", "OptionButton", _box(blue, blue.darkened(0.35), 2, 6))
	result.set_stylebox("hover", "OptionButton", _box(blue.lightened(0.12), gold, 2, 6))
	result.set_stylebox("normal", "LineEdit", _box(Color("#f8e7bc"), Color("#8e6a32"), 2, 5))
	result.set_stylebox("focus", "LineEdit", _box(Color("#fff4d6"), BLUE, 2, 5))
	result.set_stylebox("panel", "PopupMenu", _box(night, gold, 2, 5))
	result.set_color("font_color", "PopupMenu", cream)
	result.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	return result


static func decorate_panel(panel: Control, dark: bool = false) -> void:
	var frame := ReferenceRect.new()
	frame.name = "OrnamentalFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.border_color = GOLD if dark else Color("#805d2b")
	frame.border_width = 3.0
	frame.editor_only = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(frame)
	panel.move_child(frame, 0)


static func emphasize_headings(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if label.get_theme_font_size("font_size") >= 23:
			label.add_theme_font_override("font", PIXEL)
	for child: Node in node.get_children(): emphasize_headings(child)


static func _box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 7
	box.content_margin_bottom = 7
	return box
