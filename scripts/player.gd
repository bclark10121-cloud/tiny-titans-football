extends Node3D
class_name TTPlayer
# One football player. Built from simple shapes in code: big helmet, pads, arms and legs.
# Movement is plain maths (no physics body): main.gd sets `want` and this node eases towards it.

var team := 0            # 0 or 1
var role := ""           # QB, RB, WR1, LT, DE1, LB2, CB1 ...
var side := "off"        # "off" or "def" for the current play
var top_speed := 8.0     # yards per second
var want := Vector3.ZERO # wanted velocity
var vel := Vector3.ZERO
var accel := 34.0
var face := Vector3(0, 0, 1)

# play state
var job := ""            # rush, man:WR1, zone:x,z, route, block, carry, qb
var route: Array = []    # world points still to run
var route_stop := false
var route_dir := Vector3.ZERO
var man: TTPlayer = null
var zone_spot := Vector3.ZERO
var home := Vector3.ZERO
var engaged: TTPlayer = null   # who this player is locked in a block with
var block_t := 0.0
var shed_cd := 0.0             # cannot be blocked again for this long
var stun_t := 0.0              # on the ground or off balance
var down := false              # tackled or fallen
var react_t := 0.0             # delay before a defender reacts
var tackle_cd := 0.0
var juke_t := 0.0
var juke_cd := 0.0
var juke_vec := Vector3.ZERO
var dive_t := 0.0
var burst := 1.0               # sprint meter 0..1
var sprinting := false
var throw_t := 0.0
var cheer := false
var did_cpu_juke := false

var _phase := 0.0
var _lean := 0.0
var _body: Node3D
var _legs: Array = []
var _arms: Array = []
var _ring: MeshInstance3D
var _tag: Label3D

static var _mesh_cache := {}

static func _box(sz: Vector3) -> BoxMesh:
	var k := "b%s" % sz
	if not _mesh_cache.has(k):
		var m := BoxMesh.new(); m.size = sz; _mesh_cache[k] = m
	return _mesh_cache[k]

static func mat(c: Color, rough := 0.8) -> StandardMaterial3D:
	var k := "m%s%s" % [c.to_html(), rough]
	if not _mesh_cache.has(k):
		var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough; _mesh_cache[k] = m
	return _mesh_cache[k]

func _part(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = m; mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi); return mi

func build(jersey: Color, helmet: Color, pants: Color, big := 1.0) -> void:
	for c in get_children(): c.queue_free()
	_legs.clear(); _arms.clear()
	_body = Node3D.new(); add_child(_body)
	var skin := Color(0.78, 0.6, 0.46) if (hash(role + str(team)) % 3) != 0 else Color(0.45, 0.31, 0.22)
	var w := big
	for sx in [-1.0, 1.0]:
		var hip := Node3D.new(); hip.position = Vector3(0.22 * sx * w, 0.9, 0); _body.add_child(hip)
		_part(hip, _box(Vector3(0.3 * w, 0.62, 0.32)), mat(pants), Vector3(0, -0.31, 0))
		_part(hip, _box(Vector3(0.26 * w, 0.3, 0.42)), mat(Color(0.1, 0.1, 0.1)), Vector3(0, -0.76, 0.05))
		_legs.append(hip)
	_part(_body, _box(Vector3(0.78 * w, 0.72, 0.46)), mat(jersey), Vector3(0, 1.26, 0))
	_part(_body, _box(Vector3(1.12 * w, 0.3, 0.6)), mat(jersey.lightened(0.08)), Vector3(0, 1.62, 0))
	for sx in [-1.0, 1.0]:
		var sh := Node3D.new(); sh.position = Vector3(0.62 * sx * w, 1.6, 0); _body.add_child(sh)
		_part(sh, _box(Vector3(0.24, 0.66, 0.24)), mat(skin), Vector3(0, -0.36, 0))
		_arms.append(sh)
	var sph := "helm"
	if not _mesh_cache.has(sph):
		var s := SphereMesh.new(); s.radius = 0.42; s.height = 0.8; s.radial_segments = 12; s.rings = 6; _mesh_cache[sph] = s
	_part(_body, _mesh_cache[sph], mat(helmet, 0.35), Vector3(0, 2.1, 0))
	_part(_body, _box(Vector3(0.1, 0.5, 0.86)), mat(jersey, 0.5), Vector3(0, 2.14, 0))            # helmet stripe
	_part(_body, _box(Vector3(0.46, 0.14, 0.14)), mat(Color(0.2, 0.2, 0.22)), Vector3(0, 2.0, 0.4))  # face mask
	if not _mesh_cache.has("shadow"):
		var cy := CylinderMesh.new(); cy.top_radius = 0.62; cy.bottom_radius = 0.62; cy.height = 0.02; cy.radial_segments = 12; _mesh_cache["shadow"] = cy
		var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0, 0, 0, 0.3); sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mesh_cache["shadow_m"] = sm
		var tr := TorusMesh.new(); tr.inner_radius = 0.82; tr.outer_radius = 1.02; tr.rings = 20; tr.ring_segments = 6; _mesh_cache["ring"] = tr
		var rm := StandardMaterial3D.new(); rm.albedo_color = Color(1, 0.9, 0.1); rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; _mesh_cache["ring_m"] = rm
	_part(self, _mesh_cache["shadow"], _mesh_cache["shadow_m"], Vector3(0, 0.05, 0))
	_ring = _part(self, _mesh_cache["ring"], _mesh_cache["ring_m"], Vector3(0, 0.1, 0)); _ring.scale = Vector3(1, 0.25, 1); _ring.visible = false
	_tag = Label3D.new(); _tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED; _tag.no_depth_test = true; _tag.fixed_size = true
	_tag.pixel_size = 0.0011; _tag.font_size = 44; _tag.outline_size = 14; _tag.position = Vector3(0, 3.3, 0); _tag.visible = false
	_tag.modulate = Color(1, 0.95, 0.3); add_child(_tag)

func set_ring(on: bool) -> void:
	if _ring: _ring.visible = on

func set_tag(t: String) -> void:
	if _tag:
		_tag.visible = t != ""; _tag.text = t

func reset_play() -> void:
	job = ""; route = []; route_stop = false; route_dir = Vector3.ZERO; man = null; engaged = null
	block_t = 0.0; shed_cd = 0.0; stun_t = 0.0; down = false; react_t = 0.0; tackle_cd = 0.0
	juke_t = 0.0; juke_cd = 0.0; dive_t = 0.0; burst = 1.0; sprinting = false; throw_t = 0.0; cheer = false
	did_cpu_juke = false; want = Vector3.ZERO; vel = Vector3.ZERO
	set_ring(false); set_tag("")

func speed_now() -> float:
	var s := top_speed
	if sprinting and burst > 0.0: s *= 1.16
	return s

func fall(t: float) -> void:
	stun_t = max(stun_t, t); down = true; engaged = null

func step(dt: float, live: bool) -> void:
	shed_cd = max(0.0, shed_cd - dt); tackle_cd = max(0.0, tackle_cd - dt); juke_cd = max(0.0, juke_cd - dt)
	throw_t = max(0.0, throw_t - dt)
	if stun_t > 0.0:
		stun_t -= dt
		if stun_t <= 0.0 and live: down = false
	if sprinting and want.length() > 0.5: burst = max(0.0, burst - dt / 2.6)
	else: burst = min(1.0, burst + dt / 4.0)
	var target := want
	if down or stun_t > 0.0: target = Vector3.ZERO
	if juke_t > 0.0:
		juke_t -= dt; target = juke_vec
		vel = juke_vec
	elif dive_t > 0.0:
		dive_t -= dt
		if dive_t <= 0.0: fall(0.9)
	else:
		vel = vel.move_toward(target, accel * dt)
	position += vel * dt
	position.y = 0.0
	var sp := vel.length()
	if sp > 0.4: face = face.lerp(vel / sp, min(1.0, dt * 12.0)).normalized()
	rotation.y = atan2(face.x, face.z)
	# simple limb animation
	_phase += dt * (4.0 + sp * 1.25)
	var sw := clampf(sp / 8.0, 0.0, 1.0) * 0.95
	var lying := down and dive_t <= 0.0
	_lean = lerpf(_lean, (1.45 if lying else (1.1 if dive_t > 0.0 else sw * 0.22)), min(1.0, dt * 14.0))
	if _body:
		_body.rotation.x = _lean
		_body.position.y = 0.25 if lying else (abs(sin(_phase)) * 0.06 * sw)
		if cheer and not lying: _body.position.y = abs(sin(_phase * 0.9)) * 0.5
	for i in _legs.size():
		_legs[i].rotation.x = sin(_phase + PI * i) * sw
	for i in _arms.size():
		var a := sin(_phase + PI * (1 - i)) * sw * 0.9
		if cheer: a = -2.7
		elif throw_t > 0.0 and i == 0: a = -2.6 + (0.35 - throw_t) * 5.0
		elif engaged != null: a = -1.4
		_arms[i].rotation.x = a
