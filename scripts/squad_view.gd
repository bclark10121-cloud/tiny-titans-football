extends Node3D
class_name SquadView
# Draws all 22 players with one MultiMesh per body part (standard E3.2).
# The whole field of players costs about ten draw calls instead of about 240.
# Jersey numbers are drawn by a small shader from a digit strip. The digits ride in the instance colour:
# red = tens, green = ones, blue = 0 for white text or 1 for dark text. No custom data is used.

const FONT: Dictionary = {
	"0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111",
	"4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001010010010",
	"8": "111101111101111", "9": "111101111001111"}
const SKINS: Array[Color] = [Color(0.78, 0.6, 0.46), Color(0.45, 0.31, 0.22), Color(0.62, 0.45, 0.32), Color(0.9, 0.74, 0.6)]
const NUMBER_SHADER: String = """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D digits : filter_nearest, source_color;
varying vec3 dig;
varying vec2 face_uv;
void vertex() {
	dig = COLOR.rgb;
	face_uv = vec2(VERTEX.x + 0.5, 0.5 - VERTEX.y);
}
void fragment() {
	float tens = floor(dig.x * 10.0 + 0.5);
	float ones = floor(dig.y * 10.0 + 0.5);
	float d = face_uv.x < 0.5 ? tens : ones;
	float lx = fract(face_uv.x * 2.0);
	vec4 t = texture(digits, vec2((d + lx) / 10.0, face_uv.y));
	if (t.a < 0.5) {
		discard;
	}
	ALBEDO = dig.z < 0.5 ? vec3(1.0) : vec3(0.1, 0.12, 0.16);
}
"""

const STRIDE: int = 16  # 12 floats of transform and 4 of colour per instance

var players: Array[TTPlayer] = []
var mm: Dictionary = {}
var buf: Dictionary = {}  # part name -> PackedFloat32Array, pushed whole each frame
var num_dark: PackedByteArray = PackedByteArray()  # per player: 1 when the number is dark text
var num_val: PackedInt32Array = PackedInt32Array()  # per player: jersey number

func setup(ps: Array[TTPlayer]) -> void:
	players = ps
	for i: int in ps.size():
		ps[i].view_i = i
		ps[i].big = 1.2 if ps[i].idx < 5 else 1.0
	var n: int = ps.size()
	num_dark.resize(n)
	num_dark.fill(0)
	num_val.resize(n)
	num_val.fill(0)
	var box := BoxMesh.new()
	var helm: BoxMesh = box
	var disc: BoxMesh = box
	var plate: BoxMesh = box
	var lit := StandardMaterial3D.new()
	lit.vertex_color_use_as_albedo = true
	lit.roughness = 0.8
	var shiny := StandardMaterial3D.new()
	shiny.vertex_color_use_as_albedo = true
	shiny.roughness = 0.35
	var flat := StandardMaterial3D.new()
	flat.vertex_color_use_as_albedo = true
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var num := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = NUMBER_SHADER
	num.shader = sh
	num.set_shader_parameter("digits", _digit_texture())
	_add("thigh", box, lit, n * 2)
	_add("boot", box, lit, n * 2)
	_add("torso", box, lit, n)
	_add("pads", box, lit, n)
	_add("arm", box, lit, n * 2)
	_add("helmet", helm, shiny, n)
	_add("stripe", box, shiny, n)
	_add("mask", box, lit, n)
	_add("shadow", disc, flat, n)
	_add("number", plate, num, n * 2)

func _add(part: String, mesh: Mesh, mat: Material, count: int) -> void:
	var m := MultiMesh.new()
	m.transform_format = MultiMesh.TRANSFORM_3D
	m.use_colors = true
	m.use_custom_data = false
	m.mesh = mesh
	m.instance_count = count
	m.custom_aabb = AABB(Vector3(-90.0, -5.0, -95.0), Vector3(180.0, 25.0, 190.0))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = m
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mm[part] = m
	var b := PackedFloat32Array()
	b.resize(count * STRIDE)
	b.fill(0.0)
	buf[part] = b

func _digit_texture() -> ImageTexture:
	# 10 cells of 5 x 7 pixels: a 3 x 5 digit with a one pixel border
	var img := Image.create(50, 7, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	for dgt: int in 10:
		var bits: String = FONT[str(dgt)]
		for r: int in 5:
			for c: int in 3:
				if bits[r * 3 + c] == "1":
					img.set_pixel(dgt * 5 + 1 + c, 1 + r, Color.WHITE)
	return ImageTexture.create_from_image(img)

func paint(cols: Array[Dictionary]) -> void:
	for p: TTPlayer in players:
		var i: int = p.view_i
		var t: Dictionary = cols[p.team]
		var jersey := Color(String(t.jersey))
		var helmet := Color(String(t.helmet))
		var pants := Color(String(t.pants))
		var skin: Color = SKINS[(p.idx * 7 + p.team * 3) % SKINS.size()]
		num_dark[i] = 0 if jersey.get_luminance() < 0.55 else 1
		for k: int in 2:
			_col("thigh", i * 2 + k, pants)
			_col("boot", i * 2 + k, Color(0.1, 0.1, 0.1))
			_col("arm", i * 2 + k, skin)
		_col("torso", i, jersey)
		_col("pads", i, jersey.lightened(0.08))
		_col("helmet", i, helmet)
		_col("stripe", i, jersey)
		_col("mask", i, Color(0.2, 0.2, 0.22))
		_col("shadow", i, Color(0.08, 0.2, 0.1))
		_number_col(i)

func set_number(p: TTPlayer, n: int) -> void:
	num_val[p.view_i] = n
	_number_col(p.view_i)

func _number_col(i: int) -> void:
	var n: int = num_val[i]
	var c := Color(float(n / 10) / 10.0, float(n % 10) / 10.0, float(num_dark[i]), 1.0)
	_col("number", i * 2, c)
	_col("number", i * 2 + 1, c)

func _col(part: String, i: int, c: Color) -> void:
	var b: PackedFloat32Array = buf[part]
	var o: int = i * STRIDE + 12
	b[o] = c.r
	b[o + 1] = c.g
	b[o + 2] = c.b
	b[o + 3] = c.a

func _put(b: PackedFloat32Array, i: int, t: Transform3D) -> void:
	# Godot's MultiMesh buffer stores the 3 x 4 matrix row by row
	var o: int = i * STRIDE
	b[o] = t.basis.x.x
	b[o + 1] = t.basis.y.x
	b[o + 2] = t.basis.z.x
	b[o + 3] = t.origin.x
	b[o + 4] = t.basis.x.y
	b[o + 5] = t.basis.y.y
	b[o + 6] = t.basis.z.y
	b[o + 7] = t.origin.y
	b[o + 8] = t.basis.x.z
	b[o + 9] = t.basis.y.z
	b[o + 10] = t.basis.z.z
	b[o + 11] = t.origin.z

func _bx(size: Vector3, pos: Vector3) -> Transform3D:
	return Transform3D(Basis.from_scale(size), pos)

func refresh() -> void:
	var thigh: PackedFloat32Array = buf.thigh
	var boot: PackedFloat32Array = buf.boot
	var arm: PackedFloat32Array = buf.arm
	var number: PackedFloat32Array = buf.number
	var torso: PackedFloat32Array = buf.torso
	var pads: PackedFloat32Array = buf.pads
	var helmet: PackedFloat32Array = buf.helmet
	var stripe: PackedFloat32Array = buf.stripe
	var mask: PackedFloat32Array = buf.mask
	var shadow: PackedFloat32Array = buf.shadow
	var back := Transform3D(Basis(Vector3.UP, PI).scaled(Vector3(0.5, 0.32, 0.01)), Vector3(0.0, 1.3, -0.25))
	var front := Transform3D(Basis().scaled(Vector3(0.5, 0.32, 0.01)), Vector3(0.0, 1.3, 0.25))
	for p: TTPlayer in players:
		var i: int = p.view_i
		var w: float = p.big
		var root := Transform3D(Basis(Vector3.UP, p.rotation.y), p.position)
		if not p.visible:
			# sitting out (7 on 7): squash every part to nothing
			root = Transform3D(Basis().scaled(Vector3.ZERO), p.position)
		var body: Transform3D = root * Transform3D(Basis(Vector3.RIGHT, p.lean), Vector3(0.0, p.body_y, 0.0))
		for k: int in 2:
			var sx: float = -1.0 if k == 0 else 1.0
			var hip: Transform3D = body * Transform3D(Basis(Vector3.RIGHT, p.legs[k]), Vector3(0.22 * sx * w, 0.9, 0.0))
			_put(thigh, i * 2 + k, hip * _bx(Vector3(0.3 * w, 0.62, 0.32), Vector3(0.0, -0.31, 0.0)))
			_put(boot, i * 2 + k, hip * _bx(Vector3(0.26 * w, 0.3, 0.42), Vector3(0.0, -0.76, 0.05)))
			var sh: Transform3D = body * Transform3D(Basis(Vector3.RIGHT, p.arms[k]), Vector3(0.62 * sx * w, 1.6, 0.0))
			_put(arm, i * 2 + k, sh * _bx(Vector3(0.24, 0.66, 0.24), Vector3(0.0, -0.36, 0.0)))
		_put(torso, i, body * _bx(Vector3(0.78 * w, 0.72, 0.46), Vector3(0.0, 1.26, 0.0)))
		_put(pads, i, body * _bx(Vector3(1.12 * w, 0.3, 0.6), Vector3(0.0, 1.62, 0.0)))
		_put(helmet, i, body * _bx(Vector3(0.74, 0.7, 0.8), Vector3(0.0, 2.08, 0.0)))
		_put(stripe, i, body * _bx(Vector3(0.12, 0.74, 0.84), Vector3(0.0, 2.1, 0.0)))
		_put(mask, i, body * _bx(Vector3(0.5, 0.12, 0.12), Vector3(0.0, 1.98, 0.43)))
		var shadow_scale: Vector3 = Vector3(1.1, 0.04, 1.1) if p.visible else Vector3.ZERO  # no shadow for a player sitting out
		_put(shadow, i, Transform3D(Basis(Vector3.UP, p.rotation.y).scaled(shadow_scale), Vector3(p.position.x, 0.08, p.position.z)))
		var wide := Transform3D(Basis.from_scale(Vector3(w, 1.0, 1.0)), Vector3.ZERO)
		_put(number, i * 2, body * wide * back)
		_put(number, i * 2 + 1, body * wide * front)
	# One whole upload per part. Per-instance setters left some batches stale in the browser build.
	for part: String in mm:
		(mm[part] as MultiMesh).buffer = buf[part]
