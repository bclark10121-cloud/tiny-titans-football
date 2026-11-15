extends Node3D
# Tiny Titans Football. Arcade 11 on 11 football: call a play, then run it.
# The world, the rules, the computer players and the camera all live here. Plays and teams are data (data/*.json).
# Field units are yards. The field runs along Z: goal lines at z = -50 and z = +50. Side 0 (the player) attacks +Z.

const VERSION := "0.1.0"
const HALF_W := 26.65
const GOAL := 50.0
const END := 60.0
const QLEN := 120.0
const OFF_ROLES := ["LT", "LG", "C", "RG", "RT", "QB", "RB", "TE", "WR1", "WR2", "WR3"]
const DEF_ROLES := ["DE1", "DT1", "DT2", "DE2", "LB2", "LB1", "LB3", "S1", "CB1", "CB2", "S2"]
const SPEED := {"QB": 7.8, "RB": 9.0, "TE": 8.3, "WR1": 9.4, "WR2": 9.4, "WR3": 9.2, "LT": 6.2, "LG": 6.2, "C": 6.2, "RG": 6.2, "RT": 6.2,
	"DE1": 7.4, "DE2": 7.4, "DT1": 6.8, "DT2": 6.8, "LB1": 8.7, "LB2": 8.6, "LB3": 8.7, "CB1": 9.55, "CB2": 9.55, "S1": 9.4, "S2": 9.3}
const DIGITS := {"0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111", "4": "101101111001001", "5": "111100111001111"}
enum St {TITLE, TEAMSEL, PLAYCALL, PRESNAP, LIVE, DEAD, KICK, OVER}

var state: int = St.TITLE
var teams: Array = []
var plays: Dictionary = {}
var team_idx := [0, 1]
var bot := false
var bot_games := 1
var bot_done := 0
var practice := false
var score := [0, 0]
var stats := [{}, {}]
var poss := 0
var los := -25.0
var ball_x := 0.0
var down_n := 1
var first_z := -15.0
var quarter := 1
var clock := QLEN
var opening_receiver := 0
var players := [[], []]
var roles := [{}, {}]
var off_play: Dictionary = {}
var def_play: Dictionary = {}
var carrier: TTPlayer = null
var ctrl: TTPlayer = null
var ball: MeshInstance3D
var ball_state := "held"
var ball_from := Vector3.ZERO
var ball_to := Vector3.ZERO
var ball_t := 0.0
var ball_T := 1.0
var ball_arc := 2.0
var ball_target: TTPlayer = null
var live_t := 0.0
var presnap_t := 0.0
var handed := false
var pursue := false
var qb_t := 2.0
var dead_t := 0.0
var pending := "play"
var kick := {}
var events := {}
var cam: Camera3D
var cam_focus := Vector3(0, 0, -25)
var hud
var field_mat: StandardMaterial3D
var los_line: MeshInstance3D
var first_line: MeshInstance3D
var sfx := {}
var music: AudioStreamPlayer
var crowd: AudioStreamPlayer
var just := {}
var pad_last := false
var save := {"v": 1, "sound": true, "wins": 0, "losses": 0, "ties": 0, "team": 0}
var fast := false
var verbose := false
var test_hook := false

func dirv(side: int) -> float:
	return 1.0 if side == 0 else -1.0

func R(side: int, role: String) -> TTPlayer:
	return roles[side].get(role, null)

func tm(side: int) -> Dictionary:
	return teams[team_idx[side]]

func human() -> bool:
	return not bot

func user_off() -> bool:
	return human() and poss == 0

func _load_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _ready() -> void:
	randomize()
	teams = _load_json("res://data/teams.json")
	plays = _load_json("res://data/plays.json")
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		if q is String:
			for a in q.trim_prefix("?").split("&"): args.append("--" + a)
	for a in args:
		if a == "--bot": bot = true
		elif a == "--fast": fast = true
		elif a == "--verbose": verbose = true
		elif a == "--test": test_hook = OS.has_feature("web")
		elif a.begins_with("--games="): bot_games = int(a.get_slice("=", 1))
		elif a.begins_with("--seed="): seed(int(a.get_slice("=", 1)))
	_load_save()
	_build_world()
	_build_audio()
	hud = load("res://scripts/hud.gd").new()
	add_child(hud)
	hud.build(VERSION, teams)
	hud.start_pressed.connect(_on_start)
	hud.team_chosen.connect(start_game)
	hud.play_chosen.connect(_on_play_chosen)
	hud.menu_action.connect(_on_menu)
	hud.world_tap.connect(_on_world_tap)
	hud.throw_pressed.connect(_user_throw)
	_spawn_players()
	_apply_sound()
	goto_title()
	if bot: start_game(0, false)

# ---------------------------------------------------------------- world

func _mi(mesh: Mesh, m: Material, pos: Vector3, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = m; mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(mi); return mi

func _build_world() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.46, 0.7, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(1, 1, 1); env.ambient_light_energy = 0.62
	we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-58, 28, 0); sun.light_energy = 1.05; sun.shadow_enabled = false; add_child(sun)
	# field: one textured slab, so lines never flicker against the grass
	field_mat = StandardMaterial3D.new(); field_mat.roughness = 1.0
	var pm := PlaneMesh.new(); pm.size = Vector2(64, 144); _mi(pm, field_mat, Vector3.ZERO)
	var apron := PlaneMesh.new(); apron.size = Vector2(400, 400); _mi(apron, TTPlayer.mat(Color(0.16, 0.3, 0.18), 1.0), Vector3(0, -0.2, 0))
	_paint_field()
	# goal posts
	var yellow := TTPlayer.mat(Color(0.98, 0.85, 0.15), 0.4)
	for sz in [-1.0, 1.0]:
		var cyl := CylinderMesh.new(); cyl.top_radius = 0.18; cyl.bottom_radius = 0.18; cyl.height = 3.4; cyl.radial_segments = 8
		_mi(cyl, yellow, Vector3(0, 1.7, sz * (END + 0.6)))
		var bar := BoxMesh.new(); bar.size = Vector3(6.4, 0.3, 0.3); _mi(bar, yellow, Vector3(0, 3.4, sz * (END + 0.6)))
		for sx in [-1.0, 1.0]:
			var up := BoxMesh.new(); up.size = Vector3(0.26, 9.0, 0.26); _mi(up, yellow, Vector3(sx * 3.1, 7.9, sz * (END + 0.6)))
	# stands with a crowd made of coloured dots
	var cimg := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var pal := [Color(0.9, 0.9, 0.9), Color(0.8, 0.2, 0.2), Color(0.2, 0.4, 0.8), Color(0.95, 0.8, 0.3), Color(0.25, 0.25, 0.3), Color(0.8, 0.6, 0.45), Color(0.3, 0.6, 0.4)]
	var rng := RandomNumberGenerator.new(); rng.seed = 11
	for y in 128:
		for x in 128:
			cimg.set_pixel(x, y, pal[rng.randi() % pal.size()] if (x % 2 == 0 and y % 2 == 0) or rng.randf() < 0.25 else Color(0.2, 0.22, 0.27))
	var cm := StandardMaterial3D.new(); cm.albedo_texture = ImageTexture.create_from_image(cimg); cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cm.uv1_scale = Vector3(14, 3, 1); cm.roughness = 1.0
	var wall := TTPlayer.mat(Color(0.2, 0.24, 0.3), 0.9)
	for sx in [-1.0, 1.0]:
		var w := BoxMesh.new(); w.size = Vector3(1.0, 1.6, 150); _mi(w, wall, Vector3(sx * 35, 0.8, 0))
		for tier in 6:
			var b := BoxMesh.new(); b.size = Vector3(4.2, 3.0, 150); _mi(b, cm, Vector3(sx * (38 + tier * 4.0), 1.5 + tier * 2.2, 0))
	for sz in [-1.0, 1.0]:
		var w2 := BoxMesh.new(); w2.size = Vector3(71, 1.6, 1.0); _mi(w2, wall, Vector3(0, 0.8, sz * 75))
		for tier in 5:
			var b2 := BoxMesh.new(); b2.size = Vector3(71, 3.0, 4.2); _mi(b2, cm, Vector3(0, 1.5 + tier * 2.2, sz * (78 + tier * 4.0)))
	# line of scrimmage and first down markers: raised strips with real thickness
	var lm := StandardMaterial3D.new(); lm.albedo_color = Color(0.25, 0.55, 1.0); lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(1.0, 0.86, 0.1); fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var strip := BoxMesh.new(); strip.size = Vector3(HALF_W * 2, 0.1, 0.28)
	los_line = _mi(strip, lm, Vector3.ZERO); first_line = _mi(strip, fm, Vector3.ZERO)
	# ball
	var bm := SphereMesh.new(); bm.radius = 0.3; bm.height = 0.6; bm.radial_segments = 10; bm.rings = 5
	ball = _mi(bm, TTPlayer.mat(Color(0.5, 0.27, 0.12), 0.6), Vector3.ZERO); ball.scale = Vector3(0.8, 0.8, 1.35)
	cam = Camera3D.new(); cam.fov = 48; cam.near = 0.5; cam.far = 500; add_child(cam); cam.position = Vector3(0, 18, -50); cam.look_at(Vector3(0, 0, -20)); cam.current = true

func _digit(img: Image, ch: String, cx: int, cy: int, s: int, rot: int) -> void:
	var bits: String = DIGITS[ch]
	for r in 5:
		for c in 3:
			if bits[r * 3 + c] == "1":
				var ox := (c - 1) * s; var oy := (r - 2) * s
				img.fill_rect(Rect2i(cx - oy * rot - s / 2, cy + ox * rot - s / 2, s, s), Color(0.95, 0.95, 0.95))

func _paint_field() -> void:
	var img := Image.create(512, 1152, false, Image.FORMAT_RGB8)
	var px := func(x: float) -> int: return int(round((x + 32.0) * 8.0))
	var pz := func(z: float) -> int: return int(round((z + 72.0) * 8.0))
	img.fill(Color(0.17, 0.36, 0.2))
	var wpx := int(HALF_W * 16)
	for i in 20:
		img.fill_rect(Rect2i(px.call(-HALF_W), pz.call(-50.0 + i * 5), wpx, 40), Color(0.2, 0.5, 0.24) if i % 2 == 0 else Color(0.23, 0.55, 0.27))
	img.fill_rect(Rect2i(px.call(-HALF_W), pz.call(-60.0), wpx, 80), Color(tm(0).jersey).darkened(0.15))
	img.fill_rect(Rect2i(px.call(-HALF_W), pz.call(50.0), wpx, 80), Color(tm(1).jersey).darkened(0.15))
	var white := Color(0.95, 0.95, 0.95)
	for i in 21:
		var z := -50.0 + i * 5
		var th := 4 if (i == 0 or i == 20) else 2
		img.fill_rect(Rect2i(px.call(-HALF_W), pz.call(z) - th / 2, wpx, th), white)
	for zi in range(-49, 50):
		for hx in [-6.6, 6.1, -HALF_W + 0.3, HALF_W - 1.0]:
			img.fill_rect(Rect2i(px.call(hx), pz.call(zi), 5, 1), white)
	img.fill_rect(Rect2i(px.call(-HALF_W) - 4, pz.call(-60.0) - 4, wpx + 8, 4), white)
	img.fill_rect(Rect2i(px.call(-HALF_W) - 4, pz.call(60.0), wpx + 8, 4), white)
	img.fill_rect(Rect2i(px.call(-HALF_W) - 4, pz.call(-60.0), 4, 960), white)
	img.fill_rect(Rect2i(px.call(HALF_W), pz.call(-60.0), 4, 960), white)
	for z in range(-40, 41, 10):
		var txt := str(50 - abs(z)).pad_zeros(2)
		for k in 2:
			_digit(img, txt[k], px.call(-17.0), pz.call(z) + int((k - 0.5) * 22), 5, 1)
			_digit(img, txt[k], px.call(17.0), pz.call(z) - int((k - 0.5) * 22), 5, -1)
	img.generate_mipmaps()
	field_mat.albedo_texture = ImageTexture.create_from_image(img)

func _build_audio() -> void:
	for n in ["whistle", "cheer", "kick", "click", "hit0", "hit1", "hit2"]:
		var a := AudioStreamPlayer.new(); a.stream = load("res://audio/%s.ogg" % n); a.volume_db = -4.0; add_child(a); sfx[n] = a
	sfx["click"].volume_db = -10.0
	crowd = AudioStreamPlayer.new(); crowd.stream = load("res://audio/crowd.ogg"); crowd.volume_db = -15.0; add_child(crowd)
	music = AudioStreamPlayer.new(); music.stream = load("res://audio/music_title.ogg"); music.volume_db = -9.0; add_child(music)
	if crowd.stream: crowd.stream.loop = true
	if music.stream: music.stream.loop = true

func play_sfx(n: String) -> void:
	if bot: return
	if n == "hit": n = "hit%d" % (randi() % 3)
	if sfx.has(n): sfx[n].play()

func _apply_sound() -> void:
	AudioServer.set_bus_mute(0, not save.sound)
	if hud and hud.sound_btn: hud.sound_btn.text = "Sound: On" if save.sound else "Sound: Off"

func _load_save() -> void:
	if FileAccess.file_exists("user://tiny_titans.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("user://tiny_titans.json"))
		if d is Dictionary:
			for k in d: save[k] = d[k]

func _write_save() -> void:
	if bot: return
	var f := FileAccess.open("user://tiny_titans.json", FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(save))

func _spawn_players() -> void:
	for side in 2:
		for i in 11:
			var p := TTPlayer.new(); p.team = side; add_child(p); players[side].append(p)
	_paint_players()

func _paint_players() -> void:
	for side in 2:
		var t := tm(side)
		for i in 11:
			var p: TTPlayer = players[side][i]
			p.role = OFF_ROLES[i]
			p.build(Color(t.jersey), Color(t.helmet), Color(t.pants), 1.22 if i < 4 else (1.12 if i == 4 else 1.0))

# ---------------------------------------------------------------- flow

func goto_title() -> void:
	state = St.TITLE
	hud.title_panel.visible = true; hud.team_panel.visible = false; hud.over_panel.visible = false; hud.hide_call(); hud.set_menu(false)
	hud.pad_active = false; hud.meter.visible = false; hud.throw_row.visible = false; hud.menu_btn.visible = false
	hud.score_lbl.get_parent().get_parent().visible = false
	hud.hint.text = ""
	(hud.title_panel.find_child("StartBtn", true, false) as Button).grab_focus.call_deferred()
	crowd.stop()
	if not bot and not music.playing: music.play()
	poss = 0; los = -8.0; ball_x = 0.0; first_z = 2.0
	off_play = plays.offense[1]; def_play = plays.defense[1]
	_place_formation()

func _on_start() -> void:
	state = St.TEAMSEL
	hud.title_panel.visible = false; hud.team_panel.visible = true
	var g = hud.team_panel.find_child("Teams", true, false)
	(g.get_child(clampi(int(save.team), 0, 3)) as Button).grab_focus.call_deferred()

func start_game(team: int, practice_mode: bool) -> void:
	practice = practice_mode
	team_idx[0] = team
	var others := []
	for i in teams.size():
		if i != team: others.append(i)
	team_idx[1] = others[randi() % others.size()]
	save.team = team; _write_save()
	_paint_players(); _paint_field()
	score = [0, 0]
	for s in 2: stats[s] = {"yards": 0.0, "to": 0, "plays": 0, "td": 0}
	events = {"td": 0, "fg": 0, "int": 0, "punt": 0, "sack": 0, "plays": 0, "inc": 0, "comp": 0, "safety": 0, "downs": 0, "fumble": 0}
	quarter = 1; clock = QLEN; opening_receiver = 0
	hud.team_panel.visible = false; hud.title_panel.visible = false; hud.over_panel.visible = false
	hud.menu_btn.visible = true; hud.score_lbl.get_parent().get_parent().visible = true
	music.stop()
	if not bot: crowd.play()
	_kickoff_to(0)
	if practice:
		los = -20.0; first_z = -10.0
		hud.say("Practice: run any play", 2.5)
	else:
		hud.say("%s vs %s" % [tm(0).name, tm(1).name], 2.5)
	goto_playcall()

func _kickoff_to(side: int) -> void:
	poss = side; los = -25.0 * dirv(side); ball_x = 0.0; down_n = 1; first_z = los + 10.0 * dirv(side)

func _flip(spot_z: float, x: float) -> void:
	poss = 1 - poss
	var d := dirv(poss)
	if spot_z * d < -(GOAL - 1.0): spot_z = -(GOAL - 20.0) * d      # touchback
	los = spot_z; ball_x = clampf(x, -6.0, 6.0); down_n = 1
	first_z = los + 10.0 * d
	if first_z * d > GOAL: first_z = GOAL * d

func ord_txt(n: int) -> String:
	return ["1st", "2nd", "3rd", "4th"][clampi(n - 1, 0, 3)]

func yard_txt() -> String:
	var y := los * dirv(poss)
	if absf(y) < 0.5: return "the 50"
	var own := y < 0
	var who: String = tm(poss).abbr if own else tm(1 - poss).abbr
	return "%s %d" % [who, int(round(50.0 - absf(y)))]

func _update_hud() -> void:
	var d := dirv(poss)
	if practice:
		hud.score_lbl.text = "PRACTICE  %s" % tm(0).name
	else:
		hud.score_lbl.text = "%s %d   %s %d    Q%d %d:%02d" % [tm(0).abbr, score[0], tm(1).abbr, score[1], quarter, int(clock) / 60, int(clock) % 60]
	var togo := (first_z - los) * d
	var tg := "Goal" if absf(first_z) >= GOAL - 0.01 else str(maxi(1, int(round(togo))))
	hud.info_lbl.text = "%s ball  %s & %s at %s" % [tm(poss).abbr, ord_txt(down_n), tg, yard_txt()]
	hud.burst_bar.visible = state == St.LIVE and ctrl != null
	if ctrl: hud.burst_bar.value = ctrl.burst

func fg_dist() -> float:
	return (GOAL - los * dirv(poss)) + 17.0

func goto_playcall() -> void:
	state = St.PLAYCALL
	hud.pad_active = false; hud.throw_row.visible = false; hud.meter.visible = false
	off_play = plays.offense[0]; def_play = plays.defense[1]
	_place_formation()
	_update_hud()
	if bot:
		_resolve_cpu_call(); return
	if poss == 0:
		var cards := []
		for p in plays.offense: cards.append({"id": p.id, "name": p.name, "play": p, "kind": "off", "tip": ""})
		if not practice:
			if down_n == 4: cards.append({"id": "punt", "name": "Punt", "play": null, "kind": "special", "tip": "Kick it away"})
			if fg_dist() <= 57.0: cards.append({"id": "fg", "name": "Field Goal", "play": null, "kind": "special", "tip": "%d yard kick" % int(fg_dist())})
		def_play = _cpu_def_choice()
		hud.show_call("%s & %s. Pick a play" % [ord_txt(down_n), hud.info_lbl.text.get_slice("& ", 1)], cards, plays.formation, plays.defense_formation)
		hud.hint.text = "Tap a play, or press its number"
	else:
		var c = _cpu_off_choice()
		if c is String:
			_do_special(c); return
		off_play = c
		var cards2 := []
		for p in plays.defense: cards2.append({"id": p.id, "name": p.name, "play": p, "kind": "def", "tip": p.tip})
		hud.show_call("Defense. %s & %s" % [ord_txt(down_n), hud.info_lbl.text.get_slice("& ", 1)], cards2, plays.formation, plays.defense_formation)
		hud.hint.text = "Tap a defense, or press its number"

func _resolve_cpu_call() -> void:
	var c = _cpu_off_choice()
	if c is String:
		_do_special(c); return
	off_play = c; def_play = _cpu_def_choice()
	setup_play()

func _cpu_off_choice():
	var d := dirv(poss)
	var togo := (first_z - los) * d
	var to_goal := GOAL - los * d
	if not practice:
		if down_n == 4:
			if fg_dist() <= 50.0: return "fg"
			if not (togo <= 2.0 and to_goal < 55.0): return "punt"
		if clock < 13.0 and (quarter == 2 or (quarter == 4 and score[poss] <= score[1 - poss] and score[1 - poss] - score[poss] <= 3)) and fg_dist() <= 54.0:
			return "fg"
	var pp := 0.55
	if togo >= 8.0: pp = 0.72
	if togo <= 2.0: pp = 0.3
	if down_n >= 3 and togo >= 5.0: pp = 0.88
	var want_t := "pass" if randf() < pp else "run"
	var opts := []
	for p in plays.offense:
		if p.type == want_t: opts.append(p)
	if want_t == "pass" and togo >= 12.0 and randf() < 0.5: return plays.offense[1]
	return opts[randi() % opts.size()]

func _cpu_def_choice() -> Dictionary:
	var togo := (first_z - los) * dirv(poss)
	var r := randf()
	if togo <= 2.0: return plays.defense[3] if r < 0.6 else plays.defense[0]
	if togo >= 8.0: return plays.defense[1] if r < 0.5 else (plays.defense[0] if r < 0.8 else plays.defense[2])
	return plays.defense[int(r * 4.0) % 4]

func _on_play_chosen(id: String) -> void:
	if state != St.PLAYCALL: return
	hud.hide_call(); get_viewport().gui_release_focus()
	if id == "punt" or id == "fg":
		_do_special(id); return
	for p in plays.offense:
		if p.id == id: off_play = p
	for p in plays.defense:
		if p.id == id: def_play = p
	setup_play()

func _do_special(id: String) -> void:
	hud.hide_call()
	if id == "fg":
		_start_kick(false); return
	var d := dirv(poss)
	var dist := randf_range(34.0, 46.0)
	var spot := los + dist * d
	events.punt += 1
	play_sfx("kick")
	var txt := "%s punt, %d yards" % [tm(poss).abbr, int(dist)]
	if spot * d >= GOAL - 0.5:
		spot = (GOAL - 20.0) * d; txt = "%s punt. Touchback" % tm(poss).abbr
	if not practice: clock = maxf(0.0, clock - 8.0)
	_flip(spot, 0.0)
	_place_formation()
	hud.say(txt, 2.2)
	state = St.DEAD; dead_t = 2.2; pending = "play"

func fw(x: float, z: float) -> Vector3:
	var d := dirv(poss)
	return Vector3(clampf(ball_x - x * d, -HALF_W + 1.2, HALF_W - 1.2), 0, clampf(los + z * d, -END + 1.0, END - 1.0))

func _place_formation() -> void:
	roles = [{}, {}]
	var d := dirv(poss)
	for i in 11:
		var o: TTPlayer = players[poss][i]
		o.reset_play(); o.role = OFF_ROLES[i]; o.side = "off"; roles[poss][o.role] = o
		o.top_speed = SPEED[o.role] * tm(poss).speed
		var a: Array = plays.formation[o.role]
		o.position = fw(a[0], a[1]); o.home = o.position; o.face = Vector3(0, 0, d)
		var q: TTPlayer = players[1 - poss][i]
		q.reset_play(); q.role = DEF_ROLES[i]; q.side = "def"; roles[1 - poss][q.role] = q
		q.top_speed = SPEED[q.role] * tm(1 - poss).speed
		var b: Array = def_play.get("align", {}).get(q.role, plays.defense_formation[q.role])
		q.position = fw(b[0], b[1]); q.home = q.position; q.face = Vector3(0, 0, -d)
	carrier = R(poss, "QB"); ball_state = "held"; ball_target = null; ctrl = null
	los_line.position = Vector3(0, 0.05, los); first_line.position = Vector3(0, 0.05, first_z)
	first_line.visible = absf(first_z) < GOAL - 0.01
	for side in 2:
		for p in players[side]: (p as TTPlayer).step(0.0, false)
	_ball_follow()
	cam_focus = Vector3(ball_x, 0, los)

func setup_play() -> void:
	_place_formation()
	state = St.PRESNAP; presnap_t = 0.0
	hud.hide_call()
	if human():
		hud.pad_active = true; hud.reset_touch()
		if poss == 0: _set_ctrl(R(0, "QB") if off_play.type == "pass" else R(0, "RB"))
		else: _set_ctrl(R(0, "LB2"))
		hud.hint.text = "Snap: Space, A or the Snap button" if poss == 0 else "Get ready. Switch player: Tab or Snap"
	_update_hud()

func _set_ctrl(p: TTPlayer) -> void:
	if ctrl: ctrl.set_ring(false)
	ctrl = p
	if ctrl: ctrl.set_ring(true)

func snap() -> void:
	state = St.LIVE; live_t = 0.0; handed = false; pursue = false
	qb_t = randf_range(1.5, 2.7)
	var d := dirv(poss)
	var is_pass: bool = off_play.type == "pass"
	events.plays += 1; stats[poss].plays += 1
	for i in 11:
		var o: TTPlayer = players[poss][i]
		o.job = "passblock" if is_pass else "runblock"
		if o.role == "QB": o.job = "qb"
		elif o.role == "RB" and not is_pass:
			o.job = "carry"; o.route = [fw(off_play.aim[0], off_play.aim[1])]
		if is_pass and off_play.routes.has(o.role):
			o.job = "route"; o.route = []
			var a: Array = plays.formation[o.role]
			for pt in off_play.routes[o.role].pts:
				o.route.append(fw(a[0] + pt[0], a[1] + pt[1]))
			o.route_stop = off_play.routes[o.role].get("stop", false)
		var q: TTPlayer = players[1 - poss][i]
		var j: String = def_play.jobs.get(q.role, "rush")
		q.react_t = randf_range(0.1, 0.3)
		if j == "rush": q.job = "rush"
		elif j.begins_with("man:"):
			q.job = "man"; q.man = R(poss, j.substr(4))
		else:
			q.job = "zone"; var zz := j.substr(5).split(","); q.zone_spot = fw(float(zz[0]), float(zz[1]))
	hud.hint.text = ""
	get_viewport().gui_release_focus()

# ---------------------------------------------------------------- input

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		pad_last = false
		match e.physical_keycode:
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER: just["a"] = true
			KEY_E: just["b"] = true
			KEY_Q: just["c"] = true
			KEY_TAB: just["switch"] = true
			KEY_ESCAPE: just["menu"] = true
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				just["n%d" % (e.physical_keycode - KEY_1)] = true
	elif e is InputEventJoypadButton and e.pressed:
		pad_last = true
		match e.button_index:
			JOY_BUTTON_A: just["ja"] = true
			JOY_BUTTON_B: just["jb"] = true
			JOY_BUTTON_X: just["jx"] = true
			JOY_BUTTON_Y: just["jy"] = true
			JOY_BUTTON_START, JOY_BUTTON_BACK: just["menu"] = true
			JOY_BUTTON_LEFT_SHOULDER: just["switch"] = true

func _move_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT): v.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT): v.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP): v.y += 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN): v.y -= 1
	var j := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), -Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if j.length() > 0.22: v += j
	v += Vector2(hud.stick.x, -hud.stick.y)
	return v.limit_length(1.0)

func _sprint_held() -> bool:
	return Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_SHIFT) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.4 \
		or hud.btn_held["A"] or (Input.is_joy_button_pressed(0, JOY_BUTTON_A) and not _can_throw())

func _can_throw() -> bool:
	return state == St.LIVE and user_off() and off_play.type == "pass" and ball_state == "held" and carrier != null and carrier.role == "QB" \
		and ctrl == carrier and (carrier.position.z - los) * dirv(poss) < 0.5 and not carrier.down

func _on_world_tap(pos: Vector2) -> void:
	if state == St.KICK:
		just["a"] = true; return
	if not _can_throw(): return
	var best := -1; var bd := 95.0
	for i in off_play.targets.size():
		var r := R(poss, off_play.targets[i])
		if r == null: continue
		var sp := cam.unproject_position(r.position + Vector3(0, 1.5, 0))
		if sp.distance_to(pos) < bd:
			bd = sp.distance_to(pos); best = i
	if best >= 0: _user_throw(best)

func _user_throw(i: int) -> void:
	if not _can_throw() or i >= off_play.targets.size(): return
	var r := R(poss, off_play.targets[i])
	if r and not r.down: throw_to(r, 0.6 if carrier.vel.length() > 5.0 else 0.0)

func _on_menu(action: String) -> void:
	match action:
		"click": play_sfx("click")
		"toggle":
			if state in [St.TITLE, St.TEAMSEL, St.OVER]: return
			hud.set_menu(not hud.menu_open)
		"resume": hud.set_menu(false)
		"help": hud.show_help(true)
		"help_close": hud.show_help(false)
		"sound":
			save.sound = not save.sound; _apply_sound(); _write_save()
		"restart":
			hud.set_menu(false); start_game(team_idx[0], practice)
		"title":
			hud.set_menu(false); goto_title()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST: just["menu"] = true      # Android Back opens the menu

# ---------------------------------------------------------------- loop

func _process(dt: float) -> void:
	if bot or fast:
		for i in (40 if bot else 3): tick(1.0 / 30.0)
	else:
		# slow devices: keep real time by taking up to three smaller steps per frame
		dt = minf(dt, 0.12)
		var n := clampi(int(ceil(dt / 0.04)), 1, 3)
		for i in n: tick(dt / n)
	if test_hook:
		JavaScriptBridge.eval("window.ttf={state:%d,poss:%d,down:%d,q:%d,clock:%d,s0:%d,s1:%d,ball:'%s',ctrl:'%s'}" % [state, poss, down_n, quarter, int(clock), score[0], score[1], ball_state, (ctrl.role if ctrl else "")], true)

func tick(dt: float) -> void:
	if just.get("menu", false) and not bot:
		if hud.help_panel.visible: hud.show_help(false)
		else: _on_menu("toggle")
	if hud.menu_open or hud.help_panel.visible:
		just.clear(); hud.clear_just(); return
	match state:
		St.PLAYCALL:
			var cards: Array = hud.call_ids()
			for i in cards.size():
				if just.get("n%d" % i, false): (cards[i] as Button).pressed.emit()
		St.PRESNAP: _presnap(dt)
		St.LIVE: _live(dt)
		St.DEAD: _dead(dt)
		St.KICK: _kick(dt)
	if state != St.LIVE:
		for side in 2:
			for p in players[side]:
				(p as TTPlayer).want = Vector3.ZERO; (p as TTPlayer).step(dt, false)
	_ball_follow()
	_update_camera(dt)
	_update_tags()
	_update_hud()
	just.clear(); hud.clear_just()

func _a_just() -> bool:
	return just.get("a", false) or just.get("ja", false) or hud.btn_just["A"]

func _presnap(dt: float) -> void:
	presnap_t += dt
	if user_off():
		if _a_just() and presnap_t > 0.25: snap()
	elif human():
		if (just.get("switch", false) or _a_just()): _switch_defender()
		if presnap_t > 1.7: snap()
	elif presnap_t > 0.3: snap()

func _switch_defender() -> void:
	var tgt := ball_to if ball_state == "air" else (carrier.position if carrier else Vector3(ball_x, 0, los))
	var best: TTPlayer = null; var bd := 999.0
	for p in players[0]:
		var q: TTPlayer = p
		if q == ctrl or q.down: continue
		var dd := q.position.distance_to(tgt)
		if q.engaged != null: dd += 6.0
		if dd < bd:
			bd = dd; best = q
	if best: _set_ctrl(best)

func _live(dt: float) -> void:
	live_t += dt
	if not practice: clock = maxf(0.0, clock - dt)
	var d := dirv(poss)
	var is_pass: bool = off_play.type == "pass"
	if not is_pass and not handed and live_t >= 0.55:
		handed = true; carrier = R(poss, "RB")
	var run_now := ball_state == "held" and carrier != null and ((is_pass and (carrier.role != "QB" or (carrier.position.z - los) * d > 0.3)) or (not is_pass and live_t > 0.7))
	if run_now and not pursue:
		pursue = true
		for p in players[1 - poss]:
			if (p as TTPlayer).job != "rush": (p as TTPlayer).react_t = randf_range(0.08, 0.3)
	var user: TTPlayer = ctrl if human() else null
	for p in players[poss]:
		if p != user: _ai_off(p, d, is_pass)
	for p in players[1 - poss]:
		if p != user: _ai_def(p, dt, d)
	if not user_off(): _cpu_qb(d, is_pass)
	_engagements(dt, d, is_pass)
	if user: _user_live(user, d)
	for side in 2:
		for p in players[side]:
			var q: TTPlayer = p
			q.step(dt, true)
			if q != carrier:
				q.position.x = clampf(q.position.x, -HALF_W - 2.5, HALF_W + 2.5); q.position.z = clampf(q.position.z, -END - 2.0, END + 2.0)
	_separate()
	if ball_state == "air":
		ball_t += dt
		if ball_t >= ball_T: _resolve_pass()
	if state != St.LIVE: return
	if carrier and ball_state == "held":
		for p in players[1 - poss]:
			var q: TTPlayer = p
			if q.down or q.stun_t > 0.0 or q.engaged != null or q.tackle_cd > 0.0: continue
			var reach := 1.75 if q.dive_t > 0.0 else 1.25
			if q.position.distance_to(carrier.position) < reach:
				_try_tackle(q)
				if state != St.LIVE: return
		var cz := carrier.position.z * d
		if cz >= GOAL: end_play("td")
		elif absf(carrier.position.x) > HALF_W or cz < -END: end_play("oob")
		elif carrier.down: end_play("tackle")
	if state == St.LIVE and live_t > 25.0: end_play("tackle")

func _user_live(u: TTPlayer, d: float) -> void:
	var mv := _move_input()
	var wdir := Vector3(-mv.x, 0, mv.y)      # the camera always looks down +Z for the player
	u.sprinting = _sprint_held()
	var sp := u.speed_now()
	if u.engaged != null: sp *= 0.2
	u.want = wdir * sp
	if u.side == "off":
		if _can_throw():
			var t := -1
			for i in 4:
				if just.get("n%d" % i, false): t = i
			if just.get("ja", false): t = 0
			if just.get("jb", false): t = 1
			if just.get("jx", false): t = 2
			if just.get("jy", false): t = 3
			if t >= 0: _user_throw(t)
		elif u == carrier:
			if (just.get("b", false) or just.get("jb", false) or hud.btn_just["B"]) and u.juke_cd <= 0.0:
				var sx := -signf(mv.x) if absf(mv.x) > 0.2 else (1.0 if randf() < 0.5 else -1.0)
				_juke(u, sx, d)
			if (just.get("c", false) or just.get("jx", false) or hud.btn_just["C"]) and u.dive_t <= 0.0 and not u.down:
				u.dive_t = 0.25; u.vel = (u.face if u.vel.length() > 1.0 else Vector3(0, 0, d)) * 12.5
	else:
		if just.get("switch", false) or _a_just(): _switch_defender()
		if (just.get("c", false) or just.get("jx", false) or hud.btn_just["C"]) and u.dive_t <= 0.0 and not u.down and u.engaged == null:
			var tgt := carrier.position if carrier else ball_to
			var v := tgt - u.position; v.y = 0
			u.dive_t = 0.24; u.vel = (v.normalized() if v.length() > 0.1 else u.face) * 13.5

func _juke(p: TTPlayer, sx: float, d: float) -> void:
	p.juke_t = 0.22; p.juke_cd = 1.3; p.juke_vec = Vector3(sx * 11.0, 0, d * 5.0)

# ---------------------------------------------------------------- computer players

func _go(p: TTPlayer, target: Vector3, frac := 1.0) -> float:
	var v := target - p.position; v.y = 0
	var dist := v.length()
	p.want = (v / dist) * p.speed_now() * frac if dist > 0.35 else Vector3.ZERO
	return dist

func _nearest_def(pos: Vector3, free_only := false) -> TTPlayer:
	var best: TTPlayer = null; var bd := 999.0
	for p in players[1 - poss]:
		var q: TTPlayer = p
		if q.down or (free_only and (q.engaged != null or q.shed_cd > 0.0)): continue
		var dd := q.position.distance_to(pos)
		if dd < bd:
			bd = dd; best = q
	return best

func _ai_carrier(p: TTPlayer, d: float) -> void:
	p.sprinting = true
	if p.route.size() > 0:
		if _go(p, p.route[0]) < 1.6 or (p.position.z - los) * d > 1.0: p.route.clear()
		return
	var steer := Vector3(0, 0, d)
	var close := 99.0; var close_x := 0.0
	for q0 in players[1 - poss]:
		var q: TTPlayer = q0
		if q.down or q.engaged != null: continue
		var rel := q.position - p.position
		var ahead := rel.z * d
		var dist := rel.length()
		if ahead > -1.5 and dist < 9.0:
			var sx := signf(rel.x) if absf(rel.x) > 0.25 else (1.0 if (p.get_instance_id() % 2) == 0 else -1.0)
			steer.x -= sx * 2.2 / maxf(dist, 1.0)
			if dist < close and ahead > 0.0:
				close = dist; close_x = sx
	if absf(p.position.x) > HALF_W - 3.5: steer.x -= signf(p.position.x) * 1.4
	steer.x = clampf(steer.x, -0.85, 0.85)
	p.want = steer.normalized() * p.speed_now()
	if close < 2.3 and not p.did_cpu_juke and p.juke_cd <= 0.0:
		p.did_cpu_juke = true
		if randf() < 0.22: _juke(p, -close_x, d)

func _ai_off(p0, d: float, is_pass: bool) -> void:
	var p: TTPlayer = p0
	p.sprinting = false
	if p.down or p.stun_t > 0.0: return
	if p == carrier and (p.role != "QB" or not is_pass or (p.position.z - los) * d > 0.3 or live_t > qb_t + 3.0):
		if p.role == "QB" and not is_pass and not handed:
			p.want = Vector3.ZERO; return
		_ai_carrier(p, d); return
	var ball_live_run := ball_state == "held" and carrier != null and carrier != p and (carrier.role != "QB" or not is_pass or (carrier.position.z - los) * d > 0.3)
	match p.job:
		"qb":
			if not is_pass or carrier != p:
				p.want = Vector3.ZERO; return
			var spot := Vector3(p.home.x, 0, los - 7.5 * d)
			var rusher := _nearest_def(p.position, true)
			if rusher and rusher.position.distance_to(p.position) < 5.0:
				var away := p.position - rusher.position; away.y = 0
				spot = p.position + away.normalized() * 3.0; spot.z = clampf(spot.z * d, (los * d) - 11.0, (los * d) - 3.0) * d
			_go(p, spot, 0.8)
		"carry":
			if p.route.size() > 0: _go(p, p.route[0], 0.75)
		"route":
			if ball_state == "air" and ball_target == p:
				_go(p, ball_to); p.sprinting = true
			elif ball_live_run or (ball_state == "air" and ball_target != p):
				_block_ai(p, d)
			elif p.route.size() > 0:
				var before := p.position
				if _go(p, p.route[0]) < 0.9:
					p.route_dir = (p.route[0] - (p.home if p.route_dir == Vector3.ZERO else before)).normalized()
					var last: Vector3 = p.route[0]
					p.route.remove_at(0)
					if p.route.size() == 0: p.route_dir = (last - before); p.route_dir.y = 0
					if p.route.size() == 0 and p.route_dir.length() < 0.01: p.route_dir = Vector3(0, 0, d)
					p.route_dir = p.route_dir.normalized()
			elif p.route_stop:
				p.want = Vector3.ZERO
			else:
				var nx := p.position + p.route_dir * 3.0
				if absf(nx.x) > HALF_W - 2.0 or nx.z * d > END - 2.0: p.want = Vector3.ZERO
				else: p.want = p.route_dir * p.speed_now()
		"passblock":
			if ball_live_run or ball_state == "air":
				_block_ai(p, d); return
			var qb := R(poss, "QB")
			var r := _nearest_def(p.position, true)
			var pocket := p.home + Vector3(0, 0, -1.6 * d)
			if r and (r.job == "rush" or r.position.distance_to(qb.position) < 9.0) and r.position.distance_to(p.position) < 7.0:
				var between := r.position + (qb.position - r.position).normalized() * 1.0
				_go(p, between)
			else: _go(p, pocket, 0.6)
		"runblock":
			_block_ai(p, d)

func _block_ai(p: TTPlayer, d: float) -> void:
	if p.engaged != null: return
	var best: TTPlayer = null; var bs := 999.0
	var cpos := carrier.position if carrier else (ball_to if ball_state == "air" else p.position)
	for q0 in players[1 - poss]:
		var q: TTPlayer = q0
		if q.down or q.engaged != null or q.shed_cd > 0.0: continue
		var dd := q.position.distance_to(p.position)
		if dd > 11.0: continue
		var s := dd + q.position.distance_to(cpos) * 0.5
		if s < bs:
			bs = s; best = q
	if best: _go(p, best.position + (cpos - best.position).normalized() * 0.8)
	else: _go(p, cpos + Vector3(0, 0, d * 5.0), 0.8)

func _ai_def(p0, dt: float, d: float) -> void:
	var p: TTPlayer = p0
	p.sprinting = false
	if p.down or p.stun_t > 0.0 or p.engaged != null: return
	if p.react_t > 0.0: p.react_t -= dt
	if ball_state == "air":
		if p.job == "rush" and p.position.distance_to(ball_to) > 14.0: p.want = p.want * 0.9
		else: _go(p, ball_to)
		return
	if carrier == null: return
	if p.job == "rush" or (pursue and p.react_t <= 0.0):
		var dist := p.position.distance_to(carrier.position)
		var lead := carrier.position + carrier.vel * clampf(dist / maxf(p.top_speed, 1.0), 0.0, 1.4)
		_go(p, lead); p.sprinting = dist < 12.0
		return
	match p.job:
		"man":
			var m := p.man
			if m == null or m.job == "passblock" or m.job == "carry":
				_go(p, Vector3(clampf(carrier.position.x, -8, 8), 0, los + 4.0 * d), 0.7)
			else:
				_go(p, m.position + m.vel * 0.3 + Vector3(0, 0, d * 0.9))
		"zone":
			var tgt := p.zone_spot
			var best: TTPlayer = null; var bd := 9.5
			for r0 in players[poss]:
				var r: TTPlayer = r0
				if r.job != "route": continue
				var dd := r.position.distance_to(p.zone_spot)
				if dd < bd:
					bd = dd; best = r
			if best: tgt = p.zone_spot.lerp(best.position + Vector3(0, 0, d * 1.6), 0.72)
			var zdepth := (p.zone_spot.z - los) * d
			if zdepth >= 14.0:      # deep zones stay over the top of the deepest receiver on their side
				var deep: TTPlayer = null; var dz := zdepth - 7.0
				for r0 in players[poss]:
					var r: TTPlayer = r0
					if r.job != "route" or absf(r.position.x - p.zone_spot.x) > 17.0: continue
					if (r.position.z - los) * d > dz:
						dz = (r.position.z - los) * d; deep = r
				if deep: tgt = Vector3(lerpf(p.zone_spot.x, deep.position.x, 0.8), 0, los + maxf(zdepth, dz + 3.0) * d)
			_go(p, tgt, 0.92)

func _cpu_qb(d: float, is_pass: bool) -> void:
	if not is_pass or ball_state != "held" or carrier == null or carrier.role != "QB": return
	var qb := carrier
	if qb.down or (qb.position.z - los) * d > 0.3: return
	var rusher := _nearest_def(qb.position, true)
	var pressure := rusher.position.distance_to(qb.position) if rusher else 99.0
	if live_t < 0.9: return
	if live_t < qb_t and pressure > 3.2: return
	var best: TTPlayer = null; var bo := -99.0
	for role in off_play.targets:
		var r := R(poss, role)
		if r == null or r.down: continue
		var nd := _nearest_def(r.position)
		var open := (nd.position.distance_to(r.position) if nd else 20.0) - qb.position.distance_to(r.position) * 0.05
		if (r.position.z - los) * d < -1.0: open -= 2.0
		if open > bo:
			bo = open; best = r
	if best and (bo > 1.6 or live_t > qb_t + 1.0 or pressure < 3.2):
		throw_to(best, 1.6 if pressure < 3.2 else 0.5)

func _engagements(dt: float, d: float, is_pass: bool) -> void:
	for b0 in players[poss]:
		var b: TTPlayer = b0
		if b == carrier or b.down or b.stun_t > 0.0 or b.engaged != null: continue
		if not (b.job == "passblock" or b.job == "runblock" or (b.job == "route" and (ball_state != "held" or carrier == null or carrier.role != "QB") and ball_target != b)): continue
		for q0 in players[1 - poss]:
			var q: TTPlayer = q0
			if q.down or q.engaged != null or q.shed_cd > 0.0 or q.stun_t > 0.0 or q.dive_t > 0.0: continue
			if q.position.distance_to(b.position) < 1.4:
				b.engaged = q; q.engaged = b
				var big := b.role in ["LT", "LG", "C", "RG", "RT", "TE"]
				q.block_t = (randf_range(2.6, 4.4) if big else randf_range(0.9, 1.8)) if is_pass and not pursue else (randf_range(0.9, 1.9) if big else randf_range(0.4, 0.9))
				q.block_t *= float(tm(poss).power) / float(tm(1 - poss).power)
				break
	for q0 in players[1 - poss]:
		var q: TTPlayer = q0
		if q.engaged == null: continue
		var b: TTPlayer = q.engaged
		q.block_t -= dt * (1.8 if q == ctrl and human() else 1.0)
		if carrier and ball_state == "held" and pursue and q.position.distance_to(carrier.position) < 2.4: q.block_t -= dt * 2.0
		if q.block_t <= 0.0 or b.down or q.down:
			q.engaged = null; b.engaged = null; q.shed_cd = 3.0; b.stun_t = maxf(b.stun_t, 0.5)
			continue
		var push := Vector3(0, 0, d * 1.1)
		if is_pass and not pursue and carrier:
			push = (carrier.position - q.position); push.y = 0; push = push.normalized() * 0.9
		q.want = push; b.want = push
		var gap := b.position - q.position; gap.y = 0
		if gap.length() > 1.25: b.want += -gap.normalized() * 3.0

func _separate() -> void:
	var all: Array = players[0] + players[1]
	for i in all.size():
		var a: TTPlayer = all[i]
		if a.down: continue
		for j in range(i + 1, all.size()):
			var b: TTPlayer = all[j]
			if b.down: continue
			var v := b.position - a.position; v.y = 0
			var dist := v.length()
			if dist < 0.95 and dist > 0.001:
				var push := v / dist * (0.95 - dist) * 0.5
				a.position -= push; b.position += push

func _try_tackle(q: TTPlayer) -> void:
	q.tackle_cd = 0.9
	var bc := carrier
	if bc.juke_t > 0.0:
		if randf() < 0.6: q.fall(1.3)
		return
	var p := 0.88 * float(tm(1 - poss).power) / float(tm(poss).power)
	if q.dive_t > 0.0: p += 0.15
	if bc.sprinting and bc.burst > 0.0: p -= 0.04
	if human():
		if bc == ctrl: p -= 0.05
		if q == ctrl: p += 0.12
	if bc.role == "QB" and (bc.position.z - los) * dirv(poss) < 0.0: p += 0.12
	if randf() < p:
		bc.fall(4.0); q.fall(0.8); play_sfx("hit")
		if randf() < 0.008 and bc.role != "QB":
			end_play("fumble")
		else:
			end_play("tackle")
	else:
		q.fall(1.2); play_sfx("hit")
		if human() and bc == ctrl: hud.say("Broken tackle!", 0.9, hud.GOLD)

# ---------------------------------------------------------------- ball

func throw_to(r: TTPlayer, err: float) -> void:
	var qb := carrier
	qb.throw_t = 0.35
	ball_from = qb.position + Vector3(0, 2.0, 0)
	var target := r.position
	var T := 0.6
	var stopped := r.job == "route" and r.route.size() == 0 and r.route_stop
	for i in 3:
		var dist := ball_from.distance_to(target)
		T = maxf(0.42, dist / (20.0 + minf(dist, 32.0) * 0.28))
		target = r.position + (Vector3.ZERO if stopped else r.vel * T * 0.92)
	if err > 0.0: target += Vector3(randf_range(-err, err), 0, randf_range(-err, err))
	target.x = clampf(target.x, -HALF_W + 0.6, HALF_W - 0.6); target.z = clampf(target.z, -END + 0.8, END - 0.8); target.y = 0
	ball_to = target; ball_T = T; ball_t = 0.0; ball_arc = 1.0 + ball_from.distance_to(target) * 0.1
	ball_state = "air"; ball_target = r; carrier = null
	if human() and poss == 1:
		_set_ctrl(null)
		var best: TTPlayer = null; var bd := 999.0
		for p in players[0]:
			var q: TTPlayer = p
			if q.down or q.engaged != null: continue
			if q.position.distance_to(ball_to) < bd:
				bd = q.position.distance_to(ball_to); best = q
		_set_ctrl(best if best else R(0, "LB2"))

func _resolve_pass() -> void:
	var r := ball_target
	var d := dirv(poss)
	var rd := r.position.distance_to(ball_to) if (r and not r.down) else 99.0
	var nd: TTPlayer = null; var dd := 99.0
	for p in players[1 - poss]:
		var q: TTPlayer = p
		if q.down or q.engaged != null: continue
		var x := q.position.distance_to(ball_to)
		if x < dd:
			dd = x; nd = q
	var user_d := human() and nd != null and nd == ctrl
	var pint := 0.0; var pcatch := 0.0
	if rd > 2.1:
		if dd < 1.3: pint = 0.3
	else:
		pcatch = (0.93 - maxf(0.0, ball_from.distance_to(ball_to) - 24.0) * 0.014) * float(tm(poss).hands)
		if dd < 2.3:
			var k := 1.0 - dd / 2.3
			pcatch -= 0.62 * k
			pint = 0.06 * k + (0.07 if dd < rd else 0.0)
	if user_d: pint *= 1.8
	var roll := randf()
	ball_state = "held"
	if roll < pint:
		carrier = nd; end_play("int"); return
	if roll < pint + pcatch:
		carrier = r; r.job = "carry"; r.route = []
		events.comp += 1
		if user_off(): _set_ctrl(r)
		return
	carrier = null; ball_state = "dead"; ball.position = ball_to + Vector3(0, 0.3, 0)
	end_play("incomplete")

func _ball_follow() -> void:
	if state == St.KICK and kick.get("phase", "") == "fly": return
	if ball_state == "air":
		var k := clampf(ball_t / ball_T, 0.0, 1.0)
		ball.position = ball_from.lerp(ball_to + Vector3(0, 1.4, 0), k) + Vector3(0, sin(k * PI) * ball_arc, 0)
		var v := ball_to - ball_from
		ball.rotation.y = atan2(v.x, v.z)
	elif carrier:
		ball.position = carrier.position + Vector3(0, 0.5 if carrier.down else 1.3, 0) + carrier.face * 0.45
		ball.rotation.y = carrier.rotation.y

# ---------------------------------------------------------------- results

func end_play(kind: String) -> void:
	var d := dirv(poss)
	state = St.DEAD; dead_t = 2.3; pending = "play"
	play_sfx("whistle")
	hud.throw_row.visible = false
	var is_pass: bool = off_play.type == "pass"
	var spot := carrier.position.z if carrier else los
	var sx := carrier.position.x if carrier else ball_x
	var msg := ""; var col := Color.WHITE
	if verbose: print("PLAY %s %s vs %s kind %s gain %.1f t %.1f" % [off_play.id, off_play.type, def_play.id, kind, (spot - los) * d, live_t])
	if practice:
		var g := int(round((spot - los) * d))
		match kind:
			"td": msg = "Touchdown!"
			"incomplete": msg = "Incomplete"
			"int": msg = "Intercepted"
			_: msg = "%+d yards" % g
		hud.say(msg, 2.0); los = -20.0; first_z = -10.0; down_n = 1; ball_x = 0.0; poss = 0
		return
	match kind:
		"td":
			score[poss] += 6; events.td += 1; stats[poss].td += 1
			stats[poss].yards += (GOAL - los * d)
			msg = "TOUCHDOWN %s!" % tm(poss).name.to_upper(); col = hud.GOLD
			play_sfx("cheer"); pending = "xp"
			for p in players[poss]: (p as TTPlayer).cheer = true
		"incomplete":
			events.inc += 1; msg = "Incomplete"
			_next_down(los, ball_x)
		"int", "fumble":
			if kind == "int": events["int"] += 1
			else: events.fumble += 1
			stats[poss].to += 1
			msg = ("INTERCEPTED by %s!" if kind == "int" else "FUMBLE! %s ball") % tm(1 - poss).abbr; col = hud.GOLD
			play_sfx("cheer")
			for p in players[1 - poss]: (p as TTPlayer).cheer = true
			_flip(spot, sx)
		"tackle", "oob":
			var gain := (spot - los) * d
			if spot * d <= -GOAL:
				score[1 - poss] += 2; events.safety += 1; msg = "SAFETY! 2 points %s" % tm(1 - poss).abbr; col = hud.GOLD
				pending = "kick%d" % (1 - poss)
			else:
				stats[poss].yards += gain
				var sack := is_pass and carrier != null and carrier.role == "QB" and gain < 0.0
				if sack: events.sack += 1
				msg = ("SACKED! %d yards" % int(round(gain))) if sack else ("%+d yards" % int(round(gain)) if absf(gain) >= 0.5 else "No gain")
				if kind == "oob": msg += ", out of bounds"
				else: clock = maxf(0.0, clock - 15.0)
				var was := down_n
				var note := _next_down(spot, sx)
				if note != "":
					msg += ". " + note
					if note.begins_with("First"): col = hud.GOLD
				elif was < 4: pass
	hud.say(msg, 2.2, col)

func _next_down(spot: float, x: float) -> String:
	var d := dirv(poss)
	los = spot; ball_x = clampf(x, -6.0, 6.0)
	if (los - first_z) * d >= -0.01:
		down_n = 1; first_z = los + 10.0 * d
		if first_z * d > GOAL: first_z = GOAL * d
		return "First down!"
	down_n += 1
	if down_n > 4:
		events.downs += 1; stats[poss].to += 1
		_flip(los, ball_x)
		return "Turnover on downs"
	return ""

func _dead(dt: float) -> void:
	dead_t -= dt * (6.0 if bot else 1.0)
	if dead_t > 0.0: return
	if pending == "xp":
		_start_kick(true); return
	if not practice and clock <= 0.0:
		if quarter >= 4:
			_game_over(); return
		quarter += 1; clock = QLEN
		if quarter == 3:
			_kickoff_to(1 - opening_receiver); pending = "play"
			hud.say("Halftime. %s ball" % tm(poss).abbr, 2.4)
		else:
			hud.say("End of quarter %d" % (quarter - 1), 1.8)
	if pending.begins_with("kick"):
		_kickoff_to(int(pending.substr(4)))
	pending = "play"
	goto_playcall()

func _game_over() -> void:
	state = St.OVER
	hud.pad_active = false; hud.hide_call(); hud.hint.text = ""
	var res := "Tie game"
	if score[0] > score[1]:
		res = "You win!"; save.wins += 1
	elif score[0] < score[1]:
		res = "%s win" % tm(1).name; save.losses += 1
	else: save.ties += 1
	_write_save()
	var t := "%s %d\n%s %d\n\n%s\n\nYards: %d to %d    Turnovers: %d to %d\nYour record: %d wins, %d losses, %d ties" % [tm(0).name, score[0], tm(1).name, score[1], res,
		int(stats[0].yards), int(stats[1].yards), stats[0].to, stats[1].to, save.wins, save.losses, save.ties]
	if bot:
		bot_done += 1
		print("BOT game %d final %d-%d plays %d yards %d/%d events %s" % [bot_done, score[0], score[1], events.plays, int(stats[0].yards), int(stats[1].yards), JSON.stringify(events)])
		if bot_done >= bot_games:
			print("BOT done games %d" % bot_done); get_tree().quit()
		else: start_game(bot_done % 4, false)
		return
	play_sfx("cheer")
	hud.show_over(t)
	if not music.playing: music.play()

# ---------------------------------------------------------------- kicks

func _start_kick(xp: bool) -> void:
	var d := dirv(poss)
	if xp:
		los = (GOAL - 15.0) * d; ball_x = 0.0; first_z = GOAL * d
	off_play = plays.offense[4]; def_play = plays.defense[3]
	_place_formation()
	var origin := Vector3(ball_x, 0.3, los - 7.0 * d)
	var dist := (GOAL - los * d) + 17.0
	kick = {"phase": "aim", "t": 0.0, "xp": xp, "dist": dist, "from": origin, "good": false, "fly": 0.0, "to": Vector3.ZERO}
	state = St.KICK; carrier = null; ball_state = "dead"; ball.position = origin
	hud.hide_call(); hud.pad_active = human()
	if user_off():
		hud.meter.visible = true; hud.meter_half = clampf(0.2 - dist * 0.0028, 0.045, 0.16)
		hud.hint.text = "%s: stop the marker in the green. Space, A or tap" % ("Extra point" if xp else "%d yard field goal" % int(dist))
	else:
		kick.good = randf() < clampf(1.12 - dist * 0.012, 0.25, 0.97)
		kick.t = -0.9

func _kick(dt: float) -> void:
	var d := dirv(poss)
	if kick.phase == "aim":
		kick.t += dt
		if user_off():
			hud.meter_pos = 0.5 + 0.5 * sin(kick.t * (3.0 + kick.dist * 0.035))
			if (_a_just() or hud.btn_just["B"] or hud.btn_just["C"]) and kick.t > 0.3:
				kick.good = absf(hud.meter_pos - 0.5) <= hud.meter_half
				kick.t = 99.0
		if (user_off() and kick.t >= 99.0) or (not user_off() and kick.t >= 0.0):
			kick.phase = "fly"; kick.fly = 0.0; hud.meter.visible = false; hud.hint.text = ""
			play_sfx("kick")
			var miss_x := (1.0 if randf() < 0.5 else -1.0) * randf_range(4.6, 8.0)
			kick.to = Vector3(randf_range(-1.6, 1.6) if kick.good else miss_x, 6.5, (END + 0.6) * d)
	elif kick.phase == "fly":
		kick.fly += dt / 1.5 * (5.0 if bot else 1.0)
		var k: float = clampf(kick.fly, 0.0, 1.0)
		ball.position = (kick.from as Vector3).lerp(kick.to, k) + Vector3(0, sin(k * PI) * 8.0, 0)
		ball.rotation.x += dt * 14.0
		if k >= 1.0:
			kick.phase = "done"; ball.rotation.x = 0.0
			state = St.DEAD; dead_t = 1.9
			if kick.xp:
				if kick.good: score[poss] += 1
				hud.say("Extra point is good!" if kick.good else "Extra point missed", 1.8)
				pending = "kick%d" % (1 - poss)
			elif kick.good:
				score[poss] += 3; events.fg += 1
				hud.say("FIELD GOAL %s! %d yards" % [tm(poss).abbr, int(kick.dist)], 2.0, hud.GOLD); play_sfx("cheer")
				pending = "kick%d" % (1 - poss)
			else:
				hud.say("No good!", 1.8)
				var spot := los
				if GOAL - los * d < 20.0: spot = (GOAL - 20.0) * d
				_flip(spot, 0.0); pending = "play"
			clock = maxf(0.0, clock - (0.0 if kick.xp else 5.0))

# ---------------------------------------------------------------- camera and labels

func _update_camera(dt: float) -> void:
	var focus := Vector3(ball_x, 0, los)
	var h := 15.0; var back := 20.0
	if state == St.LIVE or state == St.DEAD:
		if ball_state == "air": focus = ball.position; focus.y = 0
		elif carrier: focus = carrier.position
		if state == St.LIVE and off_play.type == "pass" and carrier != null and carrier.role == "QB":
			h = 21.0; back = 23.0; focus = Vector3(ball_x * 0.6 + carrier.position.x * 0.4, 0, los)
	elif state == St.PRESNAP or state == St.PLAYCALL:
		h = 19.0; back = 22.0
	elif state == St.KICK:
		focus = Vector3(0, 0, los + 10.0 * dirv(poss)); h = 14.0; back = 24.0
	elif state == St.TITLE or state == St.TEAMSEL or state == St.OVER:
		h = 11.0; back = 30.0; focus = Vector3(sin(Time.get_ticks_msec() * 0.0001) * 8.0, 0, los)
	if human() and poss == 1 and state in [St.PRESNAP, St.LIVE, St.PLAYCALL, St.DEAD]: back += 7.0
	cam_focus = cam_focus.lerp(focus, minf(1.0, dt * 5.0))
	var want_pos := Vector3(cam_focus.x * 0.92, h, cam_focus.z - back)
	cam.position = cam.position.lerp(want_pos, minf(1.0, dt * 4.0))
	cam.look_at(Vector3(cam_focus.x * 0.96, 0, cam_focus.z + 6.0), Vector3.UP)

func _update_tags() -> void:
	var show: bool = (state == St.PRESNAP or state == St.LIVE) and user_off() and off_play.type == "pass" and ball_state == "held" and carrier != null and carrier.role == "QB"
	var names := ["A", "B", "X", "Y"] if pad_last else ["1", "2", "3", "4"]
	for p in players[0]: (p as TTPlayer).set_tag("")
	if show and off_play.has("targets"):
		for i in off_play.targets.size():
			var r := R(0, off_play.targets[i])
			if r: r.set_tag(names[i])
	hud.throw_row.visible = hud.touch_seen and _can_throw()
	if human() and state == St.LIVE and ctrl != null:
		hud.pad.labels = {"A": "Sprint" if ctrl.side == "off" else "Switch", "B": "Juke" if ctrl.side == "off" else "", "C": "Dive" if ctrl.side == "off" else "Tackle"}
	elif state == St.KICK:
		hud.pad.labels = {"A": "Kick", "B": "", "C": ""}
	else:
		hud.pad.labels = {"A": "Snap" if poss == 0 else "Switch", "B": "", "C": ""}
