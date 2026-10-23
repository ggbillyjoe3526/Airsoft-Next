class_name FigureSidecar
extends RefCounted
## A rigged figure's sidecar (`human.json`, `robot.json`, written by tools/blender/bot-figure/), typed: its clips with
## their loop, pace, upper-body flag and the replica stat they are fitted to; its parts; where each replica class sits
## on the Grip_R bone; and where the magazines go in the reloads. The matrices are kept as the file gives them, in
## Blender's axes in the bone's frame (X right, Y forward, Z up, origin at the bone head): the code that places a
## replica or a magazine turns them (FI3, FI4). `read` warns and gives null for a missing or unreadable file, and the
## figures fall back to the capsules.

## One clip: its name in the AnimationPlayer's library, length (s), whether it loops, the speed (m/s) its steps were
## made at (0 when it isn't a gait), whether it is authored over a still pelvis for the upper body only, and the replica
## stat its length is fitted to (&"" when none: reloadTime, drawTime).
class Clip:
	var name: StringName = &""
	var seconds: float = 0.0
	var loop: bool = false
	var speed: float = 0.0
	var upper_body_only: bool = false
	var fit_to: StringName = &""


## The old magazine pulled out in a reload: shown on the bone from `from` to `release` (fractions of the clip), then
## thrown with `velocity` (m/s) and `spin` (rad/s, axis times rate) under `gravity`, lying for `lifetime` (s).
class OldMagazine:
	var from: float = 0.0
	var release: float = 0.0
	var velocity: Vector3 = Vector3.ZERO
	var spin: Vector3 = Vector3.ZERO
	var on_bone: Transform3D = Transform3D.IDENTITY
	var gravity: float = 0.0
	var lifetime: float = 0.0


## A reload's magazine in the hand: replica class, bone, shown from `from` to `to` (fractions of the clip) at `on_bone`;
## the replica's own magazine hidden over `replica_hidden` (from, to); the old one, or null.
class Magazine:
	var replica: StringName = &""
	var bone: StringName = &""
	var from: float = 0.0
	var to: float = 0.0
	var on_bone: Transform3D = Transform3D.IDENTITY
	var replica_hidden: Vector2 = Vector2.ZERO
	var old: OldMagazine = null


var clips: Array[Clip] = []
var parts: PackedStringArray = PackedStringArray()
## Replica class (rifle, pistol) to its place on Grip_R.
var replica_on_grip: Dictionary[StringName, Transform3D] = {}
## Reload clip name to its magazine.
var magazine_in_hand: Dictionary[StringName, Magazine] = {}


## The sidecar at `path`, or null with a warning when it is missing or unreadable.
static func read(path: String) -> FigureSidecar:
	if not FileAccess.file_exists(path):
		push_warning("FigureSidecar: %s is missing; the figures stay capsules" % path)
		return null
	return parse(FileAccess.get_file_as_string(path), path)


## The sidecar in `text` (`source` names it in a warning), or null with a warning when it can't be read: not an object,
## or its clips or parts missing or of the wrong shape.
static func parse(text: String, source: String = "sidecar") -> FigureSidecar:
	var json := JSON.new()
	var data: Variant = json.data if json.parse(text) == OK else null
	if not data is Dictionary:
		push_warning("FigureSidecar: %s is not a JSON object; the figures stay capsules" % source)
		return null
	var d := data as Dictionary
	var s := FigureSidecar.new()
	var clip_list: Variant = d.get("clips")
	var part_list: Variant = d.get("parts")
	if not clip_list is Array or not part_list is Array:
		push_warning("FigureSidecar: %s has no clips or parts; the figures stay capsules" % source)
		return null
	for entry: Variant in clip_list:
		var clip := _clip(entry)
		if clip == null:
			push_warning("FigureSidecar: %s has a clip without a name and length; the figures stay capsules" % source)
			return null
		s.clips.append(clip)
	for part: Variant in part_list:
		if not part is String:
			push_warning("FigureSidecar: %s has a part that isn't a name; the figures stay capsules" % source)
			return null
		s.parts.append(part as String)
	if s.parts.is_empty():
		push_warning("FigureSidecar: %s lists no parts; the figures stay capsules" % source)
		return null
	var grip: Variant = d.get("replicaOnGrip")
	if grip is Dictionary:
		for key: Variant in grip:
			s.replica_on_grip[StringName(str(key))] = _matrix((grip as Dictionary)[key])
	var mags: Variant = d.get("magazineInHand")
	if mags is Dictionary:
		for key: Variant in mags:
			var m := _magazine((mags as Dictionary)[key])
			if m != null:
				s.magazine_in_hand[StringName(str(key))] = m
	return s


## The clip named `name`, or null.
func clip(name: StringName) -> Clip:
	for c in clips:
		if c.name == name:
			return c
	return null


static func _clip(entry: Variant) -> Clip:
	if not entry is Dictionary:
		return null
	var e := entry as Dictionary
	var name: Variant = e.get("name")
	var seconds: Variant = e.get("seconds")
	if not name is String or not (seconds is float or seconds is int):
		return null
	var c := Clip.new()
	c.name = StringName(name as String)
	c.seconds = float(seconds)
	c.loop = _flag(e, "loop")
	c.upper_body_only = _flag(e, "upperBodyOnly")
	var speed: Variant = e.get("speed")
	c.speed = float(speed) if speed is float or speed is int else 0.0
	var fit: Variant = e.get("fitTo")
	c.fit_to = StringName(fit as String) if fit is String else &""
	return c


static func _magazine(entry: Variant) -> Magazine:
	if not entry is Dictionary:
		return null
	var e := entry as Dictionary
	var m := Magazine.new()
	m.replica = StringName(str(e.get("replica", "")))
	m.bone = StringName(str(e.get("bone", "")))
	m.from = _number(e, "from")
	m.to = _number(e, "to")
	m.on_bone = _matrix(e.get("magazineOnBone"))
	var hidden := _numbers(e.get("replicaMagazineHidden"))
	if hidden.size() >= 2:
		m.replica_hidden = Vector2(hidden[0], hidden[1])
	var old: Variant = e.get("oldMagazine")
	if old is Dictionary:
		var o := old as Dictionary
		m.old = OldMagazine.new()
		m.old.from = _number(o, "from")
		m.old.release = _number(o, "release")
		m.old.velocity = _vector(o.get("releaseVelocity"))
		m.old.spin = _vector(o.get("releaseSpin"))
		m.old.on_bone = _matrix(o.get("magazineOnBone"))
		m.old.gravity = _number(o, "gravity")
		m.old.lifetime = _number(o, "lifetime")
	return m


static func _flag(d: Dictionary, key: String) -> bool:
	var v: Variant = d.get(key)
	return v if v is bool else false


static func _number(d: Dictionary, key: String) -> float:
	var v: Variant = d.get(key)
	return float(v) if v is float or v is int else 0.0


static func _numbers(v: Variant) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	if v is Array:
		for n: Variant in v:
			out.append(float(n) if n is float or n is int else 0.0)
	return out


static func _vector(v: Variant) -> Vector3:
	var n := _numbers(v)
	return Vector3(n[0], n[1], n[2]) if n.size() >= 3 else Vector3.ZERO


## A row-major 4x4 (rows of four numbers) as a Transform3D, axes untouched; identity when it isn't one.
static func _matrix(v: Variant) -> Transform3D:
	if not v is Array or (v as Array).size() < 3:
		return Transform3D.IDENTITY
	var rows: Array[PackedFloat64Array] = []
	for r: Variant in v:
		var row := _numbers(r)
		if row.size() < 4:
			return Transform3D.IDENTITY
		rows.append(row)
	var basis := Basis(Vector3(rows[0][0], rows[1][0], rows[2][0]), Vector3(rows[0][1], rows[1][1], rows[2][1]),
			Vector3(rows[0][2], rows[1][2], rows[2][2]))
	return Transform3D(basis, Vector3(rows[0][3], rows[1][3], rows[2][3]))
