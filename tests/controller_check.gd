extends SceneTree
# Controller check (G5.8): plays Tiny Titans Football with controller button events only. Run: godot --headless --path . -s res://tests/controller_check.gd

var main: Node
var log_lines: PackedStringArray = PackedStringArray()

func _press(b: int, hold: float = 0.08) -> void:
	for down: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = b as JoyButton
		e.pressed = down
		Input.parse_input_event(e)
		await create_timer(hold if down else 0.05).timeout

func _st() -> int:
	return int(main.get("state"))

func _wait_for(states: Array[int], secs: float) -> bool:
	var t: float = 0.0
	while t < secs:
		if _st() in states:
			return true
		await process_frame
		t += root.get_process_delta_time()
	return false

func _initialize() -> void:
	main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	_run.call_deferred()

func _run() -> void:
	await create_timer(0.8).timeout
	await _press(JOY_BUTTON_A)
	await create_timer(0.4).timeout
	log_lines.append("title: A goes to team screen: %s" % (_st() == 1))
	await _press(JOY_BUTTON_A)
	await create_timer(0.6).timeout
	log_lines.append("team screen: A starts a game: %s (state %d)" % [_st() > 1, _st()])
	var picked_off: bool = false
	var held_after_pick: bool = false
	var bullet_ok: bool = false
	var lob_ok: bool = false
	var def_picked: bool = false
	var meter_ok: bool = false
	var throws: int = 0
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 120000 and not (bullet_ok and lob_ok and def_picked):
		var s: int = _st()
		var poss: int = int(main.get("poss"))
		var kind: String = String(main.get("play_kind"))
		if s == 2 and poss == 0:
			await create_timer(0.3).timeout
			await _press(JOY_BUTTON_A)                       # pick the highlighted play card
			if await _wait_for([3], 2.0):
				picked_off = true
				await create_timer(1.0).timeout
				if _st() == 3:
					held_after_pick = true
		elif s == 2:
			await create_timer(0.3).timeout
			await _press(JOY_BUTTON_A)                       # pick the highlighted defense card
			if await _wait_for([3, 4], 2.0):
				def_picked = true
			await _wait_for([5, 2, 6, 7], 30.0)
		elif s == 3 and poss == 0 and kind == "scrim":
			var is_pass: bool = String((main.get("off_play") as Dictionary).get("type", "")) == "pass"
			await _press(JOY_BUTTON_A)                       # snap
			if is_pass and await _wait_for([4], 2.0):
				var t: float = 0.0
				while not bool(main.call("_can_throw")) and _st() == 4 and t < 2.0:
					await process_frame
					t += root.get_process_delta_time()
				if bool(main.call("_can_throw")):
					var targets: Array = (main.get("off_play") as Dictionary).targets
					var lobs_before: int = int((main.get("events") as Dictionary).lob)
					if throws % 2 == 0:
						await _press(JOY_BUTTON_B, 0.06)         # tap B: bullet to receiver B
						var tgt: Node = main.get("ball_target")
						bullet_ok = bullet_ok or (tgt != null and String(tgt.get("role")) == String(targets[1]) and int((main.get("events") as Dictionary).lob) == lobs_before)
						log_lines.append("tap B: ball %s to %s, want %s" % [main.get("ball_state"), (String(tgt.get("role")) if tgt else "none"), targets[1]])
					else:
						# hold the last receiver's button for a lob: Y with 4 targets (11 on 11), X with 3 (7 on 7)
						var li: int = targets.size() - 1
						var lb: int = JOY_BUTTON_Y if li == 3 else JOY_BUTTON_X
						await _press(lb, 0.4)
						var tgt2: Node = main.get("ball_target")
						lob_ok = lob_ok or (tgt2 != null and String(tgt2.get("role")) == String(targets[li]) and int((main.get("events") as Dictionary).lob) == lobs_before + 1)
						log_lines.append("hold %s: ball %s to %s, want %s, lob counted %s" % ["Y" if li == 3 else "X", main.get("ball_state"), (String(tgt2.get("role")) if tgt2 else "none"), targets[li], int((main.get("events") as Dictionary).lob) == lobs_before + 1])
					throws += 1
			await _wait_for([5, 2, 6, 7], 30.0)
		elif s == 3 or s == 6:
			await create_timer(0.35).timeout
			await _press(JOY_BUTTON_A)                       # kick meter, or snap a kick
			meter_ok = true
			await create_timer(0.3).timeout
		else:
			await create_timer(0.15).timeout
	log_lines.append("play card picked with A: %s. No snap from the same press: %s" % [picked_off, held_after_pick])
	log_lines.append("defense card picked with A: %s. Kick meter or kick snap pressed with A: %s" % [def_picked, meter_ok])
	await _wait_for([2, 3], 20.0)
	await _press(JOY_BUTTON_START)
	await create_timer(0.3).timeout
	var opened: bool = bool((main.get("hud") as Node).get("menu_open"))
	await _press(JOY_BUTTON_START)
	await create_timer(0.3).timeout
	var closed: bool = not bool((main.get("hud") as Node).get("menu_open"))
	log_lines.append("Menu button opens the menu: %s. Closes it: %s" % [opened, closed])
	var all_ok: bool = picked_off and held_after_pick and bullet_ok and lob_ok and def_picked and opened and closed
	for l: String in log_lines:
		print(l)
	print("mode %d on %d" % [int(main.get("mode")), int(main.get("mode"))])
	print("JOY020 check %s" % ("ok" if all_ok else "FAIL"))
	quit()
