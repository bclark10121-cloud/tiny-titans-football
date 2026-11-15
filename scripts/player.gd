extends Node3D
class_name TTPlayer
# One football player: movement, play state and pose. It draws nothing itself.
# SquadView reads the pose (lean, body_y, legs, arms) and draws every player with shared MultiMeshes.
# Movement is plain maths (no physics body): main.gd sets `want` and this node eases towards it.

var team: int = 0
var idx: int = 0
var view_i: int = 0
var role: String = ""
var side: String = "off"
var big: float = 1.0
var top_speed: float = 8.0
var want: Vector3 = Vector3.ZERO
var vel: Vector3 = Vector3.ZERO
var accel: float = 34.0
var face: Vector3 = Vector3(0.0, 0.0, 1.0)

# play state
var job: String = ""
var route: Array[Vector3] = []
var route_prev: Vector3 = Vector3.ZERO
var route_stop: bool = false
var route_dir: Vector3 = Vector3.ZERO
var man: TTPlayer = null
var zone_spot: Vector3 = Vector3.ZERO
var lane_x: float = 0.0
var home: Vector3 = Vector3.ZERO
var engaged: TTPlayer = null
var block_t: float = 0.0
var shed_cd: float = 0.0
var stun_t: float = 0.0
var down: bool = false
var react_t: float = 0.0
var tackle_cd: float = 0.0
var juke_t: float = 0.0
var juke_cd: float = 0.0
var juke_vec: Vector3 = Vector3.ZERO
var dive_t: float = 0.0
var burst: float = 1.0
var sprinting: bool = false
var throw_t: float = 0.0
var kick_t: float = 0.0
var kneel: bool = false
var cheer: bool = false
var did_cpu_juke: bool = false

# pose, read by SquadView
var lean: float = 0.0
var body_y: float = 0.0
var legs: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])
var arms: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])

var _phase: float = 0.0
var _tag: Label3D
var _tag_text: String = ""

func _ready() -> void:
	_tag = Label3D.new()
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	_tag.fixed_size = true
	_tag.pixel_size = 0.0011
	_tag.font_size = 44
	_tag.outline_size = 14
	_tag.position = Vector3(0.0, 3.3, 0.0)
	_tag.modulate = Color(1.0, 0.95, 0.3)
	_tag.visible = false
	add_child(_tag)

func set_tag(t: String) -> void:
	if t == _tag_text:
		return
	_tag_text = t
	_tag.visible = t != ""
	_tag.text = t

func reset_play() -> void:
	job = ""
	route.clear()
	route_stop = false
	route_dir = Vector3.ZERO
	man = null
	engaged = null
	block_t = 0.0
	shed_cd = 0.0
	stun_t = 0.0
	down = false
	react_t = 0.0
	tackle_cd = 0.0
	juke_t = 0.0
	juke_cd = 0.0
	dive_t = 0.0
	burst = 1.0
	sprinting = false
	throw_t = 0.0
	kick_t = 0.0
	kneel = false
	cheer = false
	did_cpu_juke = false
	want = Vector3.ZERO
	vel = Vector3.ZERO
	set_tag("")

func speed_now() -> float:
	if sprinting and burst > 0.0:
		return top_speed * 1.16
	return top_speed

func fall(t: float) -> void:
	stun_t = maxf(stun_t, t)
	down = true
	engaged = null

func step(dt: float, live: bool) -> void:
	shed_cd = maxf(0.0, shed_cd - dt)
	tackle_cd = maxf(0.0, tackle_cd - dt)
	juke_cd = maxf(0.0, juke_cd - dt)
	throw_t = maxf(0.0, throw_t - dt)
	kick_t = maxf(0.0, kick_t - dt)
	if stun_t > 0.0:
		stun_t -= dt
		if stun_t <= 0.0 and live:
			down = false
	if sprinting and want.length_squared() > 0.25:
		burst = maxf(0.0, burst - dt / 2.6)
	else:
		burst = minf(1.0, burst + dt / 4.0)
	var target: Vector3 = want
	if down or stun_t > 0.0:
		target = Vector3.ZERO
	if juke_t > 0.0:
		juke_t -= dt
		vel = juke_vec
	elif dive_t > 0.0:
		dive_t -= dt
		if dive_t <= 0.0:
			fall(0.9)
	else:
		vel = vel.move_toward(target, accel * dt)
	position += vel * dt
	position.y = 0.0
	var sp2: float = vel.length_squared()
	if sp2 > 0.16:
		face = face.lerp(vel / sqrt(sp2), minf(1.0, dt * 12.0)).normalized()
	rotation.y = atan2(face.x, face.z)
	_pose(dt, sqrt(sp2))

func _pose(dt: float, sp: float) -> void:
	_phase += dt * (4.0 + sp * 1.25)
	var sw: float = clampf(sp / 8.0, 0.0, 1.0) * 0.95
	var lying: bool = down and dive_t <= 0.0
	var want_lean: float = sw * 0.22
	if lying:
		want_lean = 1.45
	elif dive_t > 0.0:
		want_lean = 1.1
	elif kneel:
		want_lean = 0.0
	lean = lerpf(lean, want_lean, minf(1.0, dt * 14.0))
	if lying:
		body_y = 0.25
	elif kneel:
		body_y = -0.5
	elif cheer:
		body_y = absf(sin(_phase * 0.9)) * 0.5
	else:
		body_y = absf(sin(_phase)) * 0.06 * sw
	for i: int in 2:
		legs[i] = sin(_phase + PI * i) * sw
	if kneel:
		legs[0] = -1.4
		legs[1] = 0.2
	if kick_t > 0.0:
		legs[0] = -1.6 + (0.3 - kick_t) * 2.0
	for i: int in 2:
		var a: float = sin(_phase + PI * (1 - i)) * sw * 0.9
		if cheer:
			a = -2.7
		elif throw_t > 0.0 and i == 0:
			a = -2.6 + (0.35 - throw_t) * 5.0
		elif engaged != null:
			a = -1.4
		elif kneel:
			a = -0.9
		arms[i] = a
