extends CanvasLayer
class_name TTHud
# All on-screen interface: scoreboard, messages, Menu button, play cards, kick meter, touch pad and panels.
# Standard G5.1: one Menu button at the top right opens every option in a row across the top.
# Standard E5.3: in-game pieces sit inside a safe-area box. Full screen panels still cover the screen.

signal start_pressed
signal team_chosen(idx: int, practice: bool, difficulty: int)
signal play_chosen(id: String)
signal menu_action(name: String)
signal world_press(pos: Vector2)
signal world_release(pos: Vector2)
signal throw_down(i: int)
signal throw_up(i: int)

const GOLD: Color = Color(1.0, 0.82, 0.2)
const INK: Color = Color(0.06, 0.09, 0.12, 0.88)
const CARD_POOL: int = 12
const DIFF_NAMES: Array[String] = ["Easy", "Normal", "Hard"]

var root: Control
var safe: Control
var score_box: PanelContainer
var score_lbl: Label
var info_lbl: Label
var burst_bar: ProgressBar
var banner: Label
var banner_t: float = 0.0
var hint: Label
var menu_btn: Button
var menu_row: HBoxContainer
var menu_open: bool = false
var sound_btn: Button
var auto_btn: Button
var auto_box: CheckBox
var title_panel: Control
var team_panel: Control
var call_panel: Control
var call_title: Label
var tab_row: HBoxContainer
var tab_btns: Array[Button] = []
var call_grid: GridContainer
var cards: Array[Button] = []
var card_diag: Array[Diagram] = []
var card_lbl: Array[Label] = []
var card_ids: Array[String] = []
var tabs: Dictionary = {}
var tab_names: PackedStringArray = PackedStringArray()
var cur_tab: int = 0
var formations: Dictionary = {}
var dformation: Dictionary = {}
var over_panel: Control
var over_lbl: Label
var help_panel: Control
var meter: Meter
var pad: Pad
var throw_row: HBoxContainer
var throw_btns: Array[Button] = []
var throw_labels: PackedStringArray = PackedStringArray()
var diff_btns: Array[Button] = []
var mode_btns: Array[Button] = []
var game_mode: int = 7  # players a side picked on the team screen
var active_off: Array[String] = []  # roles on the field this game: diagrams draw only these
var active_def: Array[String] = []
var difficulty: int = 1
var practice_box: CheckBox

# touch state read by main.gd
var pad_active: bool = false
var touch_seen: bool = false
var stick: Vector2 = Vector2.ZERO
var btn_held: Dictionary = {"A": false, "B": false, "C": false}
var btn_just: Dictionary = {"A": false, "B": false, "C": false}
var meter_pos: float = 0.5
var meter_half: float = 0.1
var _stick_id: int = -1
var _stick_origin: Vector2 = Vector2.ZERO
var _btn_ids: Dictionary = {}
var _world_ids: Dictionary = {}

func _sb(c: Color, r: int = 10, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	s.set_content_margin_all(12)
	if border.a > 0.0:
		s.border_color = border
		s.set_border_width_all(2)
	return s

func _lbl(t: String, size: int, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _btn(t: String, size: int = 24) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(48, 48)
	b.add_theme_stylebox_override("normal", _sb(Color(0.12, 0.17, 0.22, 0.95), 10, Color(1, 1, 1, 0.25)))
	b.add_theme_stylebox_override("hover", _sb(Color(0.18, 0.26, 0.33, 0.98), 10, GOLD))
	b.add_theme_stylebox_override("focus", _sb(Color(0.18, 0.26, 0.33, 0.98), 10, GOLD))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.3, 0.4, 0.2, 1), 10, GOLD))
	b.pressed.connect(func() -> void: menu_action.emit("click"))
	return b

func _panel(parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(INK, 16, Color(1, 1, 1, 0.2)))
	parent.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	return p

func _full(parent: Control) -> Control:
	var c := Control.new()
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func build(version: String, teams: Array, diff: int, offense_forms: Dictionary, base_def: Dictionary) -> void:
	formations = offense_forms
	dformation = base_def
	difficulty = diff
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe = _full(root)
	pad = Pad.new()
	pad.hud = self
	safe.add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.visible = false
	# scoreboard, top left
	score_box = PanelContainer.new()
	score_box.add_theme_stylebox_override("panel", _sb(INK, 10))
	safe.add_child(score_box)
	score_box.position = Vector2(14, 12)
	var sv := VBoxContainer.new()
	score_box.add_child(sv)
	score_lbl = _lbl("", 26)
	sv.add_child(score_lbl)
	info_lbl = _lbl("", 20, GOLD)
	sv.add_child(info_lbl)
	burst_bar = ProgressBar.new()
	burst_bar.custom_minimum_size = Vector2(160, 8)
	burst_bar.show_percentage = false
	burst_bar.max_value = 1.0
	sv.add_child(burst_bar)
	var bf := StyleBoxFlat.new()
	bf.bg_color = GOLD
	bf.set_corner_radius_all(3)
	var bb := StyleBoxFlat.new()
	bb.bg_color = Color(1, 1, 1, 0.15)
	bb.set_corner_radius_all(3)
	burst_bar.add_theme_stylebox_override("fill", bf)
	burst_bar.add_theme_stylebox_override("background", bb)
	# message, one fifth of the way down the screen
	banner = _lbl("", 46)
	safe.add_child(banner)
	banner.anchor_left = 0.0
	banner.anchor_right = 1.0
	banner.anchor_top = 0.2
	banner.anchor_bottom = 0.2
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_constant_override("outline_size", 12)
	hint = _lbl("", 21, Color(1, 1, 1, 0.92))
	safe.add_child(hint)
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_top = -44
	hint.offset_bottom = -10
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# kick meter
	meter = Meter.new()
	meter.hud = self
	safe.add_child(meter)
	meter.anchor_left = 0.5
	meter.anchor_right = 0.5
	meter.anchor_top = 0.72
	meter.anchor_bottom = 0.72
	meter.offset_left = -260
	meter.offset_right = 260
	meter.offset_bottom = 44
	meter.visible = false
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# pass and audible buttons for touch
	throw_row = HBoxContainer.new()
	safe.add_child(throw_row)
	throw_row.anchor_left = 1.0
	throw_row.anchor_right = 1.0
	throw_row.anchor_top = 1.0
	throw_row.anchor_bottom = 1.0
	throw_row.offset_left = -640
	throw_row.offset_right = -20
	throw_row.offset_top = -430
	throw_row.offset_bottom = -362
	throw_row.alignment = BoxContainer.ALIGNMENT_END
	throw_row.add_theme_constant_override("separation", 12)
	throw_row.visible = false
	for i: int in 4:
		var tb := _btn(str(i + 1), 26)
		tb.custom_minimum_size = Vector2(92, 66)
		tb.focus_mode = Control.FOCUS_NONE
		tb.button_down.connect(func() -> void: throw_down.emit(i))
		tb.button_up.connect(func() -> void: throw_up.emit(i))
		throw_row.add_child(tb)
		throw_btns.append(tb)
	_build_call()
	_build_title(version)
	_build_team(teams)
	_build_over()
	_build_help()
	# Menu button and its row, top right (built last so it sits on top)
	menu_row = HBoxContainer.new()
	safe.add_child(menu_row)
	menu_row.anchor_left = 0.0
	menu_row.anchor_right = 1.0
	menu_row.offset_left = 330
	menu_row.offset_right = -150
	menu_row.offset_top = 12
	menu_row.offset_bottom = 60
	menu_row.alignment = BoxContainer.ALIGNMENT_END
	menu_row.add_theme_constant_override("separation", 8)
	menu_row.visible = false
	for item: Array in [["Resume", "resume"], ["Help", "help"], ["Sound: On", "sound"], ["Auto pass: Off", "autopass"], ["Restart", "restart"], ["Title", "title"]]:
		var b := _btn(String(item[0]), 19)
		var act: String = String(item[1])
		b.pressed.connect(func() -> void: menu_action.emit(act))
		menu_row.add_child(b)
		if act == "sound":
			sound_btn = b
		elif act == "autopass":
			auto_btn = b
	menu_btn = _btn("Menu", 22)
	safe.add_child(menu_btn)
	menu_btn.anchor_left = 1.0
	menu_btn.anchor_right = 1.0
	menu_btn.offset_left = -136
	menu_btn.offset_right = -14
	menu_btn.offset_top = 12
	menu_btn.offset_bottom = 60
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.pressed.connect(func() -> void: menu_action.emit("toggle"))
	set_process(false)

func apply_safe_area(fake: int) -> void:
	# Margins from the display safe area (notches, rounded corners, gesture bars), in canvas units.
	var vis: Vector2 = root.get_viewport_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	var l: float = 0.0
	var t: float = 0.0
	var r: float = 0.0
	var b: float = 0.0
	if win.x > 0.0 and not OS.has_feature("web"):
		var sa: Rect2i = DisplayServer.get_display_safe_area()
		var wp := Vector2(DisplayServer.window_get_position())
		var k: Vector2 = vis / win
		if sa.size.x > 0 and sa.size.y > 0:
			l = maxf(0.0, (float(sa.position.x) - wp.x) * k.x)
			t = maxf(0.0, (float(sa.position.y) - wp.y) * k.y)
			r = maxf(0.0, (wp.x + win.x - float(sa.end.x)) * k.x)
			b = maxf(0.0, (wp.y + win.y - float(sa.end.y)) * k.y)
	if fake > 0:
		l = maxf(l, float(fake))
		r = maxf(r, float(fake) * 0.5)
	l = minf(l, vis.x * 0.12)
	r = minf(r, vis.x * 0.12)
	t = minf(t, vis.y * 0.12)
	b = minf(b, vis.y * 0.12)
	safe.offset_left = l
	safe.offset_top = t
	safe.offset_right = -r
	safe.offset_bottom = -b

func set_mode(m: int) -> void:
	game_mode = m
	for b: Button in mode_btns:
		b.set_pressed_no_signal(b.text.begins_with("%d " % m))

func active_on(role: String, off: bool) -> bool:
	var list: Array[String] = active_off if off else active_def
	return list.is_empty() or list.has(role)

func set_auto_pass(on: bool) -> void:
	# keeps the team screen box and the Menu button in step with the saved setting
	if auto_box:
		auto_box.set_pressed_no_signal(on)
	if auto_btn:
		auto_btn.text = "Auto pass: On" if on else "Auto pass: Off"

func set_menu(open: bool) -> void:
	menu_open = open
	menu_row.visible = open
	menu_btn.text = "Close" if open else "Menu"
	if open and menu_row.get_child_count() > 0:
		(menu_row.get_child(0) as Button).grab_focus()

func set_ingame(on: bool) -> void:
	score_box.visible = on
	menu_btn.visible = on
	if not on:
		hint.text = ""

func show_screen(which: String) -> void:
	title_panel.visible = which == "title"
	team_panel.visible = which == "team"
	if which == "title":
		(title_panel.find_child("StartBtn", true, false) as Button).grab_focus.call_deferred()
	elif which == "team":
		var g: Node = team_panel.find_child("Teams", true, false)
		(g.get_child(0) as Button).grab_focus.call_deferred()
	if which != "over":
		over_panel.visible = false

func _build_title(version: String) -> void:
	title_panel = _full(root)
	title_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var p := _panel(title_panel)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_theme_constant_override("separation", 10)
	var t := _lbl("TINY TITANS FOOTBALL", 58, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := _lbl("Version %s" % version, 18, Color(1, 1, 1, 0.7))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var d := _lbl("Arcade 7 on 7 and 11 on 11 football. Call a play, then run it.", 24)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(d)
	var c := _lbl("Keyboard: WASD or arrows move. Space snaps and sprints. 1 to 4 pass: tap for a bullet, hold for a lob.\nE juke. Q dive or tackle. Tab switch player. R audible. 1 to 4 before the snap: hot route. Esc menu.\nController: stick moves, A picks and snaps. Pass with the button shown on each receiver: A, B, X or Y. Tap for a bullet, hold for a lob.\nRT sprint. B juke or pitch. X dive. LB switch. Y audible. RB plus a receiver's button: hot route. View or Menu: Menu.\nTouch: drag on the left to move. Buttons on the right. Tap a receiver to pass, hold for a lob.", 16, Color(1, 1, 1, 0.85))
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(c)
	var b := _btn("Start", 32)
	b.custom_minimum_size = Vector2(260, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void: start_pressed.emit())
	b.name = "StartBtn"
	v.add_child(b)
	var cr := _lbl("Music: \"Rock on Chicago\" by Kevin MacLeod (incompetech.com), CC BY 4.0. Full credits in CREDITS.md.", 13, Color(1, 1, 1, 0.55))
	cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cr)

func _build_team(teams: Array) -> void:
	team_panel = _full(root)
	team_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	team_panel.visible = false
	var p := _panel(team_panel)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_theme_constant_override("separation", 12)
	var t := _lbl("Pick your team", 40, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	g.name = "Teams"
	v.add_child(g)
	for i: int in teams.size():
		var tm: Dictionary = teams[i]
		var b := _btn(String(tm.name), 26)
		b.custom_minimum_size = Vector2(330, 74)
		var sw := ColorRect.new()
		sw.color = Color(String(tm.jersey))
		sw.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		sw.offset_right = 18
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sw)
		var sw2 := ColorRect.new()
		sw2.color = Color(String(tm.helmet))
		sw2.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		sw2.offset_left = -18
		sw2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sw2)
		b.pressed.connect(func() -> void: team_chosen.emit(i, practice_box.button_pressed, difficulty))
		g.add_child(b)
	var dr := HBoxContainer.new()
	dr.alignment = BoxContainer.ALIGNMENT_CENTER
	dr.add_theme_constant_override("separation", 10)
	v.add_child(dr)
	dr.add_child(_lbl("Difficulty:", 20))
	var group := ButtonGroup.new()
	for i: int in 3:
		var db := _btn(DIFF_NAMES[i], 20)
		db.toggle_mode = true
		db.button_group = group
		db.custom_minimum_size = Vector2(120, 48)
		db.button_pressed = i == difficulty
		db.pressed.connect(func() -> void: difficulty = i)
		dr.add_child(db)
		diff_btns.append(db)
	var mr := HBoxContainer.new()
	mr.alignment = BoxContainer.ALIGNMENT_CENTER
	mr.add_theme_constant_override("separation", 10)
	v.add_child(mr)
	mr.add_child(_lbl("Players:", 20))
	var mgroup := ButtonGroup.new()
	for m: int in [7, 11]:
		var mb := _btn("%d on %d" % [m, m], 20)
		mb.toggle_mode = true
		mb.button_group = mgroup
		mb.custom_minimum_size = Vector2(120, 48)
		mb.button_pressed = m == game_mode
		mb.pressed.connect(func() -> void: menu_action.emit("mode%d" % m))
		mr.add_child(mb)
		mode_btns.append(mb)
	practice_box = CheckBox.new()
	practice_box.text = "Practice mode (offense only, no clock, no score)"
	practice_box.add_theme_font_size_override("font_size", 20)
	practice_box.custom_minimum_size = Vector2(0, 48)
	v.add_child(practice_box)
	auto_box = CheckBox.new()
	auto_box.text = "Auto pass (the QB throws, you run after the catch)"
	auto_box.add_theme_font_size_override("font_size", 20)
	auto_box.custom_minimum_size = Vector2(0, 48)
	auto_box.toggled.connect(func(_on: bool) -> void: menu_action.emit("autopass"))
	v.add_child(auto_box)
	var n := _lbl("Exhibition: four 2-minute quarters against the computer. Ties go to sudden death overtime.", 17, Color(1, 1, 1, 0.8))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)

func _build_call() -> void:
	call_panel = _full(safe)
	call_panel.visible = false
	var p := _panel(call_panel)
	p.anchor_top = 0.57
	p.anchor_bottom = 0.57
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_theme_constant_override("separation", 8)
	call_title = _lbl("Pick a play", 24, GOLD)
	call_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(call_title)
	tab_row = HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 8)
	v.add_child(tab_row)
	for i: int in 5:
		var tb := _btn("", 19)
		tb.custom_minimum_size = Vector2(150, 48)
		tb.pressed.connect(func() -> void: select_tab(i))
		tab_row.add_child(tb)
		tab_btns.append(tb)
	call_grid = GridContainer.new()
	call_grid.columns = 4
	call_grid.add_theme_constant_override("h_separation", 10)
	call_grid.add_theme_constant_override("v_separation", 10)
	v.add_child(call_grid)
	for i: int in CARD_POOL:
		var b := _btn("", 18)
		b.custom_minimum_size = Vector2(236, 116)
		var dg := Diagram.new()
		dg.hud = self
		dg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(dg)
		dg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var l := _lbl("", 18)
		b.add_child(l)
		l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		l.offset_top = -30
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(func() -> void: play_chosen.emit(card_ids[i]))
		call_grid.add_child(b)
		cards.append(b)
		card_diag.append(dg)
		card_lbl.append(l)
		card_ids.append("")

func show_call(title: String, tabs_in: Dictionary, order: PackedStringArray, start: String) -> void:
	call_title.text = title
	tabs = tabs_in
	tab_names = order
	for i: int in tab_btns.size():
		tab_btns[i].visible = i < order.size() and order.size() > 1
		if i < order.size():
			tab_btns[i].text = order[i]
	call_panel.visible = true
	select_tab(maxi(0, order.find(start)))

func select_tab(i: int) -> void:
	if tab_names.size() == 0:
		return
	cur_tab = clampi(i, 0, tab_names.size() - 1)
	for k: int in tab_btns.size():
		tab_btns[k].modulate = Color(1, 1, 1) if k == cur_tab else Color(0.7, 0.7, 0.75)
	var list: Array = tabs[tab_names[cur_tab]]
	var first: Button = null
	for k: int in CARD_POOL:
		var on: bool = k < list.size()
		cards[k].visible = on
		if not on:
			continue
		var cd: Dictionary = list[k]
		card_ids[k] = String(cd.id)
		card_diag[k].card = cd
		card_diag[k].queue_redraw()
		card_lbl[k].text = "%d  %s" % [k + 1, String(cd.name)] if k < 9 else String(cd.name)
		if first == null:
			first = cards[k]
	if first:
		first.grab_focus.call_deferred()

func cycle_tab(dir: int) -> void:
	if tab_names.size() > 1:
		select_tab((cur_tab + dir + tab_names.size()) % tab_names.size())

func pick(i: int) -> void:
	if call_panel.visible and i < CARD_POOL and cards[i].visible:
		play_chosen.emit(card_ids[i])

func hide_call() -> void:
	call_panel.visible = false

func _build_over() -> void:
	over_panel = _full(root)
	over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	over_panel.visible = false
	var p := _panel(over_panel)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_theme_constant_override("separation", 12)
	var t := _lbl("FINAL", 44, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	over_lbl = _lbl("", 24)
	over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(over_lbl)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var a := _btn("Play again", 26)
	a.pressed.connect(func() -> void: menu_action.emit("restart"))
	a.name = "Again"
	h.add_child(a)
	var b := _btn("Title", 26)
	b.pressed.connect(func() -> void: menu_action.emit("title"))
	h.add_child(b)

func show_over(text: String) -> void:
	over_lbl.text = text
	over_panel.visible = true
	(over_panel.find_child("Again", true, false) as Button).grab_focus.call_deferred()

func _build_help() -> void:
	help_panel = _full(root)
	help_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	help_panel.visible = false
	var p := _panel(help_panel)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_theme_constant_override("separation", 10)
	var t := _lbl("How to play", 34, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var txt: String = "Offense\n  Pick a play from the Short, Deep, Run or Option tab. Press Snap.\n  Pass plays: press a receiver's number. Tap for a fast bullet, hold for a lob over defenders.\n  Auto pass (Menu or team screen): the QB throws for you and you take over the catcher.\n  Option plays: the QB runs at the edge. Pitch (E, B or the Pitch button) to the back, or keep it.\n  Before the snap: Audible (R, Y or the Audible button) swaps the play. 1 to 4 changes a receiver's route.\n  Run plays: sprint, juke past tacklers and dive for extra yards.\n  Four downs to gain 10 yards. On fourth down you may punt or kick a field goal.\n  After a touchdown, kick the extra point or go for two from the 3.\n\nDefense\n  Pick a defense from the Man, Zone, Blitz or Run tab. You control the player with the yellow ring.\n  Switch to the defender nearest the ball. Run into the ball carrier to tackle, or dive at him.\n\nKicks and returns\n  Stop the marker in the green. Punts and kickoffs go farther, field goals go straighter.\n  When you receive, the returner catches the ball. Then you run it back.\n  Interceptions and fumbles are live. Run them back for a score.\n\nTied after four quarters: sudden death overtime. The next score wins.\n\nController (Xbox layout)\n  Stick or D-pad moves and picks. A chooses, snaps and stops the kick meter. B goes back. View or Menu opens the Menu.\n  Pass with the button shown on each receiver: A, B, X or Y. Tap for a bullet, hold for a lob.\n  RT sprint. B juke, or pitch on option plays. X dive or tackle. LB switch player.\n  Before the snap: Y audible. Hold RB and press a receiver's button for a hot route. Play call: LB, RB or B next tab, X back."
	v.add_child(_lbl(txt, 16))
	var b := _btn("Close", 24)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void: menu_action.emit("help_close"))
	b.name = "HelpClose"
	v.add_child(b)

func show_help(on: bool) -> void:
	help_panel.visible = on
	if on:
		(help_panel.find_child("HelpClose", true, false) as Button).grab_focus.call_deferred()

func set_meter(on: bool, half: float, at: float = 0.72) -> void:
	# at: how far down the screen the meter sits (0 top, 1 bottom), picked per kick to sit on open grass
	meter.visible = on
	meter_half = half
	meter.anchor_top = at
	meter.anchor_bottom = at
	meter.offset_top = 0
	meter.offset_bottom = 44
	if on:
		meter.queue_redraw()

func show_throw(on: bool, labels: PackedStringArray) -> void:
	if on == throw_row.visible and labels == throw_labels:
		return
	throw_row.visible = on
	throw_labels = labels
	for i: int in throw_btns.size():
		throw_btns[i].visible = i < labels.size()
		if i < labels.size():
			throw_btns[i].text = labels[i]
			throw_btns[i].custom_minimum_size = Vector2(92 if labels[i].length() <= 2 else 150, 66)

func set_pad_labels(a: String, b: String, c: String) -> void:
	if String(pad.labels.A) == a and String(pad.labels.B) == b and String(pad.labels.C) == c:
		return
	pad.labels = {"A": a, "B": b, "C": c}
	pad.queue_redraw()

func say(text: String, secs: float = 2.2, col: Color = Color.WHITE) -> void:
	banner.text = text
	banner_t = secs
	banner.modulate.a = 1.0
	banner.add_theme_color_override("font_color", col)
	set_process(true)

func _process(dt: float) -> void:
	# Runs only while a message is fading (standard E1.3).
	banner_t -= dt
	banner.modulate.a = clampf(banner_t * 3.0, 0.0, 1.0)
	if banner_t <= 0.0:
		banner.text = ""
		set_process(false)

func update_pad() -> void:
	var want: bool = pad_active and touch_seen
	if pad.visible != want:
		pad.visible = want
		pad.queue_redraw()

func clear_just() -> void:
	for k: String in btn_just:
		btn_just[k] = false

func _btn_centres() -> Dictionary:
	var s: Vector2 = safe.size
	return {"A": Vector2(s.x - 110, s.y - 110), "B": Vector2(s.x - 250, s.y - 80), "C": Vector2(s.x - 110, s.y - 250)}

func _over_gui(pos: Vector2) -> bool:
	for c: Control in [menu_btn, menu_row, call_panel, help_panel, over_panel, title_panel, team_panel]:
		if c.visible and c.get_global_rect().has_point(pos):
			return true
	if throw_row.visible:
		for b: Button in throw_btns:
			if b.visible and b.get_global_rect().has_point(pos):
				return true
	return false

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		touch_seen = true
		update_pad()
	if not pad_active or menu_open:
		return
	if e is InputEventScreenTouch:
		var st: InputEventScreenTouch = e
		var pos: Vector2 = st.position - safe.global_position
		if st.pressed:
			if _over_gui(st.position):
				return
			var hit: String = ""
			var cs: Dictionary = _btn_centres()
			for k: String in cs:
				if pos.distance_squared_to(cs[k]) < 5184.0 and String(pad.labels[k]) != "":
					hit = k
			if hit != "":
				btn_held[hit] = true
				btn_just[hit] = true
				_btn_ids[st.index] = hit
				pad.queue_redraw()
			elif pos.x < safe.size.x * 0.45 and _stick_id == -1:
				_stick_id = st.index
				_stick_origin = pos
				stick = Vector2.ZERO
				pad.queue_redraw()
			else:
				_world_ids[st.index] = true
				world_press.emit(st.position)
		else:
			if st.index == _stick_id:
				_stick_id = -1
				stick = Vector2.ZERO
				pad.queue_redraw()
			if _btn_ids.has(st.index):
				btn_held[String(_btn_ids[st.index])] = false
				_btn_ids.erase(st.index)
				pad.queue_redraw()
			if _world_ids.has(st.index):
				_world_ids.erase(st.index)
				world_release.emit(st.position)
	elif e is InputEventScreenDrag:
		var sd: InputEventScreenDrag = e
		if sd.index == _stick_id:
			stick = ((sd.position - safe.global_position - _stick_origin) / 70.0).limit_length(1.0)
			pad.queue_redraw()

func reset_touch() -> void:
	_stick_id = -1
	stick = Vector2.ZERO
	_btn_ids.clear()
	_world_ids.clear()
	for k: String in btn_held:
		btn_held[k] = false

class Pad extends Control:
	var hud: TTHud
	var labels: Dictionary = {"A": "Snap", "B": "", "C": ""}

	func _draw() -> void:
		var cs: Dictionary = hud._btn_centres()
		var f: Font = ThemeDB.fallback_font
		for k: String in cs:
			var t: String = String(labels[k])
			if t == "":
				continue
			var c: Vector2 = cs[k]
			var on: bool = hud.btn_held[k]
			draw_circle(c, 62.0, Color(1, 1, 1, 0.34 if on else 0.16))
			draw_arc(c, 62.0, 0.0, TAU, 32, Color(1, 1, 1, 0.6), 3.0)
			var w: float = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(f, c + Vector2(-w / 2.0, 8.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.95))
		var o: Vector2 = hud._stick_origin if hud._stick_id != -1 else Vector2(150.0, size.y - 150.0)
		draw_circle(o, 80.0, Color(1, 1, 1, 0.1))
		draw_arc(o, 80.0, 0.0, TAU, 32, Color(1, 1, 1, 0.45), 3.0)
		draw_circle(o + hud.stick * 60.0, 34.0, Color(1, 1, 1, 0.4))

class Meter extends Control:
	var hud: TTHud

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.07, 0.1, 0.9))
		draw_rect(Rect2(w * (0.5 - hud.meter_half), 0, w * hud.meter_half * 2.0, h), Color(0.2, 0.8, 0.3))
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.8), false, 3.0)
		draw_rect(Rect2(w * hud.meter_pos - 5.0, -8.0, 10.0, h + 16.0), Color(1, 0.9, 0.2))

class Diagram extends Control:
	var hud: TTHud
	var card: Dictionary = {}

	func _pt(x: float, z: float) -> Vector2:
		if String(card.get("kind", "")) == "def":
			return Vector2(size.x * 0.5 - x * (size.x / 56.0), size.y * 0.26 + z * 2.9)
		return Vector2(size.x * 0.5 + x * (size.x / 56.0), size.y * 0.62 - z * 2.6)

	func _dash(a: Vector2, b: Vector2, col: Color) -> void:
		var n: int = maxi(2, int(a.distance_to(b) / 7.0))
		for k: int in n:
			if k % 2 == 0:
				draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), col, 2.5)
		draw_circle(b, 3.5, col)

	func _draw() -> void:
		if card.is_empty():
			return
		var los: float = _pt(0.0, 0.0).y
		draw_line(Vector2(8, los), Vector2(size.x - 8, los), Color(1, 1, 1, 0.3), 1.5)
		var kind: String = String(card.get("kind", ""))
		var f: Font = ThemeDB.fallback_font
		if kind == "special":
			var t: String = String(card.get("tip", ""))
			var w: float = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(f, Vector2((size.x - w) / 2.0, size.y * 0.42), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.85))
			return
		var play: Dictionary = card.play
		if kind == "off":
			var form: Dictionary = hud.formations.get(String(play.get("formation", "gun")), {})
			var routes: Dictionary = play.get("routes", {})
			for r: String in form:
				if r == "name" or (not hud.active_on(r, true)):
					continue
				var a: Array = form[r]
				var p: Vector2 = _pt(float(a[0]), float(a[1]))
				draw_circle(p, 3.5, Color(1, 1, 1, 0.9))
				if String(play.type) == "pass" and routes.has(r):
					var last: Vector2 = p
					var pts: Array = (routes[r] as Dictionary).pts
					for q: Array in pts:
						var n: Vector2 = _pt(float(a[0]) + float(q[0]), float(a[1]) + float(q[1]))
						draw_line(last, n, Color(1, 0.85, 0.2), 2.5)
						last = n
					draw_circle(last, 3.0, Color(1, 0.85, 0.2))
				elif String(play.type) == "run" and r == String(play.get("carrier", "RB")):
					var aim: Array = play.aim
					var n1: Vector2 = _pt(float(aim[0]), float(aim[1]))
					var n2: Vector2 = _pt(float(aim[0]), float(aim[1]) + 9.0)
					draw_line(p, n1, Color(1, 0.55, 0.2), 3.0)
					draw_line(n1, n2, Color(1, 0.55, 0.2), 3.0)
					draw_circle(n2, 4.0, Color(1, 0.55, 0.2))
				if String(play.get("option", "")) == "pitch" and r == "RB":
					# the pitch man trails the QB toward the edge
					var aim3: Array = play.aim
					var sx: float = signf(float(aim3[0]))
					_dash(p, _pt(float(aim3[0]) + sx * 4.5, float(aim3[1]) - 1.8), Color(0.6, 0.85, 1))
				elif String(play.get("option", "")) == "read" and r == "QB":
					# the QB keep path if the end crashes
					var kp: Array = play.get("keep", [10, 0.5])
					_dash(p, _pt(float(kp[0]), float(kp[1])), Color(0.6, 0.85, 1))
			draw_string(f, Vector2(8, 18), String(form.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.55))
		else:
			var jobs: Dictionary = play.get("jobs", {})
			var align: Dictionary = play.get("align", {})
			for r: String in hud.dformation:
				if not hud.active_on(r, false):
					continue
				var a2: Array = align.get(r, hud.dformation[r])
				var p2: Vector2 = _pt(float(a2[0]), float(a2[1]))
				var job: String = String(jobs.get(r, "rush"))
				var col: Color = Color(1, 0.4, 0.35)
				if job.begins_with("zone"):
					col = Color(0.45, 0.75, 1)
				elif job.begins_with("man") or job == "spy":
					col = Color(1, 0.85, 0.2)
				draw_line(p2 + Vector2(-4, -4), p2 + Vector2(4, 4), col, 2.5)
				draw_line(p2 + Vector2(-4, 4), p2 + Vector2(4, -4), col, 2.5)
				if job == "rush":
					draw_line(p2, _pt(float(a2[0]) * 0.5, -3.0), col, 2.0)
				elif job.begins_with("zone"):
					var zz: PackedStringArray = job.substr(5).split(",")
					draw_arc(_pt(float(zz[0]), float(zz[1])), 8.0, 0.0, TAU, 14, col, 1.5)
