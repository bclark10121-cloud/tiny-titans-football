extends SceneTree
# Screens check (G5.8): team screen Players choice, Menu, How to play, B to go back and Play again, with controller buttons only. Run: godot --headless --path . -s res://tests/screens_check.gd

var main: Node
var out: PackedStringArray = PackedStringArray()
var fails: int = 0

func _press(b: int, hold: float = 0.08) -> void:
	for down: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = b as JoyButton
		e.pressed = down
		Input.parse_input_event(e)
		await create_timer(hold if down else 0.06).timeout

func _check(ok: bool, what: String) -> void:
	out.append(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func _focus_text() -> String:
	var f: Control = root.gui_get_focus_owner()
	return (f as Button).text if f is Button else ""

func _initialize() -> void:
	main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	_run.call_deferred()

func _run() -> void:
	var hud: Node = main.get("hud")
	await create_timer(0.8).timeout
	await _press(JOY_BUTTON_A)
	await create_timer(0.4).timeout
	_check(int(main.get("state")) == 1, "title: A opens the team screen")
	# team screen: move with the D-pad to 11 on 11, choose it with A, then back to 7 on 7
	var found: bool = false
	for i: int in 16:
		if _focus_text() == "11 on 11":
			found = true
			break
		await _press(JOY_BUTTON_DPAD_RIGHT if _focus_text() == "7 on 7" else JOY_BUTTON_DPAD_DOWN)
	_check(found, "team screen: D-pad reaches the Players choice")
	await _press(JOY_BUTTON_A)
	await create_timer(0.2).timeout
	_check(int((main.get("save") as Dictionary).mode) == 11, "team screen: A picks 11 on 11")
	await _press(JOY_BUTTON_DPAD_LEFT)
	await _press(JOY_BUTTON_A)
	await create_timer(0.2).timeout
	_check(int((main.get("save") as Dictionary).mode) == 7, "team screen: A picks 7 on 7")
	# start a game, then the Menu row: Resume, How to play, ...
	main.call("start_game", 0, true, 1)
	await create_timer(0.6).timeout
	await _press(JOY_BUTTON_START)
	await create_timer(0.3).timeout
	_check(bool(hud.get("menu_open")), "Menu button opens the Menu")
	await _press(JOY_BUTTON_DPAD_RIGHT)
	var help_name: String = _focus_text()
	await _press(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	_check(bool((hud.get("help_panel") as Control).visible), "Menu row: D-pad to %s, A opens it" % help_name)
	await _press(JOY_BUTTON_B)
	await create_timer(0.3).timeout
	_check(not (hud.get("help_panel") as Control).visible, "How to play: B goes back")
	await _press(JOY_BUTTON_B)
	await create_timer(0.3).timeout
	_check(not bool(hud.get("menu_open")), "Menu: B closes it")
	await _press(JOY_BUTTON_BACK)
	await create_timer(0.3).timeout
	_check(bool(hud.get("menu_open")), "View button opens the Menu")
	await _press(JOY_BUTTON_BACK)
	await create_timer(0.3).timeout
	# end of the game: Play again with A
	main.call("start_game", 0, false, 1)
	await create_timer(0.4).timeout
	main.call("_game_over")
	await create_timer(0.5).timeout
	var over_txt: String = _focus_text()
	_check(int(main.get("state")) == 7 and over_txt == "Play again", "end of game: Play again is highlighted")
	await _press(JOY_BUTTON_A)
	await create_timer(0.5).timeout
	_check(int(main.get("state")) != 7, "end of game: A plays again (state %d)" % int(main.get("state")))
	for l: String in out:
		print(l)
	print("SCREENS check %s" % ("ok" if fails == 0 else "FAIL"))
	quit()
