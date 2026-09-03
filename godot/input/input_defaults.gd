class_name InputDefaults
extends RefCounted

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	"rotate_blueprint": [KEY_R],
	"remove_placed": [KEY_X, KEY_DELETE],
	"select_previous": [KEY_Q],
	"select_next": [KEY_F],
	"open_crafting": [KEY_C],
	"cancel": [KEY_ESCAPE],
	"menu_up": [KEY_W, KEY_UP],
	"menu_down": [KEY_S, KEY_DOWN],
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
	_add_joypad_button("rotate_blueprint", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joypad_button("remove_placed", JOY_BUTTON_X)
	_add_joypad_button("select_previous", JOY_BUTTON_LEFT_SHOULDER)
	_add_joypad_button("select_next", JOY_BUTTON_Y)
	_add_joypad_button("open_crafting", JOY_BUTTON_Y)
	_add_joypad_button("cancel", JOY_BUTTON_B)
	_add_joypad_button("menu_up", JOY_BUTTON_DPAD_UP)
	_add_joypad_button("menu_down", JOY_BUTTON_DPAD_DOWN)
	_add_joypad_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joypad_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joypad_button("move_up", JOY_BUTTON_DPAD_UP)
	_add_joypad_button("move_down", JOY_BUTTON_DPAD_DOWN)
	_add_joypad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joypad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joypad_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joypad_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)


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
