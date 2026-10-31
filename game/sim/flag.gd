class_name Flag
## Attack / Defend's flags, one tick at a time (the browser game's sim/flag.ts): one pole, or two (A and B, AB1), each
## worked on its own; the attackers win by raising either. Allocates nothing.

## The most poles a map has, and what each is called, in the map's order.
const MOST := 2
const LETTERS: PackedStringArray = ["A", "B"]


## One tick of every pole (`step` on each); true once any is fully raised.
static func step_all(flags: Array[FlagState], characters: Array[Character], attackers: int, cfg: FlagConfig,
		events: SimEvents, dt: float) -> bool:
	var raised := false
	for f in flags:
		raised = step(f, characters, attackers, cfg, events, dt) or raised
	return raised


## Whether the attackers work any pole's rope (raising it, or contesting it there).
static func rope_worked(flags: Array[FlagState]) -> bool:
	for f in flags:
		if f.status == FlagState.Status.RAISING or f.status == FlagState.Status.CONTESTED:
			return true
	return false


## The pole whose flag is highest, the first on a tie; -1 while every flag is at the bottom.
static func highest(flags: Array[FlagState]) -> int:
	var best := -1
	var top := 0.0
	for i in flags.size():
		if flags[i].progress > top:
			top = flags[i].progress
			best = i
	return best


## The first pole whose flag is going up (RAISING); -1 for none.
static func going_up(flags: Array[FlagState]) -> int:
	for i in flags.size():
		if flags[i].status == FlagState.Status.RAISING:
			return i
	return -1


## The pole nearest `at` (flat); -1 with none.
static func nearest(flags: Array[FlagState], at: Vector3) -> int:
	var best := -1
	var best_d := INF
	for i in flags.size():
		var p := flags[i].position
		var d := Vector2(at.x - p.x, at.z - p.z).length_squared()
		if d < best_d:
			best_d = d
			best = i
	return best


## One tick (`dt` s) of the flag: attackers in play at the pole raise it, defenders pull it down, both at once hold it
## still, nobody leaves it where it is. A FLAG_ROPE event each time it passes a rope step (value 1 raising, 0
## lowering). True once it is fully raised.
static func step(flag: FlagState, characters: Array[Character], attackers: int, cfg: FlagConfig, events: SimEvents,
		dt: float) -> bool:
	var raising := false
	var lowering := false
	for c in characters:
		if not at_pole(c, flag, cfg):
			continue
		if c.team == attackers:
			raising = true
		else:
			lowering = true
	var before := flag.progress
	if raising and lowering:
		flag.status = FlagState.Status.CONTESTED
	elif raising:
		flag.status = FlagState.Status.RAISING
		flag.progress = minf(1.0, flag.progress + dt / cfg.raise_time)
	elif lowering:
		# Defenders at the bottom of an empty pole aren't pulling anything.
		flag.status = FlagState.Status.LOWERING if flag.progress > 0.0 else FlagState.Status.IDLE
		flag.progress = maxf(0.0, flag.progress - dt / cfg.lower_time)
	else:
		flag.status = FlagState.Status.IDLE
	if floori(flag.progress / cfg.rope_step) != floori(before / cfg.rope_step):
		var rope := events.add(GameEvent.Kind.FLAG_ROPE)
		rope.position = flag.position
		rope.value = 1 if flag.progress > before else 0
	return flag.progress >= 1.0


## True if `c` is in play and close enough to the pole (flat) to work the rope.
static func at_pole(c: Character, flag: FlagState, cfg: FlagConfig) -> bool:
	return Elimination.is_in_play(c) \
			and Vector2(c.position.x - flag.position.x, c.position.z - flag.position.z).length() <= cfg.radius
