class_name InputDefaults
extends RefCounted

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_ENTER],
	"use_selected": [KEY_SPACE],
	"rotate_blueprint": [KEY_R],
	"remove_placed": [KEY_X, KEY_DELETE],
	"select_previous": [KEY_Q],
	"select_next": [KEY_F],
	"open_crafting": [KEY_C],
	"cancel": [KEY_ESCAPE],
	"menu_up": [KEY_W, KEY_UP],
	"menu_down": [KEY_S, KEY_DOWN],
	"quick_previous": [KEY_Q],
	"quick_next": [KEY_F],
	# Function keys are reserved by the Godot editor while testing the game.
	"save_game": [KEY_K],
	"load_game": [KEY_L],
}


static func ensure_actions() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for keycode: Key in ACTIONS[action]:
				var event := InputEventKey.new()
				event.physical_keycode = keycode
				InputMap.action_add_event(action, event)
	_add_joypad_button("interact", JOY_BUTTON_A)
	_add_joypad_button("use_selected", JOY_BUTTON_X)
	_add_joypad_button("rotate_blueprint", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joypad_button("remove_placed", JOY_BUTTON_X)
	_add_joypad_button("select_previous", JOY_BUTTON_LEFT_SHOULDER)
	_add_joypad_button("select_next", JOY_BUTTON_Y)
	_add_joypad_button("open_crafting", JOY_BUTTON_Y)
	_add_joypad_button("cancel", JOY_BUTTON_B)
	_add_joypad_button("menu_up", JOY_BUTTON_DPAD_UP)
	_add_joypad_button("menu_down", JOY_BUTTON_DPAD_DOWN)
	_add_joypad_button("quick_previous", JOY_BUTTON_LEFT_SHOULDER)
	_add_joypad_button("quick_next", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joypad_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joypad_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joypad_button("move_up", JOY_BUTTON_DPAD_UP)
	_add_joypad_button("move_down", JOY_BUTTON_DPAD_DOWN)
	_add_joypad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joypad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joypad_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joypad_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_mouse_button("use_selected", MOUSE_BUTTON_LEFT)
	for index in range(8):
		var action := "quick_slot_%d" % (index + 1)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var event := InputEventKey.new()
			event.keycode = KEY_1 + index
			InputMap.action_add_event(action, event)


static func _add_joypad_button(action: String, button: JoyButton) -> void:
	for existing: InputEvent in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and existing.button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


static func _add_joypad_axis(action: String, axis: JoyAxis, value: float) -> void:
	for existing: InputEvent in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion and existing.axis == axis and existing.axis_value == value:
			return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)


static func _add_mouse_button(action: String, button: MouseButton) -> void:
	for existing: InputEvent in InputMap.action_get_events(action):
		if existing is InputEventMouseButton and existing.button_index == button:
			return
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
