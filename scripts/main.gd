extends Node3D
# Tiny Titans Football. Arcade 11 on 11 football: call a play, then run it.
# Rules, flow, kicks, returns, computer players, camera, input, sound and saves live here.
# Plays and teams are data (data/*.json). Players are drawn by SquadView.
# Field units are yards. The field runs along Z: goal lines at z = -50 and z = +50. Side 0 (the player) attacks +Z.

const VERSION: String = "0.2.0"
const HALF_W: float = 26.65
const GOAL: float = 50.0
const END: float = 60.0
const QLEN: float = 120.0
const SAVE_PATH: String = "user://tiny_titans.json"
const OFF_ROLES: Array[String] = ["LT", "LG", "C", "RG", "RT", "QB", "RB", "TE", "WR1", "WR2", "WR3"]
const DEF_ROLES: Array[String] = ["DE1", "DT1", "DT2", "DE2", "LB2", "LB1", "LB3", "S1", "CB1", "CB2", "S2"]
const SPEED: Dictionary = {"QB": 7.8, "RB": 9.0, "TE": 8.3, "WR1": 9.4, "WR2": 9.4, "WR3": 9.2, "LT": 6.2, "LG": 6.2, "C": 6.2, "RG": 6.2, "RT": 6.2,
	"DE1": 7.4, "DE2": 7.4, "DT1": 6.8, "DT2": 6.8, "LB1": 8.7, "LB2": 8.6, "LB3": 8.7, "CB1": 9.55, "CB2": 9.55, "S1": 9.4, "S2": 9.3}
const NUMBERS: Dictionary = {"LT": 72, "LG": 64, "C": 55, "RG": 66, "RT": 78, "QB": 12, "RB": 28, "TE": 88, "WR1": 11, "WR2": 84, "WR3": 17,
	"DE1": 91, "DT1": 97, "DT2": 93, "DE2": 99, "LB2": 54, "LB1": 52, "LB3": 58, "S1": 21, "CB1": 24, "CB2": 31, "S2": 38}
const DIFF: Array[Dictionary] = [
	{"name": "Easy", "tackle": 0.8, "user_speed": 1.06, "qb_err": 0.9, "react": 0.15, "hands": 0.9},
	{"name": "Normal", "tackle": 0.88, "user_speed": 1.0, "qb_err": 0.0, "react": 0.0, "hands": 1.0},
	{"name": "Hard", "tackle": 0.94, "user_speed": 0.98, "qb_err": -0.2, "react": -0.05, "hands": 1.04}]
const HOT_ORDER: Array[String] = ["", "go", "slant", "out", "curl", "in"]
const PASS_ACTIONS: Array[String] = ["pass_1", "pass_2", "pass_3", "pass_4"]
const JUST_ACTIONS: Array[String] = ["act_a", "act_b", "act_x", "act_y", "switch", "hot", "menu", "pass_1", "pass_2", "pass_3", "pass_4",
	"num_1", "num_2", "num_3", "num_4", "num_5", "num_6", "num_7", "num_8", "num_9"]
const NUM_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9]
const LOB_HOLD: float = 0.22
enum St {TITLE, TEAMSEL, PLAYCALL, PRESNAP, LIVE, DEAD, KICK, OVER}

var state: St = St.TITLE
var teams: Array = []
var plays: Dictionary = {}
var team_idx: Array[int] = [0, 1]
var bot: bool = false
var demo: bool = false  # --demo: the bot plays both sides at normal speed with full drawing
var post_near: MeshInstance3D  # goal posts at the -Z end, between the camera and the play on drives deep in our end
var start_at: String = ""  # --start=punt or --start=fg: test switch, opens on fourth down with the ball
var bot_games: int = 1
var bot_done: int = 0
var fast: bool = false
var verbose: bool = false
var test_hook: bool = false
var notch: int = 0
var loaded: bool = false
var practice: bool = false
var score: Array[int] = [0, 0]
var stats: Array[Dictionary] = [{}, {}]
var events: Dictionary = {}
var poss: int = 0
var los: float = -25.0
var ball_x: float = 0.0
var down_n: int = 1
var first_z: float = -15.0
var quarter: int = 1
var clock: float = QLEN
var opening_kicker: int = 0
var players: Array[Array] = [[], []]
var roles: Array[Dictionary] = [{}, {}]
var off_play: Dictionary = {}
var def_play: Dictionary = {}
var play_kind: String = "scrim"
var conversion: bool = false
var conv_team: int = 0
var returning: String = ""
var carrier: TTPlayer = null
var ctrl: TTPlayer = null
var returner: TTPlayer = null
var kicker: TTPlayer = null
var ball: MeshInstance3D
var ring: MeshInstance3D
var ball_state: String = "held"
var ball_from: Vector3 = Vector3.ZERO
var ball_to: Vector3 = Vector3.ZERO
var ball_t: float = 0.0
var ball_T: float = 1.0
var ball_arc: float = 2.0
var ball_lob: bool = false
var ball_target: TTPlayer = null
var loose_t: float = 0.0
var kick_power: float = 0.7
var kicked: bool = false
var live_t: float = 0.0
var presnap_t: float = 0.0
var meter_t: float = 0.0
var handed: bool = false
var snap_queued: bool = false  # the player pressed snap before the presnap guard time ended
var pitched: bool = false  # option play: the QB already pitched
var qb_keep: bool = false  # zone read: the QB kept the ball
var pursue: bool = false
var qb_t: float = 2.0
var dead_t: float = 0.0
var pending: String = "play"
var kick: Dictionary = {}
var hot_routes: Dictionary = {}
var audible_open: bool = false
var audible_opts: Array[Dictionary] = []
var hold_idx: int = -1
var hold_t: float = 0.0
var cam: Camera3D
var cam_focus: Vector3 = Vector3(0.0, 0.0, -25.0)
var hud: TTHud
var view: SquadView
var field_mat: StandardMaterial3D
var los_line: MeshInstance3D
var first_line: MeshInstance3D
var sfx: Dictionary = {}
var music: AudioStreamPlayer
var crowd: AudioStreamPlayer
var audio_ok: bool = false
var just: Dictionary = {}
var pad_last: bool = false
var save: Dictionary = {"v": 1, "sound": true, "wins": 0, "losses": 0, "ties": 0, "team": 0, "difficulty": 1, "auto_pass": false}
var diff: Dictionary = {}

func dirv(side: int) -> float:
	return 1.0 if side == 0 else -1.0

func R(side: int, role: String) -> TTPlayer:
	return roles[side].get(role, null) as TTPlayer

func tm(side: int) -> Dictionary:
	return teams[team_idx[side]] as Dictionary

func human() -> bool:
	return not bot

func auto_pass() -> bool:
	# Auto pass setting: on the player's pass plays the computer QB throws and the player takes the catcher.
	return human() and poss == 0 and bool(save.get("auto_pass", false)) and play_kind == "scrim" and returning == "" \
		and String(off_play.get("type", "")) == "pass"

func user_off() -> bool:
	return human() and poss == 0

func is_kick_play() -> bool:
	return play_kind == "kickoff" or play_kind == "punt"

func _load_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _ready() -> void:
	randomize()
	teams = _load_json("res://data/teams.json") as Array
	plays = _load_json("res://data/plays.json") as Dictionary
	_parse_args()
	_setup_input()
	_load_save()
	diff = DIFF[1] if bot else DIFF[clampi(int(save.difficulty), 0, 2)]
	_build_world()
	_build_audio()
	hud = TTHud.new()
	add_child(hud)
	hud.build(VERSION, teams, clampi(int(save.difficulty), 0, 2), plays.formations as Dictionary, (plays.defense_formations as Dictionary).base as Dictionary)
	hud.start_pressed.connect(_on_start)
	hud.team_chosen.connect(start_game)
	hud.play_chosen.connect(_on_play_chosen)
	hud.menu_action.connect(_on_menu)
	hud.world_press.connect(_on_world_press)
	hud.world_release.connect(_on_world_release)
	hud.throw_down.connect(_on_throw_down)
	hud.throw_up.connect(_on_throw_up)
	hud.apply_safe_area(notch)
	get_viewport().size_changed.connect(func() -> void: hud.apply_safe_area(notch))
	_spawn_players()
	_apply_sound()
	if OS.has_feature("web") or OS.has_feature("mobile"):
		get_viewport().scaling_3d_scale = 0.85
		Engine.max_fps = 60
	loaded = true
	goto_title()
	if bot:
		start_game(0, false, 1)

func _parse_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("window.location.search", true)
		if q is String:
			for a: String in (q as String).trim_prefix("?").split("&"):
				args.append("--" + a)
	for a: String in args:
		if a == "--bot":
			bot = true
		elif a == "--demo":
			bot = true
			demo = true
		elif a == "--fast":
			fast = true
		elif a == "--verbose":
			verbose = true
		elif a == "--test":
			test_hook = OS.has_feature("web")
		elif a.begins_with("--games="):
			bot_games = int(a.get_slice("=", 1))
		elif a.begins_with("--seed="):
			seed(int(a.get_slice("=", 1)))
		elif a.begins_with("--start="):
			start_at = a.get_slice("=", 1)
		elif a.begins_with("--notch="):
			notch = int(a.get_slice("=", 1))

# ---------------------------------------------------------------- input actions (standard E5.4)

func _key(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	return e

func _joy(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.device = -1
	return e

func _axis(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	e.device = -1
	return e

func _action(action: String, evs: Array[InputEvent]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.35)
	for e: InputEvent in evs:
		InputMap.action_add_event(action, e)

func _setup_input() -> void:
	_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _joy(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _joy(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("move_up", [_key(KEY_W), _key(KEY_UP), _joy(JOY_BUTTON_DPAD_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_down", [_key(KEY_S), _key(KEY_DOWN), _joy(JOY_BUTTON_DPAD_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("act_a", [_key(KEY_SPACE), _key(KEY_ENTER), _key(KEY_KP_ENTER), _joy(JOY_BUTTON_A)])
	_action("act_b", [_key(KEY_E), _joy(JOY_BUTTON_B)])
	_action("act_x", [_key(KEY_Q), _joy(JOY_BUTTON_X)])
	_action("act_y", [_key(KEY_R), _joy(JOY_BUTTON_Y)])
	_action("sprint", [_key(KEY_SHIFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_action("switch", [_key(KEY_TAB), _joy(JOY_BUTTON_LEFT_SHOULDER)])
	_action("hot", [_joy(JOY_BUTTON_RIGHT_SHOULDER)])
	_action("menu", [_key(KEY_ESCAPE), _joy(JOY_BUTTON_START), _joy(JOY_BUTTON_BACK)])
	_action("pass_1", [_key(KEY_1), _joy(JOY_BUTTON_A)])
	_action("pass_2", [_key(KEY_2), _joy(JOY_BUTTON_B)])
	_action("pass_3", [_key(KEY_3), _joy(JOY_BUTTON_X)])
	_action("pass_4", [_key(KEY_4), _joy(JOY_BUTTON_Y)])
	for i: int in NUM_KEYS.size():
		_action("num_%d" % (i + 1), [_key(NUM_KEYS[i])])

func _input(e: InputEvent) -> void:
	var is_pad: bool = e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.5)
	if (e is InputEventKey or is_pad) and hud:
		hud.touch_seen = false
		hud.update_pad()
		pad_last = is_pad
	if not audio_ok and e.is_pressed() and (e is InputEventKey or e is InputEventJoypadButton or e is InputEventScreenTouch or e is InputEventMouseButton):
		_unlock_audio()
	if e.is_echo():
		return
	for a: String in JUST_ACTIONS:
		if e.is_action_pressed(a):
			just[a] = true
		elif e.is_action_released(a):
			just[a + "_up"] = true

func _move_input() -> Vector2:
	var v: Vector2 = Input.get_vector("move_left", "move_right", "move_down", "move_up")
	v += Vector2(hud.stick.x, -hud.stick.y)
	return v.limit_length(1.0)

func _sprint_held() -> bool:
	return Input.is_action_pressed("sprint") or (Input.is_action_pressed("act_a") and not _can_throw()) or bool(hud.btn_held.A)

func _a_just() -> bool:
	return bool(just.get("act_a", false)) or bool(hud.btn_just.A)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		just["menu"] = true
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if loaded:
			_write_save()

# ---------------------------------------------------------------- world

func _mi(mesh: Mesh, m: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b

func _mat(c: Color, rough: float = 0.8, unshaded: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _merge(parts: Array[Mesh], at: Array[Vector3], m: Material) -> MeshInstance3D:
	# Standard E3.2: repeated static pieces are merged into one mesh, one draw call.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in parts.size():
		st.append_from(parts[i], 0, Transform3D(Basis(), at[i]))
	return _mi(st.commit(), m, Vector3.ZERO)

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.46, 0.7, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.62
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, 28.0, 0.0)
	sun.light_energy = 1.05
	sun.shadow_enabled = false
	add_child(sun)
	# field: one textured slab, so lines never flicker against the grass
	field_mat = _mat(Color.WHITE, 1.0)
	var pm := PlaneMesh.new()
	pm.size = Vector2(64.0, 144.0)
	_mi(pm, field_mat, Vector3.ZERO)
	var apron := PlaneMesh.new()
	apron.size = Vector2(400.0, 400.0)
	_mi(apron, _mat(Color(0.16, 0.3, 0.18), 1.0), Vector3(0.0, -0.2, 0.0))
	_paint_field()
	# goal posts, one merged mesh per end, so the near end can hide when the camera is behind it
	var post_mat: Material = _mat(Color(0.98, 0.85, 0.15), 0.4)
	for sz: float in [-1.0, 1.0]:
		var post_parts: Array[Mesh] = []
		var post_at: Array[Vector3] = []
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.18
		cyl.bottom_radius = 0.18
		cyl.height = 3.4
		cyl.radial_segments = 8
		post_parts.append(cyl)
		post_at.append(Vector3(0.0, 1.7, sz * (END + 0.6)))
		post_parts.append(_box(Vector3(6.4, 0.3, 0.3)))
		post_at.append(Vector3(0.0, 3.4, sz * (END + 0.6)))
		for sx: float in [-1.0, 1.0]:
			post_parts.append(_box(Vector3(0.26, 9.0, 0.26)))
			post_at.append(Vector3(sx * 3.1, 7.9, sz * (END + 0.6)))
		var posts: MeshInstance3D = _merge(post_parts, post_at, post_mat)
		if sz < 0.0:
			post_near = posts
	# stands with a crowd made of coloured dots, all in one mesh
	var cimg := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var pal: Array[Color] = [Color(0.9, 0.9, 0.9), Color(0.8, 0.2, 0.2), Color(0.2, 0.4, 0.8), Color(0.95, 0.8, 0.3), Color(0.25, 0.25, 0.3), Color(0.8, 0.6, 0.45), Color(0.3, 0.6, 0.4)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for y: int in 128:
		for x: int in 128:
			var dot: bool = (x % 2 == 0 and y % 2 == 0) or rng.randf() < 0.25
			cimg.set_pixel(x, y, pal[rng.randi() % pal.size()] if dot else Color(0.2, 0.22, 0.27))
	var cm := _mat(Color.WHITE, 1.0)
	cm.albedo_texture = ImageTexture.create_from_image(cimg)
	cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cm.uv1_triplanar = true
	cm.uv1_world_triplanar = true
	cm.uv1_scale = Vector3(0.035, 0.035, 0.035)
	var st_parts: Array[Mesh] = []
	var st_at: Array[Vector3] = []
	var wall_parts: Array[Mesh] = []
	var wall_at: Array[Vector3] = []
	for sx: float in [-1.0, 1.0]:
		wall_parts.append(_box(Vector3(1.0, 1.6, 150.0)))
		wall_at.append(Vector3(sx * 35.0, 0.8, 0.0))
		for tier: int in 6:
			st_parts.append(_box(Vector3(4.2, 3.0, 150.0)))
			st_at.append(Vector3(sx * (38.0 + tier * 4.0), 1.5 + tier * 2.2, 0.0))
	for sz: float in [-1.0, 1.0]:
		wall_parts.append(_box(Vector3(71.0, 1.6, 1.0)))
		wall_at.append(Vector3(0.0, 0.8, sz * 75.0))
		for tier: int in 5:
			st_parts.append(_box(Vector3(71.0, 3.0, 4.2)))
			st_at.append(Vector3(0.0, 1.5 + tier * 2.2, sz * (78.0 + tier * 4.0)))
	_merge(st_parts, st_at, cm)
	_merge(wall_parts, wall_at, _mat(Color(0.2, 0.24, 0.3), 0.9))
	# line of scrimmage and first down markers: raised strips with real thickness
	var strip := _box(Vector3(HALF_W * 2.0, 0.1, 0.28))
	los_line = _mi(strip, _mat(Color(0.25, 0.55, 1.0), 1.0, true), Vector3.ZERO)
	first_line = _mi(strip, _mat(Color(1.0, 0.86, 0.1), 1.0, true), Vector3.ZERO)
	var bm := SphereMesh.new()
	bm.radius = 0.3
	bm.height = 0.6
	bm.radial_segments = 10
	bm.rings = 5
	ball = _mi(bm, _mat(Color(0.5, 0.27, 0.12), 0.6), Vector3.ZERO)
	ball.scale = Vector3(0.8, 0.8, 1.35)
	var tr := TorusMesh.new()
	tr.inner_radius = 0.82
	tr.outer_radius = 1.02
	tr.rings = 20
	tr.ring_segments = 6
	ring = _mi(tr, _mat(Color(1.0, 0.9, 0.1), 1.0, true), Vector3.ZERO)
	ring.scale = Vector3(1.0, 0.25, 1.0)
	ring.visible = false
	cam = Camera3D.new()
	cam.fov = 48.0
	cam.near = 0.5
	cam.far = 500.0
	add_child(cam)
	cam.position = Vector3(0.0, 18.0, -50.0)
	cam.look_at(Vector3(0.0, 0.0, -20.0))
	cam.current = true
	get_viewport().mesh_lod_threshold = 3.0

func _digit(img: Image, ch: String, cx: int, cy: int, s: int, rot: int) -> void:
	var bits: String = SquadView.FONT[ch]
	for r: int in 5:
		for c: int in 3:
			if bits[r * 3 + c] == "1":
				var ox: int = (c - 1) * s
				var oy: int = (r - 2) * s
				img.fill_rect(Rect2i(cx - oy * rot - s / 2, cy + ox * rot - s / 2, s, s), Color(0.95, 0.95, 0.95))

func _fx(x: float) -> int:
	return int(round((x + 32.0) * 8.0))

func _fz(z: float) -> int:
	return int(round((z + 72.0) * 8.0))

func _paint_field() -> void:
	var img := Image.create(512, 1152, false, Image.FORMAT_RGB8)
	img.fill(Color(0.17, 0.36, 0.2))
	var wpx: int = int(HALF_W * 16.0)
	for i: int in 20:
		img.fill_rect(Rect2i(_fx(-HALF_W), _fz(-50.0 + i * 5), wpx, 40), Color(0.2, 0.5, 0.24) if i % 2 == 0 else Color(0.23, 0.55, 0.27))
	img.fill_rect(Rect2i(_fx(-HALF_W), _fz(-60.0), wpx, 80), Color(String(tm(0).jersey)).darkened(0.15))
	img.fill_rect(Rect2i(_fx(-HALF_W), _fz(50.0), wpx, 80), Color(String(tm(1).jersey)).darkened(0.15))
	var white := Color(0.95, 0.95, 0.95)
	for i: int in 21:
		var th: int = 4 if (i == 0 or i == 20) else 2
		img.fill_rect(Rect2i(_fx(-HALF_W), _fz(-50.0 + i * 5) - th / 2, wpx, th), white)
	for zi: int in range(-49, 50):
		for hx: float in [-6.6, 6.1, -HALF_W + 0.3, HALF_W - 1.0]:
			img.fill_rect(Rect2i(_fx(hx), _fz(zi), 5, 1), white)
	img.fill_rect(Rect2i(_fx(-HALF_W) - 4, _fz(-60.0) - 4, wpx + 8, 4), white)
	img.fill_rect(Rect2i(_fx(-HALF_W) - 4, _fz(60.0), wpx + 8, 4), white)
	img.fill_rect(Rect2i(_fx(-HALF_W) - 4, _fz(-60.0), 4, 960), white)
	img.fill_rect(Rect2i(_fx(HALF_W), _fz(-60.0), 4, 960), white)
	for z: int in range(-40, 41, 10):
		var txt: String = str(50 - absi(z)).pad_zeros(2)
		for k: int in 2:
			_digit(img, txt[k], _fx(-17.0), _fz(z) + int((k - 0.5) * 22.0), 5, 1)
			_digit(img, txt[k], _fx(17.0), _fz(z) - int((k - 0.5) * 22.0), 5, -1)
	img.generate_mipmaps()
	field_mat.albedo_texture = ImageTexture.create_from_image(img)

# ---------------------------------------------------------------- sound and saves

func _build_audio() -> void:
	for n: String in ["whistle", "cheer", "kick", "click", "hit0", "hit1", "hit2"]:
		var a := AudioStreamPlayer.new()
		a.stream = load("res://audio/%s.wav" % n)
		a.volume_db = -4.0
		add_child(a)
		sfx[n] = a
	(sfx.click as AudioStreamPlayer).volume_db = -10.0
	crowd = AudioStreamPlayer.new()
	var cs: AudioStreamOggVorbis = load("res://audio/crowd.ogg")
	cs.loop = true
	crowd.stream = cs
	crowd.volume_db = -15.0
	add_child(crowd)
	music = AudioStreamPlayer.new()
	var ms: AudioStreamOggVorbis = load("res://audio/music_title.ogg")
	ms.loop = true
	music.stream = ms
	music.volume_db = -9.0
	add_child(music)

func _unlock_audio() -> void:
	# Standard E6.2: no sound starts before the first input.
	audio_ok = true
	if bot:
		return
	if state == St.TITLE or state == St.TEAMSEL or state == St.OVER:
		if not music.playing:
			music.play()
	elif not crowd.playing:
		crowd.play()

func play_sfx(n: String) -> void:
	if bot or not audio_ok:
		return
	var key: String = n
	if n == "hit":
		key = "hit%d" % (randi() % 3)
	if sfx.has(key):
		(sfx[key] as AudioStreamPlayer).play()

func _apply_sound() -> void:
	AudioServer.set_bus_mute(0, not bool(save.sound))
	if hud and hud.sound_btn:
		hud.sound_btn.text = "Sound: On" if bool(save.sound) else "Sound: Off"
		hud.set_auto_pass(bool(save.get("auto_pass", false)))

func _load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if d is Dictionary:
			for k: String in (d as Dictionary):
				save[k] = (d as Dictionary)[k]

func _write_save() -> void:
	# Standard E6.4: temp file and rename on Android, direct write and sync in the browser.
	if bot:
		return
	var txt: String = JSON.stringify(save)
	if OS.has_feature("web"):
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(txt)
			f.close()
		JavaScriptBridge.force_fs_sync()
		return
	var tmp: String = SAVE_PATH + ".tmp"
	var f2 := FileAccess.open(tmp, FileAccess.WRITE)
	if f2 == null:
		return
	f2.store_string(txt)
	f2.close()
	DirAccess.rename_absolute(tmp, SAVE_PATH)

# ---------------------------------------------------------------- players

func _spawn_players() -> void:
	var all: Array[TTPlayer] = []
	for side: int in 2:
		for i: int in 11:
			var p := TTPlayer.new()
			p.team = side
			p.idx = i
			add_child(p)
			players[side].append(p)
			all.append(p)
	view = SquadView.new()
	add_child(view)
	view.setup(all)
	view.paint([tm(0), tm(1)])

func _speed_for(p: TTPlayer) -> float:
	var base: float = float(SPEED[p.role])
	if is_kick_play():
		base = 9.4 if p.role == "CB2" else 8.6
	var s: float = base * float(tm(p.team).speed)
	if human() and p.team == 0:
		s *= float(diff.user_speed)
	return s

func _set_ctrl(p: TTPlayer) -> void:
	ctrl = p

func _nearest_of(list: Array, pos: Vector3) -> TTPlayer:
	var best: TTPlayer = null
	var bd: float = 1.0e9
	for p: TTPlayer in list:
		if p.down:
			continue
		var d2: float = p.position.distance_squared_to(pos)
		if d2 < bd:
			bd = d2
			best = p
	return best

# ---------------------------------------------------------------- flow

func goto_title() -> void:
	state = St.TITLE
	hud.show_screen("title")
	hud.set_menu(false)
	hud.pad_active = false
	hud.update_pad()
	hud.set_meter(false, 0.1)
	hud.show_throw(false, PackedStringArray())
	hud.hide_call()
	hud.set_ingame(false)
	crowd.stop()
	if audio_ok and not bot and not music.playing:
		music.play()
	poss = 0
	los = -8.0
	ball_x = 0.0
	first_z = 2.0
	play_kind = "scrim"
	conversion = false
	off_play = _find("offense", "deep")
	def_play = _find("defense", "zone")
	_place_formation()

func _on_start() -> void:
	state = St.TEAMSEL
	hud.show_screen("team")

func start_game(team: int, practice_mode: bool, difficulty: int) -> void:
	practice = practice_mode
	team_idx[0] = team
	var others: Array[int] = []
	for i: int in teams.size():
		if i != team:
			others.append(i)
	team_idx[1] = others[randi() % others.size()]
	if not bot:
		save.team = team
		save.difficulty = difficulty
		diff = DIFF[clampi(difficulty, 0, 2)]
		_write_save()
	view.paint([tm(0), tm(1)])
	_paint_field()
	score = [0, 0]
	for s: int in 2:
		stats[s] = {"yards": 0.0, "to": 0, "plays": 0, "td": 0}
	events = {"td": 0, "fg": 0, "int": 0, "punt": 0, "sack": 0, "plays": 0, "inc": 0, "comp": 0, "safety": 0, "downs": 0, "fumble": 0,
		"kickoff": 0, "returns": 0, "ret_td": 0, "touchback": 0, "two_try": 0, "two_good": 0, "xp": 0, "ot": 0, "lob": 0, "pitch": 0, "keep": 0, "read": 0, "auto": 0}
	quarter = 1
	clock = QLEN
	conversion = false
	hud.show_screen("")
	hud.set_ingame(true)
	music.stop()
	if audio_ok and not bot:
		crowd.play()
	if practice:
		poss = 0
		los = -20.0
		ball_x = 0.0
		down_n = 1
		first_z = -10.0
		hud.say("Practice: run any play", 2.5)
		goto_playcall()
	elif start_at == "punt" or start_at == "fg":
		# test switch: fourth down with the ball, deep in our end for a punt or at their 25 for a kick
		opening_kicker = 1
		poss = 0
		los = -22.0 if start_at == "punt" else 25.0
		ball_x = 0.0
		down_n = 4
		first_z = los + 6.0
		goto_playcall()
	else:
		opening_kicker = randi() % 2
		hud.say("%s vs %s" % [String(tm(0).name), String(tm(1).name)], 2.5)
		setup_kickoff(opening_kicker, -15.0)

func setup_kickoff(side: int, from_yd: float) -> void:
	poss = side
	los = from_yd * dirv(side)
	ball_x = 0.0
	down_n = 1
	first_z = los
	play_kind = "kickoff"
	conversion = false
	off_play = {"id": "kickoff", "name": "Kickoff", "type": "kick"}
	def_play = {"id": "kick_return", "name": "Return", "jobs": {}}
	events.kickoff += 1
	_place_formation()
	_begin_presnap()

func _setup_punt() -> void:
	play_kind = "punt"
	off_play = {"id": "punt", "name": "Punt", "type": "kick"}
	def_play = {"id": "punt_return", "name": "Return", "jobs": {}}
	events.punt += 1
	_place_formation()
	_begin_presnap()

func ord_txt(n: int) -> String:
	return ["1st", "2nd", "3rd", "4th"][clampi(n - 1, 0, 3)]

func yard_txt() -> String:
	var y: float = los * dirv(poss)
	if absf(y) < 0.5:
		return "the 50"
	var who: String = String(tm(poss).abbr) if y < 0.0 else String(tm(1 - poss).abbr)
	return "%s %d" % [who, int(round(50.0 - absf(y)))]

func _dd_text() -> String:
	if conversion:
		return "2-point try"
	var togo: float = (first_z - los) * dirv(poss)
	var tg: String = "Goal" if absf(first_z) >= GOAL - 0.01 else str(maxi(1, int(round(togo))))
	return "%s & %s at %s" % [ord_txt(down_n), tg, yard_txt()]

func _update_hud() -> void:
	if practice:
		hud.score_lbl.text = "PRACTICE  %s" % String(tm(0).name)
	else:
		var qn: String = "OT" if quarter >= 5 else "Q%d" % quarter
		hud.score_lbl.text = "%s %d   %s %d    %s %d:%02d" % [String(tm(0).abbr), score[0], String(tm(1).abbr), score[1], qn, int(clock) / 60, int(clock) % 60]
	var info: String = ""
	if play_kind == "kickoff":
		info = "Kickoff: %s kicks" % String(tm(poss).abbr)
	elif play_kind == "punt":
		info = "%s punts from %s" % [String(tm(poss).abbr), yard_txt()]
	elif play_kind == "fg":
		info = "%s %s" % [String(tm(poss).abbr), "extra point" if bool(kick.get("xp", false)) else "field goal, %d yards" % int(fg_dist())]
	else:
		info = "%s ball  %s" % [String(tm(poss).abbr), _dd_text()]
	hud.info_lbl.text = info
	hud.burst_bar.visible = state == St.LIVE and ctrl != null
	if ctrl:
		hud.burst_bar.value = ctrl.burst

func fg_dist() -> float:
	return (GOAL - los * dirv(poss)) + 17.0

func _find(list: String, id: String) -> Dictionary:
	for p: Dictionary in plays[list]:
		if String(p.id) == id:
			return p
	return (plays[list] as Array)[0]

func _where(list: String, key: String, val: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in plays[list]:
		if String(p.get(key, "")) == val:
			out.append(p)
	return out

func _pick(arr: Array[Dictionary]) -> Dictionary:
	return arr[randi() % arr.size()]

func _card(p: Dictionary, kind: String) -> Dictionary:
	return {"id": String(p.id), "name": String(p.name), "play": p, "kind": kind, "tip": String(p.get("tip", ""))}

func _special(id: String, nm: String, tip: String) -> Dictionary:
	return {"id": id, "name": nm, "play": {}, "kind": "special", "tip": tip}

func goto_playcall() -> void:
	state = St.PLAYCALL
	play_kind = "scrim"
	hud.pad_active = false
	hud.update_pad()
	hud.show_throw(false, PackedStringArray())
	hud.set_meter(false, 0.1)
	off_play = _find("offense", "slants")
	def_play = _find("defense", "zone")
	_place_formation()
	_update_hud()
	if bot:
		_resolve_cpu_call()
		return
	var d: float = dirv(poss)
	var togo: float = (first_z - los) * d
	if poss == 0:
		def_play = _cpu_def_choice()
		var t: Dictionary = {"Short": [], "Deep": [], "Run": [], "Option": []}
		var order := PackedStringArray(["Short", "Deep", "Run", "Option"])
		for p: Dictionary in plays.offense:
			var cat: String = String(p.cat)
			(t[cat.capitalize()] as Array).append(_card(p, "off"))
		var kicks: Array = []
		if not practice and not conversion:
			if down_n == 4:
				kicks.append(_special("punt", "Punt", "Kick it away"))
			if fg_dist() <= 57.0:
				kicks.append(_special("fg", "Field Goal", "%d yard kick" % int(fg_dist())))
		if kicks.size() > 0:
			t["Kick"] = kicks
			order.append("Kick")
		var start: String = "Run" if togo <= 2.0 else "Short"
		if down_n == 4 and kicks.size() > 0 and togo > 3.0:
			start = "Kick"
		hud.show_call("%s. Pick a play" % _dd_text(), t, order, start)
		hud.hint.text = "Tap a play or press its number. Change tabs: Q and E, or LB and RB"
	else:
		var c: Variant = _cpu_off_choice()
		if c is String:
			_do_special(c as String)
			return
		off_play = c
		var td: Dictionary = {"Man": [], "Zone": [], "Blitz": [], "Run": []}
		for p: Dictionary in plays.defense:
			(td[String(p.cat).capitalize()] as Array).append(_card(p, "def"))
		var dstart: String = "Run" if togo <= 2.0 else ("Zone" if togo >= 8.0 else "Man")
		hud.show_call("Defense. %s" % _dd_text(), td, PackedStringArray(["Man", "Zone", "Blitz", "Run"]), dstart)
		hud.hint.text = "Tap a defense or press its number. Change tabs: Q and E, or LB and RB"

func _playcall_input() -> void:
	for i: int in 9:
		if bool(just.get("num_%d" % (i + 1), false)):
			hud.pick(i)
			return
	if bool(just.get("act_b", false)) or bool(just.get("hot", false)) or bool(just.get("switch", false)):
		hud.cycle_tab(1)
	elif bool(just.get("act_x", false)):
		hud.cycle_tab(-1)

func _resolve_cpu_call() -> void:
	var c: Variant = _cpu_off_choice()
	if c is String:
		_do_special(c as String)
		return
	off_play = c
	def_play = _cpu_def_choice()
	setup_play()

func _cpu_off_choice() -> Variant:
	var d: float = dirv(poss)
	var togo: float = (first_z - los) * d
	var to_goal: float = GOAL - los * d
	if not practice and not conversion:
		if down_n == 4:
			if fg_dist() <= 50.0:
				return "fg"
			if not (togo <= 2.0 and to_goal < 55.0):
				return "punt"
		if clock < 13.0 and fg_dist() <= 54.0:
			var behind: int = score[1 - poss] - score[poss]
			if quarter == 2 or (quarter >= 4 and behind >= 0 and behind <= 3):
				return "fg"
	var pp: float = 0.55
	if togo >= 8.0:
		pp = 0.72
	if togo <= 2.0:
		pp = 0.3
	if down_n >= 3 and togo >= 5.0:
		pp = 0.88
	var short_field: bool = togo <= 1.5 or to_goal <= 3.0
	if randf() < pp:
		var cat: String = "short"
		if to_goal > 14.0 and ((togo >= 12.0 and randf() < 0.55) or randf() < 0.2):
			cat = "deep"
		var opts: Array[Dictionary] = []
		for p: Dictionary in _where("offense", "cat", cat):
			if bool(p.get("short", false)) and not short_field:
				continue
			opts.append(p)
		return _pick(opts)
	var runs: Array[Dictionary] = []
	var run_cat: String = "option" if (not short_field and randf() < 0.3) else "run"
	for p: Dictionary in _where("offense", "cat", run_cat):
		if bool(p.get("short", false)) and not short_field:
			continue
		runs.append(p)
	return _pick(runs)

func _cpu_def_choice() -> Dictionary:
	var d: float = dirv(poss)
	var togo: float = (first_z - los) * d
	var to_goal: float = GOAL - los * d
	var r: float = randf()
	var cat: String = "man"
	if conversion or to_goal <= 4.0:
		if r < 0.45:
			return _find("defense", "goal_line")
		cat = "man" if r < 0.75 else "blitz"
	elif togo <= 2.0:
		cat = "run" if r < 0.55 else ("blitz" if r < 0.75 else "man")
	elif togo >= 8.0:
		cat = "zone" if r < 0.5 else ("man" if r < 0.8 else "blitz")
	else:
		cat = ["man", "zone", "blitz", "run"][randi() % 4]
	return _pick(_where("defense", "cat", cat))

func _on_play_chosen(id: String) -> void:
	if state != St.PLAYCALL:
		return
	hud.hide_call()
	get_viewport().gui_release_focus()
	match id:
		"punt", "fg":
			_do_special(id)
			return
		"xp":
			_start_kick(true)
			return
		"two":
			_start_two()
			return
	for p: Dictionary in plays.offense:
		if String(p.id) == id:
			off_play = p
	for p: Dictionary in plays.defense:
		if String(p.id) == id:
			def_play = p
	setup_play()

func _do_special(id: String) -> void:
	hud.hide_call()
	if id == "fg":
		_start_kick(false)
	else:
		_setup_punt()

func fw(x: float, z: float) -> Vector3:
	var d: float = dirv(poss)
	return Vector3(clampf(ball_x - x * d, -HALF_W + 1.2, HALF_W - 1.2), 0.0, clampf(los + z * d, -END + 1.0, END - 1.0))

func _off_form() -> Dictionary:
	var f: Dictionary = plays.formations
	match play_kind:
		"kickoff":
			return f.kickoff
		"punt":
			return f.punt
		"fg":
			return f.fg
	return f[String(off_play.get("formation", "gun"))]

func _def_form() -> Dictionary:
	var f: Dictionary = plays.defense_formations
	match play_kind:
		"kickoff":
			return f.kick_return
		"punt":
			return f.punt_return
	return f.base

func _place_formation() -> void:
	roles = [{}, {}]
	var d: float = dirv(poss)
	var oform: Dictionary = _off_form()
	var dform: Dictionary = _def_form()
	var align: Dictionary = def_play.get("align", {})
	var jobs: Dictionary = def_play.get("jobs", {})
	for i: int in 11:
		var o: TTPlayer = players[poss][i]
		o.reset_play()
		o.role = OFF_ROLES[i]
		o.side = "off"
		roles[poss][o.role] = o
		var a: Array = oform[o.role]
		o.position = fw(float(a[0]), float(a[1]))
		o.home = o.position
		o.face = Vector3(0.0, 0.0, d)
		var q: TTPlayer = players[1 - poss][i]
		q.reset_play()
		q.role = DEF_ROLES[i]
		q.side = "def"
		roles[1 - poss][q.role] = q
	for i: int in 11:
		var q2: TTPlayer = players[1 - poss][i]
		var b: Array = align.get(q2.role, dform[q2.role])
		var pos: Vector3 = fw(float(b[0]), float(b[1]))
		var job: String = String(jobs.get(q2.role, "rush"))
		if play_kind == "scrim" and job.begins_with("man:") and not align.has(q2.role):
			var m: TTPlayer = R(poss, job.substr(4))
			if m != null and m.role != "RB":
				var depth: float = 6.0 if q2.role.begins_with("CB") else 4.5
				if bool(def_play.get("press", false)):
					depth = 1.8
				pos = Vector3(m.position.x, 0.0, los + depth * d)
		if play_kind == "punt" and q2.role == "CB2":
			pos = fw(0.0, minf(40.0, (GOAL - los * d) - 3.0))
		q2.position = pos
		q2.home = pos
		q2.face = Vector3(0.0, 0.0, -d)
	for side: int in 2:
		for p: TTPlayer in players[side]:
			p.top_speed = _speed_for(p)
			p.step(0.0, false)
			view.set_number(p, int(NUMBERS.get(p.role, 10)))
	_set_ctrl(null)
	returning = ""
	kicked = false
	kicker = null
	returner = R(1 - poss, "CB2") if is_kick_play() else null
	ball_target = null
	if play_kind == "kickoff":
		carrier = null
		ball_state = "dead"
		ball.position = Vector3(ball_x, 0.3, los)
	else:
		carrier = R(poss, "QB")
		ball_state = "held"
	los_line.position = Vector3(0.0, 0.05, los)
	first_line.position = Vector3(0.0, 0.05, first_z)
	first_line.visible = play_kind == "scrim" and absf(first_z) < GOAL - 0.01
	_ball_follow()
	cam_focus = Vector3(ball_x, 0.0, los)

func setup_play() -> void:
	_place_formation()
	_begin_presnap()

func _begin_presnap() -> void:
	state = St.PRESNAP
	snap_queued = false
	presnap_t = 0.0
	meter_t = 0.0
	kicked = false
	audible_open = false
	hold_idx = -1
	hot_routes.clear()
	hud.hide_call()
	hud.show_throw(false, PackedStringArray())
	if human():
		hud.pad_active = true
		hud.reset_touch()
		hud.update_pad()
		if is_kick_play():
			if poss == 0:
				_set_ctrl(R(0, "RB") if play_kind == "kickoff" else R(0, "QB"))
				hud.set_meter(true, 0.12, 0.56 if play_kind == "kickoff" else 0.7)
				hud.hint.text = "%s: stop the marker in the green for a long kick. Space, A or tap" % ("Kickoff" if play_kind == "kickoff" else "Punt")
			else:
				_set_ctrl(R(0, "CB2"))
				hud.hint.text = "You return the kick. The returner catches it, then you run"
		elif poss == 0:
			_set_ctrl(R(0, "QB") if String(off_play.type) == "pass" else R(0, String(off_play.get("carrier", "RB"))))
			if String(off_play.type) == "pass":
				hud.hint.text = "Snap: Space or A.  Audible: R or Y.  Hot route: 1 to 4, RB plus a button, or tap a receiver"
			else:
				hud.hint.text = "Snap: Space or A.  Audible: R or Y"
		else:
			_set_ctrl(R(0, "LB2"))
			hud.hint.text = "Get ready. Switch player: Tab, LB or Switch"
	_update_hud()

# ---------------------------------------------------------------- before the snap

func _presnap(dt: float) -> void:
	presnap_t += dt
	if is_kick_play():
		if human() and poss == 0:
			meter_t += dt
			hud.meter_pos = 0.5 + 0.5 * sin(meter_t * 3.4)
			hud.meter.queue_redraw()
			if (_a_just() or bool(hud.btn_just.B) or bool(hud.btn_just.C)) and presnap_t > 0.3:
				kick_power = 1.0 - minf(1.0, absf(hud.meter_pos - 0.5) * 2.0)
				hud.set_meter(false, 0.12)
				snap()
		elif presnap_t > (1.6 if human() else 0.3):
			kick_power = randf_range(0.5, 1.0)
			snap()
		return
	if user_off():
		_presnap_offense()
		# a snap press in the first quarter second is kept and used once the quarter second passes
		if audible_open:
			snap_queued = false
		elif state == St.PRESNAP and _a_just() and not Input.is_action_pressed("hot"):
			snap_queued = true
		if state == St.PRESNAP and not audible_open and snap_queued and presnap_t > 0.25:
			snap()
	elif human():
		if bool(just.get("switch", false)) or _a_just():
			_switch_defender()
		if presnap_t > 1.7:
			snap()
	elif presnap_t > 0.3:
		snap()

func _presnap_offense() -> void:
	var audible_key: bool = bool(just.get("act_y", false)) or bool(hud.btn_just.B)
	if audible_open:
		var pick: int = -1
		for i: int in audible_opts.size():
			if bool(just.get("num_%d" % (i + 1), false)) or bool(just.get(PASS_ACTIONS[i], false)):
				pick = i
		if pick >= 0:
			_apply_audible(audible_opts[pick])
		elif audible_key:
			audible_open = false
			_begin_hint()
		return
	if audible_key:
		audible_opts = _audible_options()
		if audible_opts.size() > 0:
			audible_open = true
			var parts: PackedStringArray = PackedStringArray()
			for i: int in audible_opts.size():
				parts.append("%d %s" % [i + 1, String(audible_opts[i].name)])
			hud.hint.text = "Audible:  " + "   ".join(parts) + "   (controller: A, B, X.  R or Y to cancel)"
		return
	if String(off_play.type) == "pass":
		var n: int = mini(4, (off_play.targets as Array).size())
		for i: int in n:
			var key_press: bool = bool(just.get("num_%d" % (i + 1), false))
			var pad_press: bool = Input.is_action_pressed("hot") and bool(just.get(PASS_ACTIONS[i], false))
			if key_press or pad_press:
				_cycle_hot(i)

func _begin_hint() -> void:
	if String(off_play.type) == "pass":
		hud.hint.text = "Snap: Space or A.  Audible: R or Y.  Hot route: 1 to 4, RB plus a button, or tap a receiver"
	else:
		hud.hint.text = "Snap: Space or A.  Audible: R or Y"

func _audible_options() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var form: String = String(off_play.get("formation", "gun"))
	for cat: String in ["short", "run", "deep"]:
		for p: Dictionary in plays.offense:
			if String(p.formation) == form and String(p.cat) == cat and String(p.id) != String(off_play.id):
				out.append(p)
				break
	return out

func _apply_audible(p: Dictionary) -> void:
	off_play = p
	audible_open = false
	_place_formation()
	hot_routes.clear()
	_set_ctrl(R(0, "QB") if String(off_play.type) == "pass" else R(0, String(off_play.get("carrier", "RB"))))
	hud.say("Audible: %s" % String(p.name), 1.2, hud.GOLD)
	_begin_hint()

func _cycle_hot(i: int) -> void:
	var role: String = String((off_play.targets as Array)[i])
	var cur: String = String(hot_routes.get(role, ""))
	var k: int = (HOT_ORDER.find(cur) + 1) % HOT_ORDER.size()
	if HOT_ORDER[k] == "":
		hot_routes.erase(role)
		hud.say("Receiver %d: play route" % (i + 1), 0.9)
	else:
		hot_routes[role] = HOT_ORDER[k]
		hud.say("Receiver %d: %s" % [i + 1, HOT_ORDER[k].to_upper()], 0.9, hud.GOLD)

func _hot_points(role: String, hot: String) -> Array:
	var a: Array = _off_form()[role]
	var x0: float = float(a[0])
	var mid: float = -signf(x0) if absf(x0) > 0.5 else 1.0
	match hot:
		"go":
			return [[0.0, 30.0]]
		"slant":
			return [[0.0, 3.0], [mid * 8.0, 10.0]]
		"out":
			return [[0.0, 8.0], [-mid * 5.0, 8.0]]
		"curl":
			return [[0.0, 11.0], [mid * 1.0, 9.0]]
		"in":
			return [[0.0, 8.0], [mid * 14.0, 9.0]]
	return []

func _switch_defender() -> void:
	var tgt: Vector3 = ball_to if (ball_state == "air" or ball_state == "kick" or ball_state == "loose") else (carrier.position if carrier else Vector3(ball_x, 0.0, los))
	var best: TTPlayer = null
	var bd: float = 1.0e9
	for q: TTPlayer in players[0]:
		if q == ctrl or q.down:
			continue
		var dd: float = q.position.distance_squared_to(tgt)
		if q.engaged != null:
			dd += 40.0
		if dd < bd:
			bd = dd
			best = q
	if best:
		_set_ctrl(best)

# ---------------------------------------------------------------- the snap

func snap() -> void:
	state = St.LIVE
	live_t = 0.0
	handed = false
	pitched = false
	qb_keep = false
	pursue = false
	returning = ""
	kicked = false
	audible_open = false
	hold_idx = -1
	hud.show_throw(false, PackedStringArray())
	hud.hint.text = ""
	qb_t = randf_range(1.5, 2.7)
	get_viewport().gui_release_focus()
	if is_kick_play():
		_snap_kick()
		return
	var d: float = dirv(poss)
	var is_pass: bool = String(off_play.type) == "pass"
	events.plays += 1
	stats[poss].plays += 1
	var carrier_role: String = String(off_play.get("carrier", "RB"))
	var oform: Dictionary = _off_form()
	var routes: Dictionary = off_play.get("routes", {})
	if bool(off_play.get("fake", false)):
		qb_t += 0.6
	for o: TTPlayer in players[poss]:
		o.job = "passblock" if is_pass else "runblock"
		o.route_prev = o.position
		if o.role == "QB":
			o.job = "qb"
		if not is_pass and o.role == carrier_role and carrier_role != "QB":
			var aim: Array = off_play.aim
			o.job = "carry"
			o.route = [fw(float(aim[0]), float(aim[1]))]
		if is_pass and (routes.has(o.role) or hot_routes.has(o.role)):
			var a: Array = oform[o.role]
			var pts: Array = []
			var stop: bool = false
			if hot_routes.has(o.role):
				var hot: String = String(hot_routes[o.role])
				pts = _hot_points(o.role, hot)
				stop = hot == "out" or hot == "curl"
			else:
				var rd: Dictionary = routes[o.role]
				pts = rd.pts
				stop = bool(rd.get("stop", false))
			o.job = "route"
			o.route.clear()
			for pt: Array in pts:
				o.route.append(fw(float(a[0]) + float(pt[0]), float(a[1]) + float(pt[1])))
			o.route_stop = stop
		if is_pass and bool(off_play.get("fake", false)) and o.role == "RB" and not routes.has("RB"):
			o.job = "fake"
			o.route = [fw(1.5, 1.0)]
	if not is_pass and carrier_role == "QB":
		handed = true
	var opt: String = String(off_play.get("option", ""))
	if opt == "pitch":
		# speed option: the QB runs at the edge with the back trailing for the pitch
		var aim2: Array = off_play.aim
		var qb: TTPlayer = R(poss, "QB")
		qb.route = [fw(float(aim2[0]) * 0.55, -2.0), fw(float(aim2[0]), float(aim2[1]))]
		R(poss, "RB").job = "pitch_man"
		if user_off():
			hud.hint.text = "Option: pitch to the back with E, B or the Pitch button. Or keep it."
	elif opt == "read" and user_off():
		hud.hint.text = "Zone read: the QB reads the end, then keeps or hands off"
	if is_pass and auto_pass():
		_set_ctrl(null)
		events.auto += 1
		hud.hint.text = "Auto pass: the QB throws. You take the catcher."
	var jobs: Dictionary = def_play.get("jobs", {})
	for q: TTPlayer in players[1 - poss]:
		var j: String = String(jobs.get(q.role, "rush"))
		q.react_t = randf_range(0.1, 0.3)
		if human() and q.team == 1:
			q.react_t = maxf(0.02, q.react_t + float(diff.react))
		if j == "rush" or j == "spy":
			q.job = j
		elif j.begins_with("man:"):
			q.job = "man"
			q.man = R(poss, j.substr(4))
		else:
			q.job = "zone"
			var zz: PackedStringArray = j.substr(5).split(",")
			q.zone_spot = fw(float(zz[0]), float(zz[1]))

func _snap_kick() -> void:
	for o: TTPlayer in players[poss]:
		o.lane_x = o.position.x
	for q: TTPlayer in players[1 - poss]:
		q.job = "retblock"
		q.react_t = 0.3
	returner.job = "returner"
	if play_kind == "kickoff":
		kicker = R(poss, "RB")
		kicker.job = "kicker"
		for o: TTPlayer in players[poss]:
			if o != kicker:
				o.job = "cover"
		carrier = null
		ball_state = "dead"
	else:
		kicker = R(poss, "QB")
		kicker.job = "punter"
		for o: TTPlayer in players[poss]:
			if o != kicker:
				o.job = "passblock"
		for g: String in ["WR1", "WR2"]:
			R(poss, g).job = "cover"
		for r: String in ["DE1", "DT1", "DT2", "DE2"]:
			R(1 - poss, r).job = "rush"
		var c: TTPlayer = R(poss, "C")
		ball_from = c.position + Vector3(0.0, 0.5, 0.0)
		ball_to = kicker.position
		ball_T = 0.45
		ball_t = 0.0
		ball_arc = 0.4
		ball_state = "snap"
		carrier = null

func _kick_ball() -> void:
	kicked = true
	play_sfx("kick")
	var d: float = dirv(poss)
	var dist: float = 0.0
	var from: Vector3 = Vector3.ZERO
	if play_kind == "kickoff":
		dist = 50.0 + 17.0 * kick_power + randf_range(-3.0, 3.0)
		from = Vector3(ball_x, 0.3, los)
	else:
		dist = 30.0 + 18.0 * kick_power + randf_range(-3.0, 3.0)
		from = kicker.position + Vector3(0.0, 1.0, 0.0) + kicker.face * 0.5
	var land_x: float = clampf(ball_x + randf_range(-9.0, 9.0), -HALF_W + 3.0, HALF_W - 3.0)
	ball_from = from
	ball_to = Vector3(land_x, 0.0, clampf(los + dist * d, -END + 0.5, END - 0.5))
	ball_T = 2.6 + dist * 0.018
	ball_t = 0.0
	ball_arc = 10.0 + dist * 0.18
	ball_state = "kick"
	carrier = null
	kicker.kick_t = 0.3
	for o: TTPlayer in players[poss]:
		o.job = "cover"
		o.lane_x = o.position.x
		o.react_t = 0.0
		o.engaged = null
	for q: TTPlayer in players[1 - poss]:
		q.engaged = null
		if q != returner:
			q.job = "retblock"
	if human() and poss == 0:
		_set_ctrl(_nearest_of(players[0], ball_to))

func _land_kick() -> void:
	var d: float = dirv(poss)
	var deep: float = ball_to.z * d - GOAL
	if (play_kind == "kickoff" and deep >= 3.0) or (play_kind == "punt" and deep >= 0.0):
		end_play("touchback")
		return
	if returner and not returner.down and returner.position.distance_squared_to(ball_to) < 9.0:
		events.returns += 1
		flip_live(returner, "kick")
	else:
		_fumble(ball_to + Vector3(0.0, 0.0, 0.01))

func flip_live(c: TTPlayer, why: String) -> void:
	# The ball changed hands during the play: the other side now runs it back.
	poss = c.team
	returning = why
	carrier = c
	ball_state = "held"
	ball_target = null
	pursue = true
	for p: TTPlayer in players[poss]:
		p.side = "off"
		p.job = "carry" if p == c else "runblock"
		p.route.clear()
		p.engaged = null
	for q: TTPlayer in players[1 - poss]:
		q.side = "def"
		q.job = "rush"
		q.react_t = randf_range(0.05, 0.35)
		q.engaged = null
	if human():
		if c.team == 0:
			_set_ctrl(c)
		else:
			_set_ctrl(_nearest_of(players[0], c.position))

func _fumble(at: Vector3) -> void:
	ball_state = "loose"
	loose_t = 0.0
	ball_from = at + Vector3(0.0, 1.0, 0.0)
	ball_to = Vector3(clampf(at.x + randf_range(-3.0, 3.0), -HALF_W + 1.0, HALF_W - 1.0), 0.0, clampf(at.z + randf_range(-3.0, 3.0), -END + 1.0, END - 1.0))
	carrier = null
	events.fumble += 1
	hud.say("LOOSE BALL!", 1.2, hud.GOLD)

# ---------------------------------------------------------------- input during play

func _can_throw() -> bool:
	return state == St.LIVE and user_off() and play_kind == "scrim" and returning == "" and String(off_play.get("type", "")) == "pass" \
		and ball_state == "held" and carrier != null and carrier.role == "QB" and ctrl == carrier \
		and (carrier.position.z - los) * dirv(poss) < 0.5 and not carrier.down

func _receiver_at(pos: Vector2) -> int:
	var best: int = -1
	var bd: float = 9025.0
	var targets: Array = off_play.get("targets", [])
	for i: int in mini(4, targets.size()):
		var r: TTPlayer = R(poss, String(targets[i]))
		if r == null:
			continue
		var sp: Vector2 = cam.unproject_position(r.position + Vector3(0.0, 1.5, 0.0))
		var d2: float = sp.distance_squared_to(pos)
		if d2 < bd:
			bd = d2
			best = i
	return best

func _on_world_press(pos: Vector2) -> void:
	if state == St.KICK or (state == St.PRESNAP and is_kick_play()):
		just["act_a"] = true
		return
	if state == St.PRESNAP and user_off() and String(off_play.get("type", "")) == "pass":
		var i: int = _receiver_at(pos)
		if i >= 0:
			_cycle_hot(i)
		return
	if _can_throw():
		var j: int = _receiver_at(pos)
		if j >= 0:
			hold_idx = j
			hold_t = 0.0

func _on_world_release(_pos: Vector2) -> void:
	if hold_idx >= 0 and _can_throw():
		_user_throw(hold_idx, hold_t >= LOB_HOLD)
	hold_idx = -1

func _on_throw_down(i: int) -> void:
	if state == St.PRESNAP and audible_open and i < audible_opts.size():
		_apply_audible(audible_opts[i])
	elif _can_throw():
		hold_idx = i
		hold_t = 0.0

func _on_throw_up(i: int) -> void:
	if hold_idx == i and _can_throw():
		_user_throw(i, hold_t >= LOB_HOLD)
	hold_idx = -1

func _throw_input() -> void:
	for i: int in 4:
		if bool(just.get(PASS_ACTIONS[i], false)):
			hold_idx = i
			hold_t = 0.0
		if bool(just.get(PASS_ACTIONS[i] + "_up", false)) and hold_idx == i:
			_user_throw(i, hold_t >= LOB_HOLD)
			hold_idx = -1
			return
	if hold_idx >= 0 and hold_t > 0.7:
		_user_throw(hold_idx, true)
		hold_idx = -1

func _user_throw(i: int, lob: bool) -> void:
	var targets: Array = off_play.get("targets", [])
	if not _can_throw() or i >= targets.size():
		return
	var r: TTPlayer = R(poss, String(targets[i]))
	if r and not r.down:
		throw_to(r, 0.6 if carrier.vel.length_squared() > 25.0 else 0.0, lob)

func _on_menu(action: String) -> void:
	match action:
		"click":
			play_sfx("click")
		"toggle":
			if state == St.TITLE or state == St.TEAMSEL or state == St.OVER:
				return
			hud.set_menu(not hud.menu_open)
		"resume":
			hud.set_menu(false)
		"help":
			hud.show_help(true)
		"help_close":
			hud.show_help(false)
		"sound":
			save.sound = not bool(save.sound)
			_apply_sound()
			_write_save()
		"autopass":
			save.auto_pass = not bool(save.get("auto_pass", false))
			hud.set_auto_pass(bool(save.auto_pass))
			_write_save()
		"restart":
			hud.set_menu(false)
			start_game(team_idx[0], practice, int(save.difficulty))
		"title":
			hud.set_menu(false)
			goto_title()

# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	# The game loop. It runs every frame because the camera and players move every frame.
	if (bot and not demo) or fast:
		for i: int in (40 if bot else 3):
			tick(1.0 / 30.0)
	else:
		# slow devices: keep real time by taking up to three smaller steps per frame
		var dt: float = minf(delta, 0.12)
		var n: int = clampi(int(ceil(dt / 0.04)), 1, 3)
		for i: int in n:
			tick(dt / float(n))
	if not bot or demo:
		view.refresh()
		_update_tags()
		_update_hud()
	if test_hook:
		var dc: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var tris: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		var vram: int = int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
		JavaScriptBridge.eval("window.ttf={state:%d,poss:%d,down:%d,q:%d,clock:%d,s0:%d,s1:%d,ball:'%s',kind:'%s',ret:'%s',ctrl:'%s',dc:%d,tris:%d,vram:%d,conv:%s,tabs:'%s',audible:%s,fps:%d}" % [
			state, poss, down_n, quarter, int(clock), score[0], score[1], ball_state, play_kind, returning, (ctrl.role if ctrl else ""), dc, tris, vram,
			"true" if conversion else "false", ",".join(hud.tab_names) if hud.call_panel.visible else "", "true" if audible_open else "false", int(Engine.get_frames_per_second())], true)

func tick(dt: float) -> void:
	if bool(just.get("menu", false)) and not bot:
		if hud.help_panel.visible:
			hud.show_help(false)
		else:
			_on_menu("toggle")
	if hud.menu_open or hud.help_panel.visible:
		just.clear()
		hud.clear_just()
		return
	match state:
		St.PLAYCALL:
			_playcall_input()
		St.PRESNAP:
			_presnap(dt)
		St.LIVE:
			_live(dt)
		St.DEAD:
			_dead(dt)
		St.KICK:
			_kick(dt)
	if state != St.LIVE:
		for side: int in 2:
			for p: TTPlayer in players[side]:
				if state == St.KICK and p == kicker and String(kick.get("phase", "")) == "runup":
					continue
				p.want = Vector3.ZERO
				p.step(dt, false)
	_ball_follow()
	_update_camera(dt)
	hold_t += dt
	just.clear()
	hud.clear_just()

func _carrier_running(p: TTPlayer) -> bool:
	if is_kick_play() and returning == "":
		return false
	if returning != "" or play_kind != "scrim":
		return true
	if p.role != "QB":
		return true
	if String(off_play.get("type", "")) == "pass":
		return (p.position.z - los) * dirv(poss) > 0.3 or live_t > qb_t + 3.0
	return String(off_play.get("carrier", "RB")) == "QB" or qb_keep

# ---------------------------------------------------------------- option plays

func _pitch_open() -> bool:
	# The pitch is on while the QB still has the ball near the line and the back is up.
	if state != St.LIVE or play_kind != "scrim" or returning != "" or pitched or ball_state != "held":
		return false
	if String(off_play.get("option", "")) != "pitch" or carrier == null or carrier.role != "QB" or carrier.down:
		return false
	var rb: TTPlayer = R(poss, "RB")
	if rb == null or rb.down or rb.job != "pitch_man":
		return false
	return (carrier.position.z - los) * dirv(poss) < 3.0

func _pitch() -> void:
	var rb: TTPlayer = R(poss, "RB")
	pitched = true
	ball_from = ball.position
	ball_target = rb
	ball_to = rb.position
	ball_t = 0.0
	ball_T = clampf(carrier.position.distance_to(rb.position) / 18.0, 0.18, 0.4)
	ball_arc = 0.5
	ball_state = "pitch"
	var qb: TTPlayer = carrier
	carrier = null
	qb.job = "runblock"
	qb.route.clear()
	events.pitch += 1
	play_sfx("click")

func _catch_pitch() -> void:
	var rb: TTPlayer = ball_target
	ball_target = null
	carrier = rb
	ball_state = "held"
	rb.job = "carry"
	rb.route.clear()
	if human() and rb.team == 0:
		_set_ctrl(rb)

func _cpu_pitch(d: float) -> void:
	# The computer QB pitches when a free defender closes on him and the back is still behind him.
	var qb: TTPlayer = carrier
	var rb: TTPlayer = R(poss, "RB")
	if (rb.position.z - qb.position.z) * d > 0.4 or rb.position.distance_squared_to(qb.position) > 64.0:
		return
	for q: TTPlayer in players[1 - poss]:
		if q.down or q.engaged != null:
			continue
		var rel: Vector3 = q.position - qb.position
		if rel.z * d > -1.0 and rel.length_squared() < 10.0:
			_pitch()
			return

func _zone_read() -> void:
	# The QB reads the end on the keep side. If he crashes inside on the back, the QB keeps.
	var qb: TTPlayer = R(poss, "QB")
	var rb: TTPlayer = R(poss, "RB")
	var keep: Array = off_play.get("keep", [10, 0.5])
	var sx: float = signf(float(keep[0]))
	var edge: Vector3 = fw(sx * 5.0, 1.5)
	var man: TTPlayer = _nearest_def(edge, true)
	var keep_it: bool = false
	events.read += 1
	if man != null:
		# the end left the edge (crashed in or chased the back): the edge is open, so keep
		keep_it = man.position.distance_squared_to(edge) > 12.25 or man.position.distance_squared_to(rb.position) < man.position.distance_squared_to(edge)
	if randf() < 0.12:
		keep_it = not keep_it
	if keep_it:
		qb_keep = true
		carrier = qb
		qb.job = "carry"
		qb.route = [fw(float(keep[0]), float(keep[1]))]
		rb.job = "runblock"
		rb.route.clear()
		events.keep += 1
		if human() and qb.team == 0:
			_set_ctrl(qb)
			hud.say("QB keeps", 0.8)
	else:
		carrier = rb
		qb.job = "fake"
		qb.route = [fw(float(keep[0]) * 0.6, -1.0)]
		if human() and rb.team == 0:
			_set_ctrl(rb)
			hud.say("Hand off", 0.8)

func _live(dt: float) -> void:
	live_t += dt
	if not practice and not conversion:
		clock = maxf(0.0, clock - dt)
	var d: float = dirv(poss)
	var is_pass: bool = play_kind == "scrim" and returning == "" and String(off_play.get("type", "")) == "pass"
	if play_kind == "scrim" and returning == "" and String(off_play.get("type", "")) == "run" and not handed \
			and live_t >= 0.55 + float(off_play.get("delay", 0.0)):
		handed = true
		if String(off_play.get("option", "")) == "read":
			_zone_read()
		else:
			carrier = R(poss, String(off_play.get("carrier", "RB")))
	if not pursue and ball_state == "held" and carrier != null and _carrier_running(carrier):
		pursue = true
		for q: TTPlayer in players[1 - poss]:
			if q.job != "rush":
				q.react_t = randf_range(0.08, 0.3)
	var user: TTPlayer = ctrl if human() else null
	if user and ball_state == "kick" and user == returner:
		user = null
	if user and is_kick_play() and returning == "" and not kicked and user == kicker:
		user = null
	if ball_state == "loose":
		_loose_ai(user)
	else:
		for p: TTPlayer in players[poss]:
			if p != user:
				_ai_off(p, d, is_pass)
		for q: TTPlayer in players[1 - poss]:
			if q != user:
				_ai_def(q, dt, d)
		if is_pass and (not user_off() or (auto_pass() and ctrl == null)):
			_cpu_qb(d)
		if auto_pass() and ctrl == null and carrier != null and carrier.role == "QB" and _carrier_running(carrier):
			_set_ctrl(carrier)
		if _pitch_open() and carrier != user:
			_cpu_pitch(d)
	if play_kind == "scrim" or returning != "" or (play_kind == "punt" and not kicked):
		_engagements(dt, d, is_pass)
	if user:
		_user_live(user, d)
	for side: int in 2:
		for p: TTPlayer in players[side]:
			p.step(dt, true)
			if p != carrier:
				p.position.x = clampf(p.position.x, -HALF_W - 2.5, HALF_W + 2.5)
				p.position.z = clampf(p.position.z, -END - 2.0, END + 2.0)
	_separate()
	match ball_state:
		"air":
			ball_t += dt
			if ball_t >= ball_T:
				_resolve_pass()
		"kick":
			ball_t += dt
			if ball_t >= ball_T:
				_land_kick()
		"snap":
			ball_t += dt
			if ball_t >= ball_T:
				carrier = kicker
				ball_state = "held"
		"pitch":
			ball_t += dt
			if ball_target != null:
				ball_to = ball_target.position
			if ball_t >= ball_T:
				_catch_pitch()
		"loose":
			_loose_recover(dt)
	if state != St.LIVE:
		return
	if play_kind == "kickoff" and not kicked and kicker != null:
		if kicker.position.distance_squared_to(Vector3(ball_x, 0.0, los - 0.6 * d)) < 0.64:
			_kick_ball()
	if play_kind == "punt" and not kicked and ball_state == "held" and carrier == kicker and live_t >= 1.35:
		_kick_ball()
	if carrier and ball_state == "held":
		var cpos: Vector3 = carrier.position
		for q: TTPlayer in players[1 - poss]:
			if q.down or q.stun_t > 0.0 or q.engaged != null or q.tackle_cd > 0.0:
				continue
			var reach: float = 3.06 if q.dive_t > 0.0 else 1.5625
			if q.position.distance_squared_to(cpos) < reach:
				_try_tackle(q)
				if state != St.LIVE or ball_state != "held":
					return
		var cz: float = carrier.position.z * dirv(poss)
		if cz >= GOAL and (not is_kick_play() or returning != ""):
			end_play("td")
		elif absf(carrier.position.x) > HALF_W or cz < -END:
			end_play("oob")
		elif carrier.down:
			end_play("tackle")
	if state == St.LIVE and live_t > 30.0:
		end_play("tackle")

func _user_live(u: TTPlayer, d: float) -> void:
	var mv: Vector2 = _move_input()
	var wdir := Vector3(-mv.x, 0.0, mv.y)
	u.sprinting = _sprint_held()
	var sp: float = u.speed_now()
	if u.engaged != null:
		sp *= 0.2
	u.want = wdir * sp
	var dive_key: bool = bool(just.get("act_x", false)) or bool(hud.btn_just.C)
	if u.side == "off":
		if _can_throw():
			_throw_input()
		elif u == carrier and _pitch_open() and (bool(just.get("act_b", false)) or bool(just.get("act_y", false)) or bool(hud.btn_just.B)):
			_pitch()
		elif u == carrier:
			if (bool(just.get("act_b", false)) or bool(hud.btn_just.B)) and u.juke_cd <= 0.0:
				var sx: float = -signf(mv.x) if absf(mv.x) > 0.2 else (1.0 if randf() < 0.5 else -1.0)
				_juke(u, sx, d)
			if dive_key and u.dive_t <= 0.0 and not u.down:
				u.dive_t = 0.25
				u.vel = (u.face if u.vel.length_squared() > 1.0 else Vector3(0.0, 0.0, d)) * 12.5
	else:
		if bool(just.get("switch", false)) or _a_just():
			_switch_defender()
		if dive_key and u.dive_t <= 0.0 and not u.down and u.engaged == null:
			var tgt: Vector3 = carrier.position if carrier else ball_to
			var v: Vector3 = tgt - u.position
			v.y = 0.0
			u.dive_t = 0.24
			u.vel = (v.normalized() if v.length_squared() > 0.01 else u.face) * 13.5

func _juke(p: TTPlayer, sx: float, d: float) -> void:
	p.juke_t = 0.22
	p.juke_cd = 1.3
	p.juke_vec = Vector3(sx * 11.0, 0.0, d * 5.0)

# ---------------------------------------------------------------- computer players

func _go(p: TTPlayer, target: Vector3, frac: float = 1.0) -> float:
	var v: Vector3 = target - p.position
	v.y = 0.0
	var dist: float = v.length()
	p.want = (v / dist) * p.speed_now() * frac if dist > 0.35 else Vector3.ZERO
	return dist

func _nearest_def(pos: Vector3, free_only: bool = false) -> TTPlayer:
	var best: TTPlayer = null
	var bd: float = 1.0e9
	for q: TTPlayer in players[1 - poss]:
		if q.down or (free_only and (q.engaged != null or q.shed_cd > 0.0)):
			continue
		var d2: float = q.position.distance_squared_to(pos)
		if d2 < bd:
			bd = d2
			best = q
	return best

func _ai_carrier(p: TTPlayer, d: float) -> void:
	p.sprinting = true
	if p.route.size() > 0:
		if (p.position.z - los) * d > 1.0:
			p.route.clear()
		elif _go(p, p.route[0]) < 1.6:
			p.route.remove_at(0)
		return
	var steer := Vector3(0.0, 0.0, d)
	var close2: float = 1.0e9
	var close_x: float = 0.0
	for q: TTPlayer in players[1 - poss]:
		if q.down or q.engaged != null:
			continue
		var rel: Vector3 = q.position - p.position
		var ahead: float = rel.z * d
		var d2: float = rel.length_squared()
		if ahead > -1.5 and d2 < 81.0:
			var dist: float = maxf(sqrt(d2), 1.0)
			var sx: float = signf(rel.x) if absf(rel.x) > 0.25 else (1.0 if (p.get_instance_id() % 2) == 0 else -1.0)
			steer.x -= sx * 2.2 / dist
			if d2 < close2 and ahead > 0.0:
				close2 = d2
				close_x = sx
	if absf(p.position.x) > HALF_W - 3.5:
		steer.x -= signf(p.position.x) * 1.4
	steer.x = clampf(steer.x, -0.85, 0.85)
	p.want = steer.normalized() * p.speed_now()
	if close2 < 5.29 and not p.did_cpu_juke and p.juke_cd <= 0.0:
		p.did_cpu_juke = true
		if randf() < 0.22:
			_juke(p, -close_x, d)

func _ai_off(p: TTPlayer, d: float, is_pass: bool) -> void:
	p.sprinting = false
	if p.down or p.stun_t > 0.0:
		return
	if p == carrier and _carrier_running(p):
		_ai_carrier(p, d)
		return
	var run_on: bool = ball_state == "held" and carrier != null and carrier != p and _carrier_running(carrier)
	match p.job:
		"qb":
			if not is_pass or carrier != p:
				p.want = Vector3.ZERO
				return
			var spot := Vector3(p.home.x, 0.0, los - 7.5 * d)
			var rusher: TTPlayer = _nearest_def(p.position, true)
			if rusher and rusher.position.distance_squared_to(p.position) < 25.0:
				var away: Vector3 = p.position - rusher.position
				away.y = 0.0
				spot = p.position + away.normalized() * 3.0
				spot.z = clampf(spot.z * d, los * d - 11.0, los * d - 3.0) * d
			_go(p, spot, 0.8)
		"carry":
			if p.route.size() > 0:
				_go(p, p.route[0], 0.75)
			else:
				p.want = Vector3.ZERO
		"pitch_man":
			# trail the QB outside and a little behind, ready for the pitch
			var qb: TTPlayer = R(poss, "QB")
			var aim: Array = off_play.aim
			var sx: float = signf(float(aim[0]))
			var off_v: Vector3 = fw(sx * 4.5, -1.8) - fw(0.0, 0.0)
			if pitched or qb == null or qb.down or (qb.position.z - los) * d > 3.0:
				p.job = "runblock"
				return
			_go(p, qb.position + off_v)
			p.sprinting = true
		"fake":
			if p.route.size() > 0 and _go(p, p.route[0], 0.8) < 1.2:
				p.route.clear()
			if p.route.size() == 0:
				p.job = "passblock"
		"route":
			if ball_state == "air" and ball_target == p:
				_go(p, ball_to)
				p.sprinting = true
			elif run_on or (ball_state == "air" and ball_target != p):
				_block_ai(p, d)
			elif p.route.size() > 0:
				if _go(p, p.route[0]) < 0.9:
					var wp: Vector3 = p.route[0]
					p.route.remove_at(0)
					var leg: Vector3 = wp - p.route_prev
					leg.y = 0.0
					p.route_dir = leg.normalized() if leg.length_squared() > 0.01 else Vector3(0.0, 0.0, d)
					p.route_prev = wp
			elif p.route_stop:
				p.want = Vector3.ZERO
			else:
				var nx: Vector3 = p.position + p.route_dir * 3.0
				if absf(nx.x) > HALF_W - 2.0 or nx.z * d > END - 2.0:
					p.want = Vector3.ZERO
				else:
					p.want = p.route_dir * p.speed_now()
		"passblock":
			if run_on or ball_state == "air":
				_block_ai(p, d)
				return
			var qb: TTPlayer = kicker if is_kick_play() else R(poss, "QB")
			var r: TTPlayer = _nearest_def(p.position, true)
			var pocket: Vector3 = p.home + Vector3(0.0, 0.0, -1.6 * d)
			if r and qb and (r.job == "rush" or r.position.distance_squared_to(qb.position) < 81.0) and r.position.distance_squared_to(p.position) < 49.0:
				var between: Vector3 = r.position + (qb.position - r.position).normalized() * 1.0
				_go(p, between)
			else:
				_go(p, pocket, 0.6)
		"runblock":
			_block_ai(p, d)
		"kicker":
			if not kicked:
				_go(p, Vector3(ball_x, 0.0, los - 0.6 * d), 0.75)
		"punter":
			p.want = Vector3.ZERO
		"cover":
			if not kicked:
				p.want = Vector3.ZERO
			else:
				_go(p, Vector3(lerpf(p.lane_x, ball_to.x, 0.55), 0.0, ball_to.z - 6.0 * d))
				p.sprinting = true
		_:
			p.want = Vector3.ZERO

func _block_ai(p: TTPlayer, d: float) -> void:
	if p.engaged != null:
		return
	var cpos: Vector3 = carrier.position if carrier else (ball_to if ball_state == "air" else p.position)
	var best: TTPlayer = null
	var bs: float = 1.0e9
	for q: TTPlayer in players[1 - poss]:
		if q.down or q.engaged != null or q.shed_cd > 0.0:
			continue
		var d2: float = q.position.distance_squared_to(p.position)
		if d2 > 121.0:
			continue
		var s: float = d2 + q.position.distance_squared_to(cpos) * 0.25
		if s < bs:
			bs = s
			best = q
	if best:
		_go(p, best.position + (cpos - best.position).normalized() * 0.8)
	else:
		_go(p, cpos + Vector3(0.0, 0.0, d * 5.0), 0.8)

func _ai_def(p: TTPlayer, dt: float, d: float) -> void:
	p.sprinting = false
	if p.down or p.stun_t > 0.0 or p.engaged != null:
		return
	if p.react_t > 0.0:
		p.react_t -= dt
	if is_kick_play() and returning == "":
		match p.job:
			"returner":
				if kicked:
					_go(p, ball_to)
					p.sprinting = true
				else:
					p.want = Vector3.ZERO
			"retblock":
				if kicked:
					_go(p, Vector3(p.home.x * 0.55, 0.0, lerpf(p.home.z, ball_to.z, 0.55)), 0.85)
				else:
					p.want = Vector3.ZERO
			"rush":
				var tgt: Vector3 = kicker.position if kicker else Vector3(ball_x, 0.0, los)
				_go(p, tgt)
		return
	if ball_state == "air":
		if p.job == "rush" and p.position.distance_squared_to(ball_to) > 196.0:
			p.want *= 0.9
		else:
			_go(p, ball_to)
		return
	if ball_state == "pitch":
		_go(p, ball_to)
		return
	if carrier == null:
		return
	if p.job == "rush" or (pursue and p.react_t <= 0.0):
		var dist: float = p.position.distance_to(carrier.position)
		var lead: Vector3 = carrier.position + carrier.vel * clampf(dist / maxf(p.top_speed, 1.0), 0.0, 1.4)
		_go(p, lead)
		p.sprinting = dist < 12.0
		return
	match p.job:
		"man":
			var m: TTPlayer = p.man
			if m == null or m.job == "passblock" or m.job == "carry" or m.job == "fake":
				_go(p, Vector3(clampf(carrier.position.x, -8.0, 8.0), 0.0, los + 4.0 * d), 0.7)
			else:
				_go(p, m.position + m.vel * 0.3 + Vector3(0.0, 0.0, d * 0.9))
		"spy":
			var qb: TTPlayer = R(poss, "QB")
			_go(p, Vector3(qb.position.x, 0.0, los + 5.0 * d), 0.9)
		"zone":
			var tgt2: Vector3 = p.zone_spot
			var best: TTPlayer = null
			var bd: float = 90.25
			for r: TTPlayer in players[poss]:
				if r.job != "route":
					continue
				var d2: float = r.position.distance_squared_to(p.zone_spot)
				if d2 < bd:
					bd = d2
					best = r
			if best:
				tgt2 = p.zone_spot.lerp(best.position + Vector3(0.0, 0.0, d * 1.6), 0.72)
			var zdepth: float = (p.zone_spot.z - los) * d
			if zdepth >= 14.0:
				# deep zones stay over the top of the deepest receiver on their side
				var deep: TTPlayer = null
				var dz: float = zdepth - 7.0
				for r: TTPlayer in players[poss]:
					if r.job != "route" or absf(r.position.x - p.zone_spot.x) > 17.0:
						continue
					var rz: float = (r.position.z - los) * d
					if rz > dz:
						dz = rz
						deep = r
				if deep:
					tgt2 = Vector3(lerpf(p.zone_spot.x, deep.position.x, 0.8), 0.0, los + maxf(zdepth, dz + 3.0) * d)
			_go(p, tgt2, 0.92)

func _cpu_qb(d: float) -> void:
	if ball_state != "held" or carrier == null or carrier.role != "QB":
		return
	var qb: TTPlayer = carrier
	if qb.down or (qb.position.z - los) * d > 0.3:
		return
	var rusher: TTPlayer = _nearest_def(qb.position, true)
	var pressed: bool = rusher != null and rusher.position.distance_squared_to(qb.position) < 10.24
	if live_t < 0.9:
		return
	if live_t < qb_t and not pressed:
		return
	var best: TTPlayer = null
	var bo: float = -99.0
	for role: Variant in off_play.targets:
		var r: TTPlayer = R(poss, String(role))
		if r == null or r.down:
			continue
		var nd: TTPlayer = _nearest_def(r.position)
		var open: float = (nd.position.distance_to(r.position) if nd else 20.0) - qb.position.distance_to(r.position) * 0.05
		if (r.position.z - los) * d < -1.0:
			open -= 2.0
		if open > bo:
			bo = open
			best = r
	if best and (bo > 1.6 or live_t > qb_t + 1.0 or pressed):
		var err: float = 1.6 if pressed else 0.5
		if human() and poss == 1:
			err = maxf(0.0, err + float(diff.qb_err))
		throw_to(best, err, (best.position.z - los) * d > 16.0)

func _engagements(dt: float, d: float, is_pass: bool) -> void:
	for b: TTPlayer in players[poss]:
		if b == carrier or b.down or b.stun_t > 0.0 or b.engaged != null:
			continue
		var blocking: bool = b.job == "passblock" or b.job == "runblock"
		if b.job == "route" and ball_target != b and (ball_state != "held" or carrier == null or carrier.role != "QB"):
			blocking = true
		if not blocking:
			continue
		for q: TTPlayer in players[1 - poss]:
			if q.down or q.engaged != null or q.shed_cd > 0.0 or q.stun_t > 0.0 or q.dive_t > 0.0:
				continue
			if q.position.distance_squared_to(b.position) < 1.96:
				b.engaged = q
				q.engaged = b
				var big: bool = b.role in ["LT", "LG", "C", "RG", "RT", "TE"]
				if is_pass and not pursue:
					q.block_t = randf_range(2.6, 4.4) if big else randf_range(0.9, 1.8)
				else:
					q.block_t = randf_range(0.9, 1.9) if big else randf_range(0.4, 0.9)
				q.block_t *= float(tm(poss).power) / float(tm(1 - poss).power)
				break
	for q: TTPlayer in players[1 - poss]:
		if q.engaged == null:
			continue
		var b2: TTPlayer = q.engaged
		q.block_t -= dt * (1.8 if (human() and q == ctrl) else 1.0)
		if carrier and ball_state == "held" and pursue and q.position.distance_squared_to(carrier.position) < 5.76:
			q.block_t -= dt * 2.0
		if q.block_t <= 0.0 or b2.down or q.down:
			q.engaged = null
			b2.engaged = null
			q.shed_cd = 3.0
			b2.stun_t = maxf(b2.stun_t, 0.5)
			continue
		var push := Vector3(0.0, 0.0, d * 1.1)
		if is_pass and not pursue and carrier:
			push = carrier.position - q.position
			push.y = 0.0
			push = push.normalized() * 0.9
		q.want = push
		b2.want = push
		var gap: Vector3 = b2.position - q.position
		gap.y = 0.0
		if gap.length_squared() > 1.5625:
			b2.want += -gap.normalized() * 3.0

func _separate() -> void:
	var all: Array = players[0] + players[1]
	for i: int in all.size():
		var a: TTPlayer = all[i]
		if a.down:
			continue
		for j: int in range(i + 1, all.size()):
			var b: TTPlayer = all[j]
			if b.down:
				continue
			var v: Vector3 = b.position - a.position
			v.y = 0.0
			var d2: float = v.length_squared()
			if d2 < 0.9025 and d2 > 0.000001:
				var dist: float = sqrt(d2)
				var push: Vector3 = v / dist * (0.95 - dist) * 0.5
				a.position -= push
				b.position += push

func _loose_ai(user: TTPlayer) -> void:
	for side: int in 2:
		for p: TTPlayer in players[side]:
			if p == user or p.down or p.stun_t > 0.0:
				continue
			_go(p, ball_to)
			p.sprinting = true
	if user:
		_user_live(user, dirv(poss))

func _loose_recover(dt: float) -> void:
	loose_t += dt
	if loose_t < 0.6:
		return
	var best: TTPlayer = null
	var bd: float = 1.44
	for side: int in 2:
		for p: TTPlayer in players[side]:
			if p.down:
				continue
			var d2: float = p.position.distance_squared_to(ball_to)
			if d2 < bd:
				bd = d2
				best = p
	if best == null:
		if loose_t < 5.0:
			return
		best = _nearest_of(players[0] + players[1], ball_to)
	if conversion:
		end_play("incomplete")
		return
	if best.team == poss:
		carrier = best
		ball_state = "held"
		pursue = true
		if is_kick_play() and returning == "":
			returning = "muff"
		for p: TTPlayer in players[poss]:
			p.job = "carry" if p == best else "runblock"
			p.route.clear()
		for q: TTPlayer in players[1 - poss]:
			q.job = "rush"
		if human() and best.team == 0:
			_set_ctrl(best)
		hud.say("Recovered by %s" % String(tm(poss).abbr), 1.2)
	else:
		flip_live(best, "fumble")
		hud.say("Recovered by %s!" % String(tm(best.team).abbr), 1.4, hud.GOLD)
		play_sfx("cheer")

func _try_tackle(q: TTPlayer) -> void:
	q.tackle_cd = 0.9
	var bc: TTPlayer = carrier
	if bc.juke_t > 0.0:
		if randf() < 0.6:
			q.fall(1.3)
		return
	var p: float = 0.88
	if human() and bc.team == 0 and q.team == 1:
		p = float(diff.tackle)
	p *= float(tm(q.team).power) / float(tm(bc.team).power)
	if q.dive_t > 0.0:
		p += 0.15
	if bc.sprinting and bc.burst > 0.0:
		p -= 0.04
	if human():
		if bc == ctrl:
			p -= 0.05
		if q == ctrl:
			p += 0.12
	if bc.role == "QB" and play_kind == "scrim" and returning == "" and (bc.position.z - los) * dirv(poss) < 0.0:
		p += 0.12
	if randf() < p:
		bc.fall(4.0)
		q.fall(0.8)
		play_sfx("hit")
		if randf() < 0.012 and bc.role != "QB" and not conversion:
			_fumble(bc.position)
		else:
			end_play("tackle")
	else:
		q.fall(1.2)
		play_sfx("hit")
		if human() and bc == ctrl:
			hud.say("Broken tackle!", 0.9, hud.GOLD)

# ---------------------------------------------------------------- passing

func throw_to(r: TTPlayer, err: float, lob: bool) -> void:
	var qb: TTPlayer = carrier
	qb.throw_t = 0.35
	ball_from = qb.position + Vector3(0.0, 2.0, 0.0)
	var target: Vector3 = r.position
	var T: float = 0.6
	var stopped: bool = r.job == "route" and r.route.size() == 0 and r.route_stop
	for i: int in 3:
		var dist: float = ball_from.distance_to(target)
		T = maxf(0.42, dist / (20.0 + minf(dist, 32.0) * 0.28))
		T *= 1.45 if lob else 0.92
		target = r.position + (Vector3.ZERO if stopped else r.vel * T * 0.92)
	if err > 0.0:
		target += Vector3(randf_range(-err, err), 0.0, randf_range(-err, err))
	target.x = clampf(target.x, -HALF_W + 0.6, HALF_W - 0.6)
	target.z = clampf(target.z, -END + 0.8, END - 0.8)
	target.y = 0.0
	var span: float = ball_from.distance_to(target)
	ball_to = target
	ball_T = T
	ball_t = 0.0
	ball_arc = (2.5 + span * 0.2) if lob else (0.8 + span * 0.07)
	ball_lob = lob
	ball_state = "air"
	ball_target = r
	carrier = null
	if lob:
		events.lob += 1
	if human() and poss == 1:
		_set_ctrl(_nearest_of(players[0], ball_to))

func _resolve_pass() -> void:
	var r: TTPlayer = ball_target
	var rd2: float = r.position.distance_squared_to(ball_to) if (r and not r.down) else 9999.0
	var nd: TTPlayer = null
	var dd2: float = 9999.0
	for q: TTPlayer in players[1 - poss]:
		if q.down or q.engaged != null:
			continue
		var x2: float = q.position.distance_squared_to(ball_to)
		if x2 < dd2:
			dd2 = x2
			nd = q
	var rd: float = sqrt(rd2)
	var dd: float = sqrt(dd2)
	var pint: float = 0.0
	var pcatch: float = 0.0
	if rd > 2.1:
		if dd < 1.3:
			pint = 0.3
	else:
		var hands: float = float(tm(poss).hands)
		if human() and poss == 1:
			hands *= float(diff.hands)
		pcatch = (0.93 - maxf(0.0, ball_from.distance_to(ball_to) - 24.0) * 0.014) * hands
		if dd < 2.3:
			var k: float = 1.0 - dd / 2.3
			pcatch -= 0.62 * k
			pint = 0.06 * k + (0.07 if dd < rd else 0.0)
	if ball_lob:
		pint *= 0.45
		pcatch -= 0.05
	if human() and nd != null and nd == ctrl:
		pint *= 1.8
	var roll: float = randf()
	if roll < pint and nd != null:
		if conversion:
			ball_state = "dead"
			end_play("incomplete")
			return
		events["int"] += 1
		stats[poss].to += 1
		flip_live(nd, "int")
		hud.say("INTERCEPTED!", 1.3, hud.GOLD)
		play_sfx("cheer")
		return
	if roll < pint + pcatch:
		carrier = r
		ball_state = "held"
		r.job = "carry"
		r.route.clear()
		events.comp += 1
		if user_off():
			_set_ctrl(r)
		return
	carrier = null
	ball_state = "dead"
	ball.position = ball_to + Vector3(0.0, 0.3, 0.0)
	end_play("incomplete")

func _ball_follow() -> void:
	if state == St.KICK and String(kick.get("phase", "")) == "fly":
		return
	match ball_state:
		"air", "kick", "snap", "pitch":
			var k: float = clampf(ball_t / ball_T, 0.0, 1.0)
			var lift: float = 1.4
			if ball_state == "kick":
				lift = 0.3
			elif ball_state == "pitch":
				lift = 1.1
			elif ball_state == "snap":
				lift = 1.2
			ball.position = ball_from.lerp(ball_to + Vector3(0.0, lift, 0.0), k) + Vector3(0.0, sin(k * PI) * ball_arc, 0.0)
			var v: Vector3 = ball_to - ball_from
			ball.rotation.y = atan2(v.x, v.z)
		"loose":
			var k2: float = clampf(loose_t / 0.7, 0.0, 1.0)
			ball.position = ball_from.lerp(ball_to + Vector3(0.0, 0.25, 0.0), k2) + Vector3(0.0, absf(sin(k2 * PI * 2.0)) * 1.2 * (1.0 - k2), 0.0)
			ball.rotation.y += 0.3
		"held":
			if carrier:
				ball.position = carrier.position + Vector3(0.0, 0.5 if carrier.down else 1.3, 0.0) + carrier.face * 0.45
				ball.rotation.y = carrier.rotation.y

# ---------------------------------------------------------------- results

func end_play(kind: String) -> void:
	var d: float = dirv(poss)
	state = St.DEAD
	dead_t = 2.3
	pending = "play"
	play_sfx("whistle")
	hud.show_throw(false, PackedStringArray())
	hold_idx = -1
	var spot: float = carrier.position.z if carrier else los
	var sx: float = carrier.position.x if carrier else ball_x
	var msg: String = ""
	var col: Color = Color.WHITE
	if verbose:
		print("PLAY %s %s vs %s kind %s gain %.1f t %.1f ret %s" % [String(off_play.get("id", "")), play_kind, String(def_play.get("id", "")), kind, (spot - los) * d, live_t, returning])
	if practice:
		match kind:
			"td":
				msg = "Touchdown!"
			"incomplete":
				msg = "Incomplete"
			_:
				msg = "Turnover" if returning != "" else "%+d yards" % int(round((spot - los) * d))
		hud.say(msg, 2.0)
		poss = 0
		los = -20.0
		first_z = -10.0
		down_n = 1
		ball_x = 0.0
		return
	if conversion:
		conversion = false
		events.two_try += 1
		if kind == "td" and returning == "" and poss == conv_team:
			score[conv_team] += 2
			events.two_good += 1
			msg = "TWO-POINT TRY IS GOOD!"
			col = hud.GOLD
			play_sfx("cheer")
		else:
			msg = "Two-point try fails"
		pending = "kick%d" % conv_team
		hud.say(msg, 2.2, col)
		return
	match kind:
		"td":
			score[poss] += 6
			events.td += 1
			stats[poss].td += 1
			if returning == "":
				stats[poss].yards += GOAL - los * d
				msg = "TOUCHDOWN %s!" % String(tm(poss).name).to_upper()
			else:
				events.ret_td += 1
				msg = "RETURN TOUCHDOWN %s!" % String(tm(poss).name).to_upper()
			col = hud.GOLD
			play_sfx("cheer")
			pending = "over" if quarter >= 5 else "pat"
			for p: TTPlayer in players[poss]:
				p.cheer = true
		"touchback":
			var recv: int = 1 - poss
			var rd: float = dirv(recv)
			poss = recv
			los = -(GOAL - (25.0 if play_kind == "kickoff" else 20.0)) * rd
			ball_x = 0.0
			down_n = 1
			first_z = los + 10.0 * rd
			events.touchback += 1
			msg = "Touchback"
		"incomplete":
			events.inc += 1
			msg = "Incomplete"
			_next_down(los, ball_x)
		"tackle", "oob":
			if returning != "":
				msg = _end_return(spot, sx)
			elif play_kind == "punt":
				msg = "Punter tackled! Turnover"
				_flip(spot, sx)
			else:
				var gain: float = (spot - los) * d
				if spot * d <= -GOAL:
					score[1 - poss] += 2
					events.safety += 1
					msg = "SAFETY! 2 points %s" % String(tm(1 - poss).abbr)
					col = hud.GOLD
					pending = "over" if quarter >= 5 else "free%d" % poss
				else:
					stats[poss].yards += gain
					var sack: bool = String(off_play.get("type", "")) == "pass" and carrier != null and carrier.role == "QB" and gain < 0.0
					if sack:
						events.sack += 1
						msg = "SACKED! %d yards" % int(round(gain))
					elif absf(gain) >= 0.5:
						msg = "%+d yards" % int(round(gain))
					else:
						msg = "No gain"
					if kind == "oob":
						msg += ", out of bounds"
					else:
						clock = maxf(0.0, clock - 15.0)
					var note: String = _next_down(spot, sx)
					if note != "":
						msg += ". " + note
						if note.begins_with("First"):
							col = hud.GOLD
	if kind == "oob" and returning != "":
		msg += ", out of bounds"
	hud.say(msg, 2.2, col)

func _end_return(spot: float, sx: float) -> String:
	var d: float = dirv(poss)
	var msg: String = ""
	var z: float = spot
	if z * d <= -GOAL:
		var tb: float = 25.0 if (returning == "kick" and play_kind == "kickoff") else 20.0
		z = -(GOAL - tb) * d
		msg = "Touchback"
	los = z
	ball_x = clampf(sx, -6.0, 6.0)
	down_n = 1
	first_z = los + 10.0 * d
	if first_z * d > GOAL:
		first_z = GOAL * d
	if msg == "":
		var lead: String = "Return to" if returning == "kick" else "%s ball at" % String(tm(poss).abbr)
		msg = "%s %s" % [lead, yard_txt()]
	return msg

func _next_down(spot: float, x: float) -> String:
	var d: float = dirv(poss)
	los = spot
	ball_x = clampf(x, -6.0, 6.0)
	if (los - first_z) * d >= -0.01:
		down_n = 1
		first_z = los + 10.0 * d
		if first_z * d > GOAL:
			first_z = GOAL * d
		return "First down!"
	down_n += 1
	if down_n > 4:
		events.downs += 1
		stats[poss].to += 1
		_flip(los, ball_x)
		return "Turnover on downs"
	return ""

func _flip(spot_z: float, x: float) -> void:
	poss = 1 - poss
	var d: float = dirv(poss)
	var z: float = spot_z
	if z * d < -(GOAL - 1.0):
		z = -(GOAL - 20.0) * d
	los = z
	ball_x = clampf(x, -6.0, 6.0)
	down_n = 1
	first_z = los + 10.0 * d
	if first_z * d > GOAL:
		first_z = GOAL * d

func _dead(dt: float) -> void:
	dead_t -= dt * (6.0 if bot else 1.0)
	if dead_t > 0.0:
		return
	for side: int in 2:
		for p: TTPlayer in players[side]:
			p.cheer = false
	if pending == "over":
		_game_over()
		return
	if pending == "pat":
		_start_pat()
		return
	if not practice and clock <= 0.0:
		if quarter == 4 and score[0] == score[1]:
			quarter = 5
			clock = QLEN
			events.ot += 1
			pending = "kick%d" % (randi() % 2)
			hud.say("Overtime. Next score wins", 2.4, hud.GOLD)
		elif quarter >= 4:
			_game_over()
			return
		else:
			quarter += 1
			clock = QLEN
			if quarter == 3:
				pending = "kick%d" % (1 - opening_kicker)
				hud.say("Halftime", 2.0)
			else:
				hud.say("End of quarter %d" % (quarter - 1), 1.8)
	if pending.begins_with("kick"):
		var s: int = int(pending.substr(4))
		pending = "play"
		setup_kickoff(s, -15.0)
		return
	if pending.begins_with("free"):
		var s2: int = int(pending.substr(4))
		pending = "play"
		setup_kickoff(s2, -30.0)
		return
	goto_playcall()

func _start_pat() -> void:
	var scorer: int = poss
	if human() and scorer == 0:
		state = St.PLAYCALL
		hud.pad_active = false
		hud.update_pad()
		var cards: Array = [_special("xp", "Extra Point", "Kick for 1 point"), _special("two", "Go for Two", "One play from the 3")]
		hud.show_call("Touchdown! Kick the extra point or go for two?", {"Try": cards}, PackedStringArray(["Try"]), "Try")
		hud.hint.text = "1 kicks, 2 goes for two"
		return
	var lead_after: int = score[scorer] - score[1 - scorer]
	if quarter >= 4 and lead_after in [-2, -5, -10, 1, 5]:
		_start_two()
	else:
		_start_kick(true)

func _start_two() -> void:
	conversion = true
	conv_team = poss
	var d: float = dirv(poss)
	los = (GOAL - 3.0) * d
	ball_x = 0.0
	down_n = 1
	first_z = GOAL * d
	goto_playcall()

func _game_over() -> void:
	state = St.OVER
	hud.pad_active = false
	hud.update_pad()
	hud.hide_call()
	hud.hint.text = ""
	var res: String = "Tie game"
	if score[0] > score[1]:
		res = "You win!" if quarter < 5 else "You win in overtime!"
		save.wins = int(save.wins) + 1
	elif score[0] < score[1]:
		res = "%s win" % String(tm(1).name)
		save.losses = int(save.losses) + 1
	else:
		save.ties = int(save.ties) + 1
	_write_save()
	if bot:
		bot_done += 1
		print("BOT game %d final %d-%d plays %d yards %d/%d events %s" % [bot_done, score[0], score[1], events.plays, int(stats[0].yards), int(stats[1].yards), JSON.stringify(events)])
		if bot_done >= bot_games:
			print("BOT done games %d" % bot_done)
			get_tree().quit()
		else:
			start_game(bot_done % 4, false, 1)
		return
	var t: String = "%s %d\n%s %d\n\n%s\n\nYards: %d to %d    Turnovers: %d to %d\nYour record: %d wins, %d losses, %d ties" % [String(tm(0).name), score[0], String(tm(1).name), score[1], res,
		int(stats[0].yards), int(stats[1].yards), int(stats[0].to), int(stats[1].to), int(save.wins), int(save.losses), int(save.ties)]
	play_sfx("cheer")
	hud.show_over(t)
	crowd.stop()
	if audio_ok and not music.playing:
		music.play()

# ---------------------------------------------------------------- field goals and extra points

func _start_kick(xp: bool) -> void:
	var d: float = dirv(poss)
	for side: int in 2:
		for p: TTPlayer in players[side]:
			p.cheer = false
	if xp:
		los = (GOAL - 15.0) * d
		ball_x = 0.0
		first_z = GOAL * d
	play_kind = "fg"
	kick = {"xp": xp}
	off_play = {"id": "fg", "name": "Field Goal", "type": "kick"}
	def_play = {"id": "fg_rush", "name": "Block", "jobs": {}}
	_place_formation()
	var holder: TTPlayer = R(poss, "QB")
	holder.kneel = true
	holder.step(0.0, false)
	kicker = R(poss, "RB")
	var origin: Vector3 = fw(0.0, -6.4) + Vector3(0.0, 0.3, 0.0)
	var dist: float = fg_dist()
	kick = {"phase": "aim", "t": 0.0, "xp": xp, "dist": dist, "from": origin, "good": false, "fly": 0.0, "to": Vector3.ZERO, "start": kicker.position}
	state = St.KICK
	carrier = null
	ball_state = "dead"
	ball.position = origin
	hud.hide_call()
	hud.pad_active = human()
	hud.update_pad()
	if user_off():
		hud.set_meter(true, clampf(0.2 - dist * 0.0028, 0.045, 0.16), 0.42)
		hud.hint.text = "%s: stop the marker in the green. Space, A or tap" % ("Extra point" if xp else "%d yard field goal" % int(dist))
	else:
		kick.good = randf() < clampf(1.12 - dist * 0.012, 0.25, 0.97)
		kick.t = -0.9
	_update_hud()

func _kick(dt: float) -> void:
	var d: float = dirv(poss)
	var phase: String = String(kick.phase)
	if phase == "aim":
		kick.t = float(kick.t) + dt
		if user_off():
			hud.meter_pos = 0.5 + 0.5 * sin(float(kick.t) * (3.0 + float(kick.dist) * 0.035))
			hud.meter.queue_redraw()
			if (_a_just() or bool(hud.btn_just.B) or bool(hud.btn_just.C)) and float(kick.t) > 0.3:
				kick.good = absf(hud.meter_pos - 0.5) <= hud.meter_half
				kick.phase = "runup"
				kick.t = 0.0
				hud.set_meter(false, 0.1)
				hud.hint.text = ""
		elif float(kick.t) >= 0.0:
			kick.phase = "runup"
			kick.t = 0.0
	elif phase == "runup":
		kick.t = float(kick.t) + dt
		var k: float = clampf(float(kick.t) / 0.4, 0.0, 1.0)
		var origin: Vector3 = kick.from
		var spot := Vector3(origin.x, 0.0, origin.z - 0.7 * d)
		kicker.position = (kick.start as Vector3).lerp(spot, k)
		kicker.face = Vector3(0.0, 0.0, d)
		kicker.step(dt, false)
		if k >= 1.0:
			kicker.kick_t = 0.3
			kick.phase = "fly"
			kick.fly = 0.0
			play_sfx("kick")
			var miss_x: float = (1.0 if randf() < 0.5 else -1.0) * randf_range(4.6, 8.0)
			kick.to = Vector3(randf_range(-1.6, 1.6) if bool(kick.good) else miss_x, 6.5, (END + 0.6) * d)
	elif phase == "fly":
		kick.fly = float(kick.fly) + dt / 1.5 * (5.0 if bot else 1.0)
		var k2: float = clampf(float(kick.fly), 0.0, 1.0)
		ball.position = (kick.from as Vector3).lerp(kick.to as Vector3, k2) + Vector3(0.0, sin(k2 * PI) * 8.0, 0.0)
		ball.rotation.x += dt * 14.0
		if k2 >= 1.0:
			kick.phase = "done"
			ball.rotation.x = 0.0
			state = St.DEAD
			dead_t = 1.9
			if bool(kick.xp):
				if bool(kick.good):
					score[poss] += 1
					events.xp += 1
				hud.say("Extra point is good!" if bool(kick.good) else "Extra point missed", 1.8)
				pending = "kick%d" % poss
			elif bool(kick.good):
				score[poss] += 3
				events.fg += 1
				hud.say("FIELD GOAL %s! %d yards" % [String(tm(poss).abbr), int(float(kick.dist))], 2.0, hud.GOLD)
				play_sfx("cheer")
				pending = "over" if quarter >= 5 else "kick%d" % poss
				clock = maxf(0.0, clock - 5.0)
			else:
				hud.say("No good!", 1.8)
				var spot2: float = los
				if GOAL - los * d < 20.0:
					spot2 = (GOAL - 20.0) * d
				_flip(spot2, 0.0)
				pending = "play"
				clock = maxf(0.0, clock - 5.0)

# ---------------------------------------------------------------- camera, labels and the ring

func _update_camera(dt: float) -> void:
	var focus := Vector3(ball_x, 0.0, los)
	var h: float = 15.0
	var back: float = 20.0
	if state == St.LIVE or state == St.DEAD:
		if ball_state == "air" or ball_state == "kick" or ball_state == "loose" or ball_state == "snap" or ball_state == "pitch":
			focus = ball.position
			focus.y = 0.0
		elif carrier:
			focus = carrier.position
		if state == St.LIVE and play_kind == "scrim" and returning == "" and String(off_play.get("type", "")) == "pass" \
				and carrier != null and carrier.role == "QB" and not _carrier_running(carrier):
			h = 21.0
			back = 23.0
			focus = Vector3(ball_x * 0.6 + carrier.position.x * 0.4, 0.0, los)
		if ball_state == "kick":
			h = 19.0
			back = 24.0
	elif state == St.PRESNAP or state == St.PLAYCALL:
		h = 19.0
		back = 22.0
		if play_kind == "kickoff" and poss == 0:
			# near side kicks: frame the kicker, the whole kicking line and the return team
			focus = Vector3(0.0, 0.0, los + 6.0)
			h = 24.0
			back = 30.0
		elif play_kind == "kickoff":
			focus = Vector3(0.0, 0.0, los + 12.0 * dirv(poss))
		elif is_kick_play() and poss == 0:
			# near side punts or kicks: keep the punter or kicker on screen
			focus = Vector3(0.0, 0.0, los - 3.0)
			h = 22.0
			back = 28.0
	elif state == St.KICK:
		focus = Vector3(0.0, 0.0, los + 10.0 * dirv(poss))
		h = 14.0
		back = 24.0
		if poss == 0:
			# low and behind the kicker so the run-up and the posts both show
			focus = Vector3(0.0, 0.0, los + 4.0)
			h = 12.0
			back = 30.0
	else:
		h = 11.0
		back = 30.0
		focus = Vector3(sin(Time.get_ticks_msec() * 0.0001) * 8.0, 0.0, los)
	if human() and poss == 1 and play_kind == "scrim" and returning == "" and (state == St.PRESNAP or state == St.LIVE or state == St.PLAYCALL):
		back += 7.0
	cam_focus = cam_focus.lerp(focus, minf(1.0, dt * 5.0))
	var want_pos := Vector3(cam_focus.x * 0.92, h, cam_focus.z - back)
	cam.position = cam.position.lerp(want_pos, minf(1.0, dt * 4.0))
	cam.look_at(Vector3(cam_focus.x * 0.96, 0.0, cam_focus.z + 6.0), Vector3.UP)
	# the camera always looks up the field, so the near posts only ever block the view
	post_near.visible = cam.position.z > -(END + 0.6) + 3.0

func _update_tags() -> void:
	var names: PackedStringArray = PackedStringArray(["A", "B", "X", "Y"]) if pad_last else PackedStringArray(["1", "2", "3", "4"])
	var tagged: Dictionary = {}
	var pass_play: bool = user_off() and play_kind == "scrim" and returning == "" and String(off_play.get("type", "")) == "pass"
	if pass_play and (state == St.PRESNAP or _can_throw()):
		var targets: Array = off_play.get("targets", [])
		for i: int in mini(4, targets.size()):
			var role: String = String(targets[i])
			var r: TTPlayer = R(0, role)
			if r == null:
				continue
			var t: String = names[i]
			if state == St.PRESNAP and hot_routes.has(role):
				t += " " + String(hot_routes[role]).to_upper()
			tagged[r] = t
	for side: int in 2:
		for p: TTPlayer in players[side]:
			p.set_tag(String(tagged.get(p, "")))
	var labels := PackedStringArray()
	if hud.touch_seen:
		if state == St.PRESNAP and audible_open:
			for o: Dictionary in audible_opts:
				labels.append(String(o.name))
		elif _can_throw():
			for i: int in mini(4, (off_play.targets as Array).size()):
				labels.append(str(i + 1))
	hud.show_throw(labels.size() > 0, labels)
	if state == St.LIVE and ctrl != null:
		if ctrl.side == "off":
			hud.set_pad_labels("Sprint", "Pitch" if (ctrl == carrier and _pitch_open()) else "Juke", "Dive")
		else:
			hud.set_pad_labels("Switch", "", "Tackle")
	elif state == St.KICK or (state == St.PRESNAP and is_kick_play()):
		hud.set_pad_labels("Kick" if poss == 0 else "", "", "")
	elif state == St.PRESNAP:
		if poss == 0:
			hud.set_pad_labels("Snap", "Audible", "")
		else:
			hud.set_pad_labels("Switch", "", "")
	ring.visible = ctrl != null and (state == St.PRESNAP or state == St.LIVE or state == St.DEAD)
	if ring.visible:
		ring.position = ctrl.position + Vector3(0.0, 0.12, 0.0)
