class_name RangeTarget
extends RefCounted
## One practice range target as plain data (the browser game's sim/rangeTargets.ts RangeTarget, M21 and M93): a steel
## plate that rings when hit, or a plywood figure that goes down when hit and stands up again, still or moving (a
## pop-up, a mover on a track, a swinger on a pendulum). GameState.targets holds them (empty in a match); RangeTargets
## steps them and tests BBs against them. Every target faces along its own yaw, so the same kinds can stand anywhere.

## STEEL: a plate that rings and stops a BB. FIGURE: a plywood figure, a player's hit volume, that falls back when hit.
enum Kind { STEEL, FIGURE }
## STILL stands; POPUP (a figure) lies flat, stands up a while and drops again; MOVER (a figure) rides a trolley to and
## fro across its face; SWINGER (a plate) swings side to side on a pendulum arm.
enum Motion { STILL, POPUP, MOVER, SWINGER }

const KINDS: Dictionary[String, Kind] = {"steel": Kind.STEEL, "figure": Kind.FIGURE}
const MOTIONS: Dictionary[String, Motion] = {
	"still": Motion.STILL, "popup": Motion.POPUP, "mover": Motion.MOVER, "swinger": Motion.SWINGER,
}


## A target as laid out in a map's `targets` (config/range.ts RangeTargetSpec): where it stands and how it moves, read
## from the file by `from_dict`.
class Spec:
	extends RefCounted
	var kind: Kind = Kind.STEEL
	var motion: Motion = Motion.STILL
	## Steel: the plate's centre (a swinger's at the bottom of its swing, under its pivot). Figures: where the feet are
	## (a mover's on its trolley, in the middle of its track).
	var position: Vector3 = Vector3.ZERO
	## Which way it faces (rad about +y; 0 faces +z, the range's firing line).
	var yaw: float = 0.0
	## Steel: the plate's radius (m).
	var radius: float = 0.0
	## Figures: crouched (the hit volume's crouched shape).
	var crouched: bool = false
	## Movers: half the track's length (m) and the trolley's speed (m/s).
	var track: float = 0.0
	var speed: float = 0.0
	## Movers and swingers: how far into its cycle it starts (s), so two of a kind don't move in step.
	var phase: float = 0.0
	## For the readout: "Steel", "Mover" …, and its marked distance (m).
	var label: String = ""
	var distance: float = 0.0
	## The timed challenge's START plate: standing only while the challenge is on, never lit, never a score.
	var start: bool = false

	## The spec in `raw` (target `index` of its file), or null when it can't stand: no kind or place, a motion the kind
	## can't have, a plate with no radius. Each thing wrong is added to `problems`; a number that won't read keeps its
	## default.
	static func from_dict(raw: Variant, index: int, problems: Array[String]) -> Spec:
		if not raw is Dictionary:
			problems.append("target %d is not an object" % index)
			return null
		var d: Dictionary = raw
		var s := Spec.new()
		var where := "target %d" % index
		var kind_name := str(d.get("kind", ""))
		if not KINDS.has(kind_name):
			problems.append("%s's kind %s is not steel or figure" % [where, kind_name])
			return null
		s.kind = KINDS[kind_name]
		var motion_name := str(d.get("motion", "still"))
		if not MOTIONS.has(motion_name):
			problems.append("%s's motion %s is not still, popup, mover or swinger" % [where, motion_name])
			return null
		s.motion = MOTIONS[motion_name]
		var steel_only := s.motion == Motion.SWINGER
		var figure_only := s.motion == Motion.POPUP or s.motion == Motion.MOVER
		if (steel_only and s.kind != Kind.STEEL) or (figure_only and s.kind != Kind.FIGURE):
			problems.append("%s: a %s can't be a %s" % [where, kind_name, motion_name])
			return null
		for axis: String in ["x", "y", "z"]:
			if not (d.get(axis) is float or d.get(axis) is int):
				problems.append("%s has no %s" % [where, axis])
				return null
		s.position = Vector3(float(d["x"]), float(d["y"]), float(d["z"]))
		s.yaw = _number(d, "yaw", s.yaw, where, problems)
		s.radius = _number(d, "radius", s.radius, where, problems)
		s.track = _number(d, "track", s.track, where, problems)
		s.speed = _number(d, "speed", s.speed, where, problems)
		s.phase = _number(d, "phase", s.phase, where, problems)
		s.distance = _number(d, "distance", s.distance, where, problems)
		s.crouched = _flag(d, "crouched", where, problems)
		s.start = _flag(d, "start", where, problems)
		s.label = str(d.get("label", ""))
		if s.kind == Kind.STEEL and not s.radius > 0.0:
			problems.append("%s: a plate needs a radius" % where)
			return null
		if s.start and s.kind != Kind.STEEL:
			problems.append("%s: the START plate must be steel" % where)
			return null
		if s.motion == Motion.MOVER and not (s.track > 0.0 and s.speed > 0.0):
			problems.append("%s: a mover needs a track and a speed (it stands still)" % where)
		return s

	## `d[key]` as a number, or `fallback` if it's missing or (with a problem added) isn't one.
	static func _number(d: Dictionary, key: String, fallback: float, where: String, problems: Array[String]) -> float:
		if not d.has(key):
			return fallback
		var v: Variant = d[key]
		if v is float or v is int:
			return float(v)
		problems.append("%s's %s must be a number" % [where, key])
		return fallback

	## `d[key]` as true or false; false if it's missing or (with a problem added) isn't one.
	static func _flag(d: Dictionary, key: String, where: String, problems: Array[String]) -> bool:
		var v: Variant = d.get(key, false)
		if v is bool:
			return v
		problems.append("%s's %s must be true or false" % [where, key])
		return false


## Its index in GameState.targets (the TARGET_HIT event's target).
var id: int = 0
var kind: Kind = Kind.STEEL
var motion: Motion = Motion.STILL
## Where it is now. Steel: the plate's centre. Figures: where the feet are. Movers and swingers move it every tick.
var position: Vector3 = Vector3.ZERO
## Where it was a tick ago: it is drawn between the two.
var prev_position: Vector3 = Vector3.ZERO
## Where it was laid out: a mover's track middle, a swinger's plate at the bottom of its swing; else `position`.
var home: Vector3 = Vector3.ZERO
## The ground's height under it (m): a plate's post and a swinger's frame stand on it.
var floor_y: float = 0.0
## Which way it faces (rad about +y; 0 faces +z), and the same as a flat unit vector (sin, cos of the yaw).
var yaw: float = 0.0
var face_x: float = 0.0
var face_z: float = 1.0
## Steel: the plate's radius (m).
var radius: float = 0.0
## Figures: crouched (the hit volume's crouched shape).
var crouched: bool = false
## Its marked distance (m) and label, for the readout.
var distance: float = 0.0
var label: String = ""
## Movers: half the track (m) and the trolley's speed (m/s).
var track: float = 0.0
var speed: float = 0.0
## Movers and swingers: how far into the cycle it is (s), now and a tick ago.
var clock: float = 0.0
var prev_clock: float = 0.0
## Seconds until a figure that was hit stands up again (0: standing, and hittable), the last RangeConfig.rise_time of
## it rising. Steel never goes down.
var down: float = 0.0
## How long this spell down lasts in all (s): the fall is drawn from its start.
var down_for: float = 0.0
## A pop-up standing by itself: seconds before it drops again.
var up: float = 0.0
## Pop-ups stand and drop by themselves (free practice); false in the timed challenge: they stand only when lit.
var auto: bool = true
## The timed challenge: seconds this target stays lit (0: not lit).
var lit: float = 0.0
## The timed challenge's START plate.
var start: bool = false
## Out of play (the START plate when the challenge isn't waiting for it): not drawn, and BBs fly through.
var hidden: bool = false
## Its stoppers (RangeTargets.target_posts), worked out once, in its own frame from its home: each post's x across, the
## top of it (m, as a height) in y, and z along its facing.
var posts: PackedVector3Array = PackedVector3Array()
## Figures: the hit volume where it stands now (a character's, upright, legs at rest), rebuilt as it moves; null for
## steel.
var volume: Hitbox.Volume = null
## A sphere round all of it a BB could meet wherever its motion takes it (RangeTargets.first_hit skips a target whose
## sphere a BB's path misses): its centre and radius, worked out once.
var reach_centre: Vector3 = Vector3.ZERO
var reach: float = 0.0
