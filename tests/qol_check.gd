extends SceneTree
# v0.3.0 check (LT is the burst): Settings, season, Continue, Run it again, skip the wait, pause on focus loss, burst and quarter length.
# Menus are driven with controller buttons only (G5.8). Run: godot --headless --path . -s res://tests/qol_check.gd

var main: Node
var hud: Node
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

func _axis(a: int, hold: float = 0.1) -> void:
	for v: float in [1.0, 0.0]:
		var e := InputEventJoypadMotion.new()
		e.device = 0
		e.axis = a as JoyAxis
		e.axis_value = v
		Input.parse_input_event(e)
		await create_timer(hold if v > 0.0 else 0.06).timeout

func _key(k: int) -> void:
	for down: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k as Key
		e.physical_keycode = k as Key
		e.pressed = down
		Input.parse_input_event(e)
		await create_timer(0.08 if down else 0.06).timeout

func _check(ok: bool, what: String) -> void:
	out.append(("ok   " if ok else "FAIL ") + what + ("" if ok else "   [state %d focus '%s' panel '%s']" % [_st(), _focus_text(), String(hud.call("any_panel"))]))
	if not ok:
		fails += 1

func _focus_text() -> String:
	var f: Control = root.gui_get_focus_owner()
	return (f as Button).text if f is Button else ""

func _focus_to(txt: String, btn: int, tries: int = 8) -> bool:
	for i: int in tries:
		if _focus_text().begins_with(txt):
			return true
		await _press(btn)
	return _focus_text().begins_with(txt)

func _st() -> int:
	return int(main.get("state"))

func _save() -> Dictionary:
	return main.get("save") as Dictionary

func _initialize() -> void:
	main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	_run.call_deferred()

func _run() -> void:
	hud = main.get("hud")
	await create_timer(0.8).timeout
	# start clean: no saved game, no season, 2 minute quarters
	_save().season = ((main.get_script() as Script).get_script_constant_map()["SEASON0"] as Dictionary).duplicate(true)
	_save().qlen = 2
	main.call("_forget_game")
	main.call("goto_title")
	await create_timer(0.3).timeout
	_check(_focus_text() == "Exhibition" and not (hud.get("continue_btn") as Button).visible, "title: no Continue without a saved game, Exhibition has the focus")

	# Settings from the title with a controller
	var got: bool = await _focus_to("Settings", JOY_BUTTON_DPAD_RIGHT)
	await _press(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	_check(got and (hud.get("settings_panel") as Control).visible and _focus_text().begins_with("Music"), "title: D-pad to Settings, A opens it, Music has the focus")
	var music0: bool = bool(_save().music)
	await _press(JOY_BUTTON_A)
	await create_timer(0.2).timeout
	_check(bool(_save().music) != music0 and _focus_text() == ("Music: Off" if music0 else "Music: On"), "Settings: A switches Music and the label says so")
	await _press(JOY_BUTTON_A)
	var mode0: int = int(_save().mode)
	got = await _focus_to("Players", JOY_BUTTON_DPAD_DOWN)
	await _press(JOY_BUTTON_A)
	await create_timer(0.2).timeout
	_check(got and int(_save().mode) != mode0 and _focus_text().begins_with("Players: %d" % int(_save().mode)), "Settings: Players switches 7 on 7 and 11 on 11")
	await _press(JOY_BUTTON_A)
	got = await _focus_to("Quarter", JOY_BUTTON_DPAD_DOWN)
	await _press(JOY_BUTTON_A)
	await create_timer(0.2).timeout
	_check(got and int(_save().qlen) == 3 and _focus_text() == "Quarter length: 3 minutes", "Settings: Quarter length goes 2, 3, 1")
	await _press(JOY_BUTTON_A)
	await _press(JOY_BUTTON_A)
	_check(int(_save().qlen) == 2, "Settings: Quarter length back to 2")
	await _press(JOY_BUTTON_B)
	await create_timer(0.3).timeout
	_check(not (hud.get("settings_panel") as Control).visible and _st() == 0, "Settings: B goes back to the title")

	# team screen: B goes back
	await _focus_to("Exhibition", JOY_BUTTON_DPAD_LEFT)
	await _press(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	_check(_st() == 1, "title: A on Exhibition opens the team screen")
	await _press(JOY_BUTTON_B)
	await create_timer(0.3).timeout
	_check(_st() == 0, "team screen: B goes back to the title")

	# season with a controller: Season, pick a team, season screen, B, back in, play week 1
	got = await _focus_to("Season", JOY_BUTTON_DPAD_RIGHT)
	await _press(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	_check(got and _st() == 1 and bool(hud.get("team_season")), "title: A on Season opens the team screen for a season")
	await _press(JOY_BUTTON_A)
	await create_timer(0.4).timeout
	var se: Dictionary = _save().season
	_check(_st() == 8 and bool(se.on) and int(se.week) == 0 and _focus_text() == "Play week 1", "team screen: A starts a season, the season screen shows Play week 1")
	await _press(JOY_BUTTON_B)
	await create_timer(0.3).timeout
	_check(_st() == 0 and String((hud.get("season_btn") as Button).text) == "Season: week 1", "season screen: B goes to the title, which shows Season: week 1")
	await _focus_to("Season", JOY_BUTTON_DPAD_RIGHT)
	await _press(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	_check(_st() == 8, "title: Season opens the season in progress")
	var opp: int = int(main.call("_season_opp", 0))
	await _press(JOY_BUTTON_A)
	await create_timer(0.5).timeout
	var ti: Array = main.get("team_idx")
	_check(bool(main.get("season_game")) and int(ti[1]) == opp and _st() != 8, "season screen: A plays week 1 against the scheduled rival (%d)" % opp)
	_check(bool(_save().game.on) and String(_save().game.at) == "kick" and bool(_save().game.season), "Continue: the season game is saved at the kickoff")

	# Run it again, Continue and pause on focus loss, from a play call with the ball
	main.set("poss", 0)
	main.set("los", -20.0)
	main.set("down_n", 1)
	main.set("first_z", -10.0)
	(main.get("score") as Array)[0] = 7
	(main.get("score") as Array)[1] = 3
	main.call("goto_playcall")
	await create_timer(0.4).timeout
	_check(String(_save().game.at) == "call" and int(_save().game.s0) == 7, "Continue: the play call saves the game with the score")
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await create_timer(0.2).timeout
	_check(bool(hud.get("menu_open")), "focus lost mid-game: the Menu opens and the game pauses")
	await _press(JOY_BUTTON_B)
	await create_timer(0.3).timeout
	var cards: Array = hud.get("cards")
	await _press(JOY_BUTTON_DPAD_RIGHT)
	await _press(JOY_BUTTON_DPAD_RIGHT)
	var first_i: int = cards.find(root.gui_get_focus_owner())
	await _press(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	var last_off: String = String(main.get("last_off"))
	_check(_st() == 3 and last_off != "" and first_i == 2, "play call: after the Menu closes, the D-pad reaches the third play and A picks it (%s)" % last_off)
	main.call("goto_playcall")
	await create_timer(0.4).timeout
	var lid: String = String(hud.get("last_id"))
	var fi: int = cards.find(root.gui_get_focus_owner())
	var tags: Array = hud.get("card_last")
	var ids: Array = hud.get("card_ids")
	var tag_on: bool = fi >= 0 and (tags[fi] as Label).visible and String(ids[fi]) == last_off
	_check(lid == last_off and fi == first_i and tag_on, "Run it again: the next play call opens on the last play, marked Last")

	# skip the wait after a play
	await _press(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	main.call("end_play", "incomplete")
	await create_timer(0.7).timeout
	var was_dead: bool = _st() == 5
	await _press(JOY_BUTTON_A)
	await create_timer(0.2).timeout
	_check(was_dead and _st() == 2, "after the whistle: A skips the wait once half a second has passed")

	# Continue from the title
	main.call("goto_title")
	await create_timer(0.3).timeout
	_check(_focus_text() == "Continue" and String((hud.get("continue_lbl") as Label).text).contains("7"), "title: Continue shows the game in progress and has the focus")
	await _press(JOY_BUTTON_A)
	await create_timer(0.5).timeout
	var sc: Array = main.get("score")
	ti = main.get("team_idx")
	_check(_st() == 2 and int(sc[0]) == 7 and int(sc[1]) == 3 and int(ti[1]) == opp and bool(main.get("season_game")), "Continue: A picks the game up at the play call with the same score and rival")
	_check(String(main.get("last_off")) == last_off, "Continue: Run it again remembers the last play")

	# burst: LT gives 2 seconds, then 5 seconds to charge
	await _press(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	var t0: int = Time.get_ticks_msec()
	while _st() != 3 and Time.get_ticks_msec() - t0 < 3000:
		await process_frame
	await create_timer(0.4).timeout
	await _press(JOY_BUTTON_A)
	t0 = Time.get_ticks_msec()
	while _st() != 4 and Time.get_ticks_msec() - t0 < 3000:
		await process_frame
	await create_timer(0.2).timeout
	var c: Node = main.get("ctrl")
	await _axis(JOY_AXIS_TRIGGER_LEFT)
	await create_timer(0.1).timeout
	var boosted: bool = float(main.get("boost_t")) > 0.0 and c != null and bool(c.get("boost"))
	var fast_ok: bool = c != null and absf(float(c.call("speed_now")) - float(c.get("top_speed")) * 1.3) < 0.01
	_check(_st() == 4 and boosted and fast_ok, "burst: LT gives the player you control 1.3 times top speed")
	await create_timer(2.2).timeout
	var cd: float = float(main.get("boost_cd"))
	_check(float(main.get("boost_t")) == 0.0 and cd > 4.0 and cd < 5.2, "burst: ends after 2 seconds, ready again 5 seconds later (%.1f s left)" % cd)
	await _key(KEY_F)
	_check(float(main.get("boost_t")) == 0.0, "burst: F does nothing while it charges")

	# season results and the save checks
	var week0: int = int(_save().season.week)
	main.call("_season_record", 21, 14)
	se = _save().season
	var w_sum: int = 0
	var l_sum: int = 0
	var t_sum: int = 0
	for i: int in 4:
		w_sum += int(se.w[i])
		l_sum += int(se.l[i])
		t_sum += int(se.t[i])
	_check(int(se.week) == week0 + 1 and int(se.w[int(se.team)]) == 1 and (se.last as Array).size() == 2 and w_sum == l_sum and w_sum + t_sum / 2 == 2, "season: a win goes in the standings, the other game of the week is played, the week moves on")
	_save().season.w = ["x", 1, 2, 3]
	main.call("_check_season_save")
	_check(not bool(_save().season.on), "save check: bad standings in the file set the season aside (E6.7)")
	_save().game.on = true
	_save().game.at = "bogus"
	main.call("_check_game_save")
	_check(not bool(_save().game.on), "save check: an odd saved game is dropped, so Continue does not show (E6.7)")

	# quarter length 1 minute
	_save().qlen = 1
	main.call("start_game", 0, false, 1)
	await create_timer(0.3).timeout
	_check(int(main.get("clock")) == 60, "Settings: a 1 minute quarter starts the clock at 1:00")
	_save().qlen = 2
	main.call("_forget_game")

	for l: String in out:
		print(l)
	print("QOL030 check %s (%d failed)" % ["ok" if fails == 0 else "FAIL", fails])
	quit()
