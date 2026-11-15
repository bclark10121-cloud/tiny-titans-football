extends CanvasLayer
# All on-screen interface: scoreboard, messages, Menu button, play cards, kick meter, touch pad and panels.
# Standard: one Menu button at the top right opens every option in a row across the top.

signal start_pressed
signal team_chosen(idx: int, practice: bool)
signal play_chosen(id: String)
signal menu_action(name: String)
signal world_tap(pos: Vector2)
signal throw_pressed(i: int)

const GOLD := Color(1.0, 0.82, 0.2)
const INK := Color(0.06, 0.09, 0.12, 0.88)

var root: Control
var score_lbl: Label
var info_lbl: Label
var banner: Label
var banner_t := 0.0
var hint: Label
var menu_btn: Button
var menu_row: HBoxContainer
var menu_open := false
var sound_btn: Button
var title_panel: Control
var team_panel: Control
var call_panel: Control
var call_grid: GridContainer
var call_title: Label
var over_panel: Control
var over_lbl: Label
var help_panel: Control
var meter: Control
var pad: Control
var throw_row: HBoxContainer
var burst_bar: ProgressBar

# touch state read by main.gd
var pad_active := false
var touch_seen := false
var stick := Vector2.ZERO
var btn_held := {"A": false, "B": false, "C": false}
var btn_just := {"A": false, "B": false, "C": false}
var _stick_id := -1
var _stick_origin := Vector2.ZERO
var _btn_ids := {}
var meter_pos := 0.5
var meter_half := 0.1

func _sb(c: Color, r := 10, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = c; s.set_corner_radius_all(r); s.set_content_margin_all(12)
	if border.a > 0: s.border_color = border; s.set_border_width_all(2)
	return s

func _lbl(t: String, size: int, col := Color.WHITE) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9)); l.add_theme_constant_override("outline_size", 6)
	return l

func _btn(t: String, size := 24) -> Button:
	var b := Button.new(); b.text = t; b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", _sb(Color(0.12, 0.17, 0.22, 0.95), 10, Color(1, 1, 1, 0.25)))
	b.add_theme_stylebox_override("hover", _sb(Color(0.18, 0.26, 0.33, 0.98), 10, GOLD))
	b.add_theme_stylebox_override("focus", _sb(Color(0.18, 0.26, 0.33, 0.98), 10, GOLD))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.3, 0.4, 0.2, 1), 10, GOLD))
	b.pressed.connect(func(): menu_action.emit("click"))
	return b

func _panel(parent: Control, anchor := Control.PRESET_CENTER) -> PanelContainer:
	var p := PanelContainer.new(); p.add_theme_stylebox_override("panel", _sb(INK, 16, Color(1, 1, 1, 0.2)))
	parent.add_child(p); p.set_anchors_and_offsets_preset(anchor); p.grow_horizontal = Control.GROW_DIRECTION_BOTH; p.grow_vertical = Control.GROW_DIRECTION_BOTH
	return p

func _full() -> Control:
	var c := Control.new(); root.add_child(c); c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func build(version: String, teams: Array) -> void:
	root = Control.new(); add_child(root); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# touch pad sits under everything else
	pad = Pad.new(); pad.hud = self; root.add_child(pad); pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# scoreboard, top left
	var sp := PanelContainer.new(); sp.add_theme_stylebox_override("panel", _sb(INK, 10)); root.add_child(sp); sp.position = Vector2(14, 12)
	var sv := VBoxContainer.new(); sp.add_child(sv)
	score_lbl = _lbl("", 26); sv.add_child(score_lbl)
	info_lbl = _lbl("", 20, GOLD); sv.add_child(info_lbl)
	burst_bar = ProgressBar.new(); burst_bar.custom_minimum_size = Vector2(160, 8); burst_bar.show_percentage = false; burst_bar.max_value = 1.0; sv.add_child(burst_bar)
	var bf := StyleBoxFlat.new(); bf.bg_color = GOLD; bf.set_corner_radius_all(3)
	var bb := StyleBoxFlat.new(); bb.bg_color = Color(1, 1, 1, 0.15); bb.set_corner_radius_all(3)
	burst_bar.add_theme_stylebox_override("fill", bf); burst_bar.add_theme_stylebox_override("background", bb)
	# message, one third down the screen
	banner = _lbl("", 46, Color.WHITE); root.add_child(banner); banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.anchor_top = 0.2; banner.anchor_bottom = 0.2; banner.anchor_left = 0.0; banner.anchor_right = 1.0; banner.offset_left = 0; banner.offset_right = 0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; banner.add_theme_constant_override("outline_size", 12); banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint = _lbl("", 22, Color(1, 1, 1, 0.92)); root.add_child(hint); hint.anchor_left = 0; hint.anchor_right = 1; hint.anchor_top = 1; hint.anchor_bottom = 1
	hint.offset_top = -44; hint.offset_bottom = -10; hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# kick meter
	meter = Meter.new(); meter.hud = self; root.add_child(meter); meter.anchor_left = 0.5; meter.anchor_right = 0.5; meter.anchor_top = 0.72; meter.anchor_bottom = 0.72
	meter.offset_left = -260; meter.offset_right = 260; meter.offset_top = 0; meter.offset_bottom = 44; meter.visible = false; meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# throw buttons for touch
	throw_row = HBoxContainer.new(); root.add_child(throw_row); throw_row.anchor_left = 1; throw_row.anchor_right = 1; throw_row.anchor_top = 1; throw_row.anchor_bottom = 1
	throw_row.offset_left = -470; throw_row.offset_right = -20; throw_row.offset_top = -430; throw_row.offset_bottom = -360; throw_row.alignment = BoxContainer.ALIGNMENT_END
	throw_row.add_theme_constant_override("separation", 12); throw_row.visible = false
	for i in 4:
		var tb := _btn(str(i + 1), 30); tb.custom_minimum_size = Vector2(92, 66); tb.focus_mode = Control.FOCUS_NONE
		tb.pressed.connect(func(): throw_pressed.emit(i)); throw_row.add_child(tb)
	_build_call(); _build_title(version); _build_team(teams); _build_over(); _build_help()
	# Menu button and its row, top right (built last so it sits on top)
	menu_row = HBoxContainer.new(); root.add_child(menu_row); menu_row.anchor_left = 0; menu_row.anchor_right = 1; menu_row.offset_left = 330; menu_row.offset_right = -150; menu_row.offset_top = 12; menu_row.offset_bottom = 60
	menu_row.alignment = BoxContainer.ALIGNMENT_END; menu_row.add_theme_constant_override("separation", 8); menu_row.visible = false
	for item in [["Resume", "resume"], ["How to play", "help"], ["Sound: On", "sound"], ["Restart game", "restart"], ["Quit to title", "title"]]:
		var b := _btn(item[0], 20); var act: String = item[1]
		b.pressed.connect(func(): menu_action.emit(act)); menu_row.add_child(b)
		if act == "sound": sound_btn = b
	menu_btn = _btn("Menu", 22); root.add_child(menu_btn); menu_btn.anchor_left = 1; menu_btn.anchor_right = 1; menu_btn.offset_left = -136; menu_btn.offset_right = -14; menu_btn.offset_top = 12; menu_btn.offset_bottom = 60
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.pressed.connect(func(): menu_action.emit("toggle"))

func set_menu(open: bool) -> void:
	menu_open = open; menu_row.visible = open; menu_btn.text = "Close" if open else "Menu"
	if open and menu_row.get_child_count() > 0: (menu_row.get_child(0) as Button).grab_focus()

func _build_title(version: String) -> void:
	title_panel = _full(); title_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var p := _panel(title_panel); var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 10)
	var t := _lbl("TINY TITANS FOOTBALL", 58, GOLD); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t)
	var s := _lbl("Version %s" % version, 18, Color(1, 1, 1, 0.7)); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(s)
	var d := _lbl("Arcade 11 on 11 football. Call a play, then run it.", 24); d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(d)
	var c := _lbl("Keyboard: WASD or arrows move. Space snaps and sprints. 1 to 4 pass. E juke. Q dive or tackle. Tab switch player.\nController: left stick moves. A snaps and sprints. A, B, X, Y pass. B juke. X dive or tackle. RT sprint.\nTouch: drag on the left to move. Buttons on the right. Tap a receiver or a number to pass.", 17, Color(1, 1, 1, 0.85))
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(c)
	var b := _btn("Start", 32); b.custom_minimum_size = Vector2(260, 64); b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): start_pressed.emit()); v.add_child(b); b.name = "StartBtn"
	var cr := _lbl("Music: \"Rock on Chicago\" by Kevin MacLeod (incompetech.com), CC BY 4.0. Full credits in CREDITS.md.", 13, Color(1, 1, 1, 0.55)); cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(cr)

func _build_team(teams: Array) -> void:
	team_panel = _full(); team_panel.mouse_filter = Control.MOUSE_FILTER_STOP; team_panel.visible = false
	var p := _panel(team_panel); var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 12)
	var t := _lbl("Pick your team", 40, GOLD); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t)
	var g := GridContainer.new(); g.columns = 2; g.add_theme_constant_override("h_separation", 12); g.add_theme_constant_override("v_separation", 12); v.add_child(g); g.name = "Teams"
	for i in teams.size():
		var tm: Dictionary = teams[i]
		var b := _btn(tm.name, 26); b.custom_minimum_size = Vector2(330, 74)
		var sw := ColorRect.new(); sw.color = Color(tm.jersey); sw.custom_minimum_size = Vector2(18, 0); sw.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE); sw.offset_right = 18; sw.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(sw)
		var sw2 := ColorRect.new(); sw2.color = Color(tm.helmet); sw2.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE); sw2.offset_left = -18; sw2.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(sw2)
		b.pressed.connect(func(): team_chosen.emit(i, _practice_box.button_pressed)); g.add_child(b)
	_practice_box = CheckBox.new(); _practice_box.text = "Practice mode (offense only, no clock, no score)"; _practice_box.add_theme_font_size_override("font_size", 20); v.add_child(_practice_box)
	var n := _lbl("Exhibition: four 2-minute quarters against the computer.", 18, Color(1, 1, 1, 0.8)); n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(n)
var _practice_box: CheckBox

func _build_call() -> void:
	call_panel = _full(); call_panel.visible = false
	var p := _panel(call_panel, Control.PRESET_CENTER); p.anchor_top = 0.56; p.anchor_bottom = 0.56
	var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 8)
	call_title = _lbl("Pick a play", 26, GOLD); call_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(call_title)
	call_grid = GridContainer.new(); call_grid.columns = 4; call_grid.add_theme_constant_override("h_separation", 10); call_grid.add_theme_constant_override("v_separation", 10); v.add_child(call_grid)

func show_call(title: String, cards: Array, formation: Dictionary, dformation: Dictionary) -> void:
	# cards: [{id, name, play (dictionary or null), kind: "off"/"def"/"special", tip}]
	for c in call_grid.get_children(): c.queue_free()
	call_title.text = title
	var first: Button = null
	for i in cards.size():
		var cd: Dictionary = cards[i]
		var b := _btn("", 18); b.custom_minimum_size = Vector2(236, 150)
		var dg := Diagram.new(); dg.card = cd; dg.formation = formation; dg.dformation = dformation; dg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(dg); dg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var l := _lbl("%d  %s" % [i + 1, cd.name], 19); l.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(l)
		l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); l.offset_top = -32; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var id: String = cd.id
		b.pressed.connect(func(): play_chosen.emit(id)); call_grid.add_child(b)
		if first == null: first = b
	call_panel.visible = true
	if first: first.grab_focus.call_deferred()

func hide_call() -> void:
	call_panel.visible = false

func call_ids() -> Array:
	var out := []
	for c in call_grid.get_children():
		if not c.is_queued_for_deletion(): out.append(c)
	return out

func _build_over() -> void:
	over_panel = _full(); over_panel.mouse_filter = Control.MOUSE_FILTER_STOP; over_panel.visible = false
	var p := _panel(over_panel); var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 12)
	var t := _lbl("FINAL", 44, GOLD); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t)
	over_lbl = _lbl("", 24); over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(over_lbl)
	var h := HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER; h.add_theme_constant_override("separation", 12); v.add_child(h)
	var a := _btn("Play again", 26); a.pressed.connect(func(): menu_action.emit("restart")); h.add_child(a); a.name = "Again"
	var b := _btn("Title", 26); b.pressed.connect(func(): menu_action.emit("title")); h.add_child(b)

func show_over(text: String) -> void:
	over_lbl.text = text; over_panel.visible = true
	(over_panel.find_child("Again", true, false) as Button).grab_focus.call_deferred()

func _build_help() -> void:
	help_panel = _full(); help_panel.mouse_filter = Control.MOUSE_FILTER_STOP; help_panel.visible = false
	var p := _panel(help_panel); var v := VBoxContainer.new(); p.add_child(v); v.add_theme_constant_override("separation", 10)
	var t := _lbl("How to play", 36, GOLD); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t)
	var txt := "Offense\n  Pick a play. Press Snap. On a pass play you are the quarterback: press a receiver's number to throw.\n  On a run play you are the runner. Sprint, juke past tacklers and dive for extra yards.\n  You get four downs to gain 10 yards. On fourth down you may punt or kick a field goal.\n\nDefense\n  Pick a defense. You control the player with the yellow ring. Switch to the nearest defender with Snap or Tab.\n  Run into the ball carrier to tackle, or dive at him.\n\nKicks\n  Stop the marker inside the green zone. Longer kicks have a smaller zone.\n\nKeyboard: WASD or arrows, Space, 1 to 4, E, Q, Tab, Esc.   Controller: stick, A, B, X, Y, RT, Start."
	var l := _lbl(txt, 18); v.add_child(l)
	var b := _btn("Close", 24); b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; b.pressed.connect(func(): menu_action.emit("help_close")); v.add_child(b); b.name = "HelpClose"

func show_help(on: bool) -> void:
	help_panel.visible = on
	if on: (help_panel.find_child("HelpClose", true, false) as Button).grab_focus.call_deferred()

func say(text: String, secs := 2.2, col := Color.WHITE) -> void:
	banner.text = text; banner_t = secs; banner.add_theme_color_override("font_color", col)

func _process(dt: float) -> void:
	if banner_t > 0.0:
		banner_t -= dt
		banner.modulate.a = clampf(banner_t * 3.0, 0.0, 1.0)
		if banner_t <= 0.0: banner.text = ""
	pad.visible = pad_active and touch_seen
	pad.queue_redraw()
	if meter.visible: meter.queue_redraw()

func clear_just() -> void:
	for k in btn_just: btn_just[k] = false

func _btn_centres() -> Dictionary:
	var s := root.size
	return {"A": Vector2(s.x - 110, s.y - 110), "B": Vector2(s.x - 250, s.y - 80), "C": Vector2(s.x - 110, s.y - 250)}

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventScreenDrag: touch_seen = true
	if not pad_active or menu_open: return
	var s := root.size
	var scale_v := s / Vector2(get_viewport().get_visible_rect().size)
	if e is InputEventScreenTouch:
		var pos: Vector2 = e.position * scale_v
		if e.pressed:
			if pos.y < 70: return
			var hit := ""
			var cs := _btn_centres()
			for k in cs:
				if pos.distance_to(cs[k]) < 72 and pad.labels[k] != "": hit = k
			if hit != "":
				btn_held[hit] = true; btn_just[hit] = true; _btn_ids[e.index] = hit
			elif pos.x < s.x * 0.45 and _stick_id == -1:
				_stick_id = e.index; _stick_origin = pos; stick = Vector2.ZERO
			else:
				world_tap.emit(e.position)
		else:
			if e.index == _stick_id:
				_stick_id = -1; stick = Vector2.ZERO
			if _btn_ids.has(e.index):
				btn_held[_btn_ids[e.index]] = false; _btn_ids.erase(e.index)
	elif e is InputEventScreenDrag and e.index == _stick_id:
		var v: Vector2 = (e.position * scale_v - _stick_origin) / 70.0
		stick = v.limit_length(1.0)

func reset_touch() -> void:
	_stick_id = -1; stick = Vector2.ZERO; _btn_ids.clear()
	for k in btn_held: btn_held[k] = false

class Pad extends Control:
	var hud
	var labels := {"A": "Snap", "B": "Juke", "C": "Dive"}
	func _draw() -> void:
		var cs: Dictionary = hud._btn_centres()
		for k in cs:
			if labels[k] == "": continue
			var on: bool = hud.btn_held[k]
			draw_circle(cs[k], 62, Color(1, 1, 1, 0.34 if on else 0.16))
			draw_arc(cs[k], 62, 0, TAU, 32, Color(1, 1, 1, 0.6), 3.0)
			var f := ThemeDB.fallback_font
			var t: String = labels[k]
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(f, cs[k] + Vector2(-w / 2, 8), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.95))
		var o: Vector2 = hud._stick_origin if hud._stick_id != -1 else Vector2(150, size.y - 150)
		draw_circle(o, 80, Color(1, 1, 1, 0.1)); draw_arc(o, 80, 0, TAU, 32, Color(1, 1, 1, 0.45), 3.0)
		draw_circle(o + hud.stick * 60, 34, Color(1, 1, 1, 0.4))

class Meter extends Control:
	var hud
	func _draw() -> void:
		var w := size.x; var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.07, 0.1, 0.9))
		draw_rect(Rect2(w * (0.5 - hud.meter_half), 0, w * hud.meter_half * 2, h), Color(0.2, 0.8, 0.3))
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.8), false, 3.0)
		draw_rect(Rect2(w * hud.meter_pos - 5, -8, 10, h + 16), Color(1, 0.9, 0.2))

class Diagram extends Control:
	var card: Dictionary
	var formation: Dictionary
	var dformation: Dictionary
	func _pt(x: float, z: float) -> Vector2:
		if card.kind == "def":      # the player sees his defense from behind, so flip the picture
			return Vector2(size.x * 0.5 - x * (size.x / 56.0), size.y * 0.3 + z * 3.4)
		return Vector2(size.x * 0.5 + x * (size.x / 56.0), size.y * 0.62 - z * 3.4)
	func _draw() -> void:
		var los := _pt(0, 0).y
		draw_line(Vector2(8, los), Vector2(size.x - 8, los), Color(1, 1, 1, 0.3), 1.5)
		if card.kind == "special":
			var f := ThemeDB.fallback_font
			var t: String = card.tip
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(f, Vector2((size.x - w) / 2, size.y * 0.42), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.85))
			return
		var play: Dictionary = card.play
		if card.kind == "off":
			for r in formation:
				var a: Array = formation[r]; var p := _pt(a[0], a[1])
				draw_circle(p, 4.0, Color(1, 1, 1, 0.9))
				if play.type == "pass" and play.routes.has(r):
					var last := p
					for q in play.routes[r].pts:
						var n := _pt(a[0] + q[0], a[1] + q[1]); draw_line(last, n, Color(1, 0.85, 0.2), 2.5); last = n
					draw_circle(last, 3.5, Color(1, 0.85, 0.2))
				elif play.type == "run" and r == "RB":
					var n1 := _pt(play.aim[0], play.aim[1]); var n2 := _pt(play.aim[0], play.aim[1] + 9)
					draw_line(p, n1, Color(1, 0.55, 0.2), 3.0); draw_line(n1, n2, Color(1, 0.55, 0.2), 3.0); draw_circle(n2, 4.0, Color(1, 0.55, 0.2))
		else:
			for r in dformation:
				var a: Array = play.align.get(r, dformation[r]); var p := _pt(a[0], a[1])
				var job: String = play.jobs.get(r, "rush")
				var col := Color(1, 0.4, 0.35) if job == "rush" else (Color(0.45, 0.75, 1) if job.begins_with("zone") else Color(1, 0.85, 0.2))
				draw_line(p + Vector2(-4, -4), p + Vector2(4, 4), col, 2.5); draw_line(p + Vector2(-4, 4), p + Vector2(4, -4), col, 2.5)
				if job == "rush": draw_line(p, _pt(a[0] * 0.5, -3), col, 2.0)
				elif job.begins_with("zone"):
					var zz := job.substr(5).split(","); draw_arc(_pt(float(zz[0]), float(zz[1])), 9, 0, TAU, 14, col, 1.5)
