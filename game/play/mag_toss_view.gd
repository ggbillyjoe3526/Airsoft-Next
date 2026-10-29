class_name MagTossView
extends Node3D
## The magazines in the air of the hand-off (MH3; concept `step27/mag-hand-off.png`; the browser game's
## render/effects/magTosses.ts): one copy per slot of GameState.mag_tosses, made once, each drawn while its slot flies
## as the thrower's replica's own magazine mesh (FigureModels.magazine_mesh; a dark box the size of a rifle's or a
## pistol's without one), from where it left the hand to the catcher's chest wherever they are now, arcing up
## ARC_PER_METRE a metre of toss at most ARC_MAX at the middle and spinning SPIN turns a second. Reads the state; owns
## no rule. A frame with nothing in the air only hides what was shown.

## The arc's peak over the straight line (m): this much a metre of toss, never more than ARC_MAX; the spin (turns a
## second) about the toss's sideways axis.
const ARC_PER_METRE := 0.1
const ARC_MAX := 0.6
const SPIN := 2.5
## The stand-in box (m: width, height, depth) for a magazine with no mesh, by the replica's class, and its colour.
const RIFLE_BOX := Vector3(0.028, 0.19, 0.07)
const PISTOL_BOX := Vector3(0.022, 0.12, 0.035)
const BOX_COLOUR := Color("2b2d31")
const BOX_ROUGHNESS := 0.7

var _share: MagShare = null
var _copies: Array[MeshInstance3D] = []
## Each copy's mesh's middle (spun about), and what it shows: its thrower's id and slot (-1: nothing yet).
var _middles := PackedVector3Array()
var _showing := PackedInt32Array()
var _rifle: BoxMesh = null
var _pistol: BoxMesh = null
## By character id and slot (id * _stride + slot): the mesh its toss draws.
var _meshes: Array[Mesh] = []
var _stride: int = 1


## One copy for each of `count` toss slots, hidden, with each character's replicas' magazines read from `models` (null:
## the stand-in boxes); `share` gives the catcher's chest.
func setup(count: int, characters: Array[Character], models: FigureModels, share: MagShare) -> void:
	name = "MagTosses"
	top_level = true
	_share = share
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BOX_COLOUR
	paint.roughness = BOX_ROUGHNESS
	_rifle = BoxMesh.new()
	_rifle.size = RIFLE_BOX
	_rifle.material = paint
	_pistol = BoxMesh.new()
	_pistol.size = PISTOL_BOX
	_pistol.material = paint
	for c in characters:
		_stride = maxi(_stride, c.armament.replicas.size())
	_meshes.resize((characters.size() + 1) * _stride)
	for c in characters:
		var replicas := c.armament.replicas
		for slot in replicas.size():
			var r := replicas[slot]
			var mesh: Mesh = models.magazine_mesh(r.id) if models != null else null
			if mesh == null:
				mesh = _pistol if r.site_class == &"pistol" else _rifle
			if c.id >= 0 and c.id * _stride + slot < _meshes.size():
				_meshes[c.id * _stride + slot] = mesh
	for i in maxi(0, count):
		var m := MeshInstance3D.new()
		m.visible = false
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		_copies.append(m)
	_middles.resize(_copies.size())
	_showing.resize(_copies.size())
	_showing.fill(-1)


## Each frame: every toss in `state` flying, `fraction` of a tick of `tick` seconds past its last step.
func update(state: GameState, fraction: float, tick: float) -> void:
	var tosses := state.mag_tosses
	for i in _copies.size():
		var m := _copies[i]
		var t: MagShare.Toss = tosses[i] if i < tosses.size() else null
		if t == null or not t.active:
			if m.visible:
				m.visible = false
			continue
		var catcher := state.character(t.to_id)
		if catcher == null:
			m.visible = false
			continue
		_wear(i, t)
		var to := _share.catch_point(catcher)
		var p := clampf((t.age + fraction * tick) / maxf(t.flight, 0.001), 0.0, 1.0)
		m.transform = flight_at(t.from, to, p, t.flight) * Transform3D(Basis.IDENTITY, -_middles[i])
		m.visible = true


## Where a magazine tossed from `from` to `to` in a flight of `flight` seconds is, `p` of the way through it (0 to 1):
## along the line, raised by the arc (ARC_PER_METRE a metre, at most ARC_MAX, at the middle), turned SPIN turns a
## second about the toss's sideways axis.
static func flight_at(from: Vector3, to: Vector3, p: float, flight: float) -> Transform3D:
	var along := to - from
	var reach := along.length()
	var arc := minf(ARC_PER_METRE * reach, ARC_MAX)
	var at := from.lerp(to, p) + Vector3.UP * arc * 4.0 * p * (1.0 - p)
	var flat := Vector3(along.x, 0.0, along.z)
	var side := flat.cross(Vector3.UP).normalized() if flat.length_squared() > 0.0001 else Vector3.RIGHT
	return Transform3D(Basis(side, SPIN * TAU * p * flight), at)


## Copy `i` shows slot `t`'s thrower's magazine: set only when the thrower or slot changes.
func _wear(i: int, t: MagShare.Toss) -> void:
	var key := t.from_id * _stride + t.from_slot
	if key == _showing[i]:
		return
	_showing[i] = key
	var mesh: Mesh = _meshes[key] if key >= 0 and key < _meshes.size() else null
	if mesh == null:
		mesh = _rifle
	_copies[i].mesh = mesh
	_middles[i] = mesh.get_aabb().get_center()


## The copies' materials (each surface's), for ShaderPrewarm.
func materials() -> Array[Material]:
	var out: Array[Material] = []
	for mesh in _meshes:
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var mat := mesh.surface_get_material(s)
			if mat != null and not out.has(mat):
				out.append(mat)
	return out


## Whether copy `i` is drawn, for tests.
func shown(i: int) -> bool:
	return i < _copies.size() and _copies[i].visible


## Copy `i`'s mesh, for tests.
func mesh_of(i: int) -> Mesh:
	return _copies[i].mesh if i < _copies.size() else null
