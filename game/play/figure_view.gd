class_name FigureView
extends Node3D
## Another player on the field, drawn as its rigged figure (FigureBody, step 23; every bot on every preset, DECISIONS
## BD1), placed and posed from its Character between the last two ticks: its legs by `animate` (FigurePose: moving,
## crouching, jumping, vaulting, the hit call, the walk-off and the lean) and its upper body (the aim, the holster, a
## switch, a trigger press per SHOT event, `on_shot`), its replicas handed to it (FigureHands: in the hand, slung,
## hanging from the hand), the models' cut-down figure versions in its team's paint (ReplicaPaint) with its parts'
## figure versions fitted (ReplicaParts). Calling a hit, "HIT!" shows above the head; it stays up on the walk off; a
## figure leaving the field fades out, its replicas put away. The hit flinch (`hit`, FigureFlinch): the upper body
## jolts the way the BB flew, through FigureBend. In a reload (FI4) the left hand carries a copy of the replica model's
## magazine, made here once a slot in the replica's paint, and throws the old one into `thrown`. A kind the session
## couldn't load draws no body, only the sign (the tests catch a missing model, FigureModels warns).

## Where the sign floats and how it is drawn.
const SIGN_HEIGHT := 2.25
const SIGN_FONT_SIZE := 96
const SIGN_PIXEL := 0.004
const SIGN_OUTLINE_DARKEN := 0.5
const MODEL_DIR := "res://assets/models/replicas/"

var character_id: int = -1
var _sign: Label3D = null
var _hits: HitConfig = null
## The replicas the character carries, as the models' figure versions (kept hidden on the figure between bodies).
var _replicas: Array[MeshInstance3D] = []
var _classes: Array[StringName] = []
## Each replica's magazine copy (the full model's magazine mesh, painted as the replica; null without one); where the
## figure throws its old magazines (null: none thrown).
var _magazines: Array[MeshInstance3D] = []
var thrown: ThrownMagazines = null
## Seen this much (1 solid, 0 gone), as `update` last drew it; a shot since the last pose (the trigger pressed).
var _fade: float = 1.0
var _fired: bool = false
## The figure drawn (null when its kind couldn't load); the team and its colour and glow, for a body made later.
var _body: FigureBody = null
var _team: int = 0
var _team_colour: Color = Color.WHITE
var _glow: float = 0.0
## The legs: their pose (reused every frame), the lines its levels change at, whether the next pose snaps (the
## first, or the first after the legs were left still), and the frames and time gathered beyond the far line.
var _pose: FigurePose = null
var _lines: Vector2 = Vector2.ZERO
var _snap: bool = true
var _far_frames: int = 0
var _far_delta: float = 0.0
## The hit flinch, eased on every frame's time in `update` (hidden or far all the same).
var _flinch: FigureFlinch = null


## Draws `c` in `team_colour` (the body's Team* paint, set_body, and the sign's outline), glowing with `glow` of it
## (High contrast by day, TeamColours), holding its replicas in its team's paints (`realistic`: each bold scheme as its
## plain colour) with `parts[i]` on replica `i` (Kit.parts; bots carry theirs as they come); `figures` gives the hit
## flinch's numbers (the built-in ones when null).
func setup(c: Character, team_colour: Color, hits: HitConfig, font: Font,
		realistic: bool = false, parts: Array[Dictionary] = [], glow: float = 0.0, figures: FigureConfig = null) -> void:
	character_id = c.id
	var cfg := figures if figures != null else FigureConfig.new()
	_flinch = FigureFlinch.new(cfg)
	_hits = hits
	_team = c.team
	_team_colour = team_colour
	_glow = glow
	name = "Figure_%d" % c.id
	top_level = true
	for i in c.armament.replicas.size():
		var held := _held_replica(c.armament.replicas[i], c.team, realistic, parts[i] if i < parts.size() else {},
				cfg.magazine_node, _magazines)
		_replicas.append(held)
		_classes.append(c.armament.replicas[i].site_class)
		if held != null:
			add_child(held)
		if _magazines[i] != null:
			add_child(_magazines[i])
	_sign = make_sign(font, team_colour)
	_sign.position = Vector3(0.0, SIGN_HEIGHT, 0.0)
	add_child(_sign)


## Draws figure kind `kind` of `models`, its levels changing at `lines` (m); with `models` null, or a kind it couldn't
## load, no body (the old one freed, its replicas kept).
func set_body(models: FigureModels, kind: int, lines: Vector2) -> void:
	if _body != null:
		# The replicas back on the figure first, hidden: they outlive the body.
		_body.hands.release(self)
		# Out of the tree at once, so the old body never draws beside a new one this frame.
		remove_child(_body)
		_body.queue_free()
		_body = null
	_lines = lines
	_snap = true
	if models != null and models.has_kind(kind):
		_pose = FigurePose.new(models.config) if _pose == null else _pose
		_body = FigureBody.new()
		if _body.setup(models, kind, character_id, _team, _team_colour, _glow, lines):
			add_child(_body)
			_body.hands.hold(_replicas, _classes, _magazines)
			_body.hands.thrown = thrown
			_body.set_fade(_fade)
		else:
			_body.free()
			_body = null


## The figure drawn, or null.
func body() -> FigureBody:
	return _body


## The figure's levels change at `lines` (m) from now on (the graphics' Mesh detail).
func set_lod_lines(lines: Vector2) -> void:
	_lines = lines
	if _body != null:
		_body.set_lod_lines(lines)


## The models' figure version of `r` with `parts`' figure versions on it, hidden, painted for `team` (null without a
## model). The figure version is one mesh, so a part shows over the standard magazine or flash hider rather than in
## its place. A copy of the full model's `magazine_node` mesh for the reloads, in the same paint
## (null without one), goes on the end of `magazines`.
func _held_replica(r: ReplicaConfig, team: int, realistic: bool, parts: Dictionary, magazine_node: String,
		magazines: Array[MeshInstance3D]) -> MeshInstance3D:
	var scene := load(MODEL_DIR + r.id + ".glb") as PackedScene
	if scene == null:
		magazines.append(null)
		return null
	var model := scene.instantiate()
	var paint := ReplicaPaint.bot_paint(team, r)
	var mag := model.find_child(magazine_node, true, false) as MeshInstance3D
	var copy: MeshInstance3D = null
	if mag != null and mag.mesh != null:
		copy = MeshInstance3D.new()
		copy.name = "Magazine_%s" % r.id
		copy.mesh = mag.mesh
		copy.visible = false
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ReplicaPaint.apply(copy, paint, realistic)
	magazines.append(copy)
	var held := model.find_child("Figure", true, false) as MeshInstance3D
	if held != null:
		held.get_parent().remove_child(held)
		held.transform = Transform3D.IDENTITY
		held.visible = false
		held.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for part in ReplicaParts.figure_meshes(r.id, parts):
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			held.add_child(part)
		ReplicaPaint.apply(held, paint, realistic)
	model.free()
	return held


## A shot from this figure (its SHOT event): one trigger press at its next pose.
func on_shot() -> void:
	if _body != null:
		_fired = true


## The "HIT!" sign, hidden until the hit is called.
static func make_sign(font: Font, team_colour: Color) -> Label3D:
	var s := Label3D.new()
	s.text = TranslationServer.translate(&"HUD_HIT_SIGN")
	s.font = font
	s.font_size = SIGN_FONT_SIZE
	s.pixel_size = SIGN_PIXEL
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.outline_size = SIGN_FONT_SIZE / 6
	s.modulate = Color.WHITE
	s.outline_modulate = team_colour.darkened(SIGN_OUTLINE_DARKEN)
	s.visible = false
	return s


## Poses the figure's legs from `c` at `fraction` between its ticks, `delta` seconds on, seen from `eye`. A
## hidden figure's legs are left still (and snap to the pose when it shows again); beyond the far line they move every
## FigureConfig.far_stride-th frame, but a figure's first pose is always taken (never the rig's rest pose). After
## `update` and after the figure is hidden from its own eyes.
func animate(c: Character, fraction: float, delta: float, eye: Vector3) -> void:
	if _body == null:
		return
	if not visible:
		_snap = true
		_fired = false
		return
	var cfg := _pose.config()
	var far := _lines.y + cfg.lod_margin
	if not _snap and global_position.distance_squared_to(eye) > far * far:
		if cfg.far_stride <= 0:
			# Held still out there: a press kept now would play stale when the figure comes near.
			_far_frames = 0
			_far_delta = 0.0
			_fired = false
			return
		_far_delta += delta
		_far_frames += 1
		if _far_frames < cfg.far_stride:
			return
		delta = _far_delta
	_far_frames = 0
	_far_delta = 0.0
	_pose.read(c, fraction, _hits)
	if _snap:
		_snap = false
		_pose.snap()
	else:
		_pose.settle(delta)
	_body.animate(_pose, _hits, delta, _fired)
	_body.set_flinch(_flinch.tilt())
	_fired = false
	if _fade < 1.0:
		_body.hands.show_hands(-1, -1, false)
		_body.hands.show_reload(-1, 0.0, true)


## The flinch dropped at once (a round reset or a rematch), the figure's bend too.
func reset_flinch() -> void:
	_flinch.reset()
	if _body != null:
		_body.set_flinch(Vector3.ZERO)


## A BB flying along `way` (the world's) hit the character, facing `yaw`: the upper body jolts that way (flattened).
func hit(way: Vector3, yaw: float) -> void:
	_flinch.hit(Basis(Vector3.UP, -yaw) * way)


## Places and poses the figure for `c` at `fraction` between its ticks, the hit flinch `delta` seconds on.
func update(c: Character, fraction: float, delta: float = 0.0) -> void:
	_flinch.advance(delta)
	global_position = c.prev_position.lerp(c.position, fraction)
	rotation = Vector3(0.0, lerp_angle(c.prev_yaw, c.yaw, fraction), 0.0)
	_sign.visible = c.status == Character.Status.CALLING or c.status == Character.Status.WALKING_OFF
	var fade := 1.0
	if c.status == Character.Status.LEAVING:
		fade = clampf(1.0 - c.status_time / maxf(_hits.vanish_time, 0.001), 0.0, 1.0)
	visible = fade > 0.0
	_fade = fade
	if _body != null:
		# The hands show the replicas as animate poses them; put away as it fades (the paint is shared).
		_body.set_fade(fade)
		if fade < 1.0:
			_body.hands.show_hands(-1, -1, false)
			_body.hands.show_reload(-1, 0.0, true)
