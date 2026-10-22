class_name Flag
## Attack / Defend's flag, one tick at a time (the browser game's sim/flag.ts). Allocates nothing.


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
