extends RefCounted
## Shared controller setup for menus (G5.8, E5.4). Pulled from game-standards/common. Never edit it in a game (G10.3).
## Godot 4.6 gives its menu actions the D-pad and the left stick, but no controller button to choose or go back.
## Call this once at startup so the Xbox A button presses the focused button in every menu, the same as Enter,
## and B sends ui_cancel, the same as Escape:
##   const InputSetup := preload("res://addons/bc_common/input_setup.gd")
##   func _ready() -> void: InputSetup.add_controller_ui()
## Safe to call more than once. Other controllers that the browser or Android sees as standard use the same buttons.

static func add_controller_ui() -> void:
	_add("ui_accept", JOY_BUTTON_A)
	_add("ui_cancel", JOY_BUTTON_B)

static func _add(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action): return
	for e: InputEvent in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button: return
	var j := InputEventJoypadButton.new()
	j.button_index = button
	j.device = -1   # every connected controller
	InputMap.action_add_event(action, j)
