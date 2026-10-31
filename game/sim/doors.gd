class_name Doors
extends RefCounted
## Hinged doors (DO1): a press of Use toggles the door in reach nearest the view's line, a swing takes no press, a door
## won't shut on a body, and each toggle is a DOOR event heard out to DoorConfig.heard through walls (defaults taken
## with the owner's doors, docs/records/DO1.md). A shut leaf is a solid wooden box to BBs, bombs, sight and bodies; an
## open one is nothing (the view swings it flat against its wall). Each match and each round starts with every door as
## the map sets it. Pure rules on GameState.doors; the level is told each change through WorldQuery.set_door_shut.
## Allocates nothing a tick.

## Feet closer than this (m) to a leaf are at it: no direction to weigh.
const AT_LEAF := 1e-4

var _cfg: DoorConfig = null
var _body: BodyConfig = null
var _query: WorldQuery = null


func _init(tuning: SimTuning, world: WorldQuery) -> void:
	_cfg = tuning.doors
	_body = tuning.body
	_query = world


## How many doors the level has.
func count() -> int:
	return _query.door_count()


## Every door as the map starts a round (WorldQuery.door_starts_shut), at rest, the level told; sizes `doors` to the
## level's doors.
func reset(doors: DoorState) -> void:
	var n := _query.door_count()
	doors.shut.resize(n)
	doors.swing_left.resize(n)
	for i in n:
		doors.shut[i] = _query.door_starts_shut[i]
		doors.swing_left[i] = 0.0
		_query.set_door_shut(i, doors.shut[i] != 0)


## The swings run on.
static func step(doors: DoorState, dt: float) -> void:
	for i in doors.swing_left.size():
		if doors.swing_left[i] > 0.0:
			doors.swing_left[i] = maxf(0.0, doors.swing_left[i] - dt)


## `c`'s Use press: toggles door `picked` if its controller picked one and it is in reach, else the door in reach
## nearest its view's line (`in_reach`), unless that door is swinging or would shut on a body. Whether a door moved.
func press(c: Character, picked: int, state: GameState) -> bool:
	var i := picked
	if i < 0 or i >= _query.door_count() or _to_leaf(_query, _cfg, c.position, i).length() > _cfg.reach:
		i = in_reach(_query, _cfg, c.position, c.yaw)
	return i >= 0 and toggle(i, c, state)


## A walk-off's way through a door (someone hit, walking to the dead zone on the simulation's command `cmd`): the shut
## door ahead of it in reach opens, as anyone's would.
func walk_through(c: Character, cmd: PlayerCommand, state: GameState) -> void:
	var way := way_of(cmd)
	if way == Vector2.ZERO:
		return
	var i := shut_ahead(_query, _cfg, state.doors, c.position, way)
	if i >= 0:
		toggle(i, c, state)


## Toggles door `i` for `c`: refused while it swings, or shutting onto a body. Whether it moved.
func toggle(i: int, c: Character, state: GameState) -> bool:
	var doors := state.doors
	if doors.swing_left[i] > 0.0:
		return false
	var shutting := not doors.is_shut(i)
	if shutting and blocked(i, state.characters):
		return false
	doors.shut[i] = 1 if shutting else 0
	doors.swing_left[i] = _cfg.swing_time
	_query.set_door_shut(i, shutting)
	var e := state.events.add(GameEvent.Kind.DOOR)
	e.actor = c.id
	e.target = i
	e.value = 1 if shutting else 0
	e.position = _query.door_centers[i]
	e.reach = _cfg.heard
	return true


## The door in reach of feet at `feet` (DoorConfig.reach, level, and reach_up of its foot) nearest the line of a view
## along `yaw`; -1 for none. Any door in reach counts: the view only picks between two.
static func in_reach(query: WorldQuery, cfg: DoorConfig, feet: Vector3, yaw: float) -> int:
	var look := Vector2(-sin(yaw), -cos(yaw))
	var best := -1
	var best_dot := -INF
	for i in query.door_count():
		var to := _to_leaf(query, cfg, feet, i)
		var d := to.length()
		if d > cfg.reach:
			continue
		var dot := look.dot(to / d) if d > AT_LEAF else 1.0
		if dot > best_dot:
			best = i
			best_dot = dot
	return best


## The shut door in reach of feet at `feet` whose leaf's nearest point lies within DoorConfig.ahead_angle of `way`
## (level, any length), and at rest; -1 for none. A bot's or a walk-off's: it opens what it is walking into.
static func shut_ahead(query: WorldQuery, cfg: DoorConfig, doors: DoorState, feet: Vector3, way: Vector2) -> int:
	if way == Vector2.ZERO or doors.count() != query.door_count():
		return -1
	var dir := way.normalized()
	var cos_ahead := cos(cfg.ahead_angle)
	for i in query.door_count():
		if not doors.is_shut(i) or doors.swing_left[i] > 0.0:
			continue
		var to := _to_leaf(query, cfg, feet, i)
		var d := to.length()
		if d > cfg.reach:
			continue
		if d < AT_LEAF or dir.dot(to / d) >= cos_ahead:
			return i
	return -1


## A command's walk as a level direction in the world (its forward and right turned by its yaw); zero standing still.
static func way_of(cmd: PlayerCommand) -> Vector2:
	var s := sin(cmd.yaw)
	var c := cos(cmd.yaw)
	return Vector2(-s * cmd.forward + c * cmd.right, -c * cmd.forward - s * cmd.right)


## From feet at `feet` to the nearest point of door `i`'s leaf, level; Vector2.INF when the feet are more than reach_up
## below or above its foot (another storey), or plainly out of reach along x or z.
static func _to_leaf(query: WorldQuery, cfg: DoorConfig, feet: Vector3, i: int) -> Vector2:
	var c := query.door_centers[i]
	var h := query.door_halves[i]
	# Far off along either level axis, or on another storey: out of reach without the rest.
	if absf(feet.x - c.x) > h.x + cfg.reach or absf(feet.z - c.z) > h.z + cfg.reach \
			or absf(feet.y - (c.y - h.y)) > cfg.reach_up:
		return Vector2.INF
	var nx := clampf(feet.x, c.x - h.x, c.x + h.x)
	var nz := clampf(feet.z, c.z - h.z, c.z + h.z)
	return Vector2(nx - feet.x, nz - feet.z)


## Whether anyone's body (in play or not) stands in door `i`'s leaf: it won't shut.
func blocked(i: int, characters: Array[Character]) -> bool:
	var c := _query.door_centers[i]
	var h := _query.door_halves[i]
	var r := _body.radius
	for ch in characters:
		var p := ch.position
		if p.y >= c.y + h.y or p.y + _body.height <= c.y - h.y:
			continue
		var dx := p.x - clampf(p.x, c.x - h.x, c.x + h.x)
		var dz := p.z - clampf(p.z, c.z - h.z, c.z + h.z)
		if dx * dx + dz * dz < r * r:
			return true
	return false
