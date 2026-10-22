class_name RangeChallenge
extends RefCounted
## The practice range's timed challenge (the browser game's sim/rangeChallenge.ts, M93): off by default. On, the START
## plate stands near the line; shoot it, wait out the countdown, then hit as many lit targets as you can before time
## runs out (RangeConfig's challenge numbers). Plain data in GameState.challenge, stepped by Simulation once a practice
## tick after the targets, from the tick's events: it lights and puts out GameState.targets, adds its cues as CHALLENGE
## events and keeps the run's tally. Lit targets are picked from the match's stream. A tick allocates nothing.

## OFF: free practice, no START plate. READY: the START plate stands, waiting for a hit. COUNTDOWN: the seconds before
## the run. RUNNING: the run itself.
enum Phase { OFF, READY, COUNTDOWN, RUNNING }
## A CHALLENGE event's value: COUNT, a second of the countdown (value2: the seconds left); GO, the run starts; TIME, it
## is over (RangeChallenge.last).
enum Cue { COUNT, GO, TIME }


## A finished run.
class Run:
	extends RefCounted
	## Lit targets hit, BBs fired, lit targets that went out unhit.
	var hits: int = 0
	var shots: int = 0
	var missed: int = 0
	## It beat the best kept before it.
	var best: bool = false
	## A Dev setting that changes play was on during it (RangeChallenge.helped): never a best, never kept.
	var helped: bool = false


var phase: Phase = Phase.OFF
## Where the best is kept (Records.best_challenge): the map's id, "range" on the range.
var course: String = ""
## The character whose START hit, BBs and target hits count: the player.
var player_id: int = 0
## Seconds left of the countdown or of the run.
var clock: float = 0.0
## The run under way: lit targets hit, BBs fired, lit targets that went out unhit.
var hits: int = 0
var shots: int = 0
var missed: int = 0
## The best score kept (Records.challenge_best for `course`), raised as a run beats it.
var best: int = 0
## The last finished run, until the next one starts (null before one).
var last: Run = null
## A Dev setting that changes play (DevCheats.any) was on at some point since the START plate was shot: the run is not
## a best, as such a match goes into no records.
var helped: bool = false
## `last`'s object, filled at each run's end (nothing allocated in a tick).
var _run: Run = Run.new()
## The targets that can light this tick, by index (lit_one), and how many: grown once, never shrunk.
var _candidates: PackedInt32Array = PackedInt32Array()


func _init(course_id: String = "", best_kept: int = 0) -> void:
	course = course_id
	best = best_kept


## Whether `targets` have a START plate, so the challenge can be played (a map may have none).
static func has_start(targets: Array[RangeTarget]) -> bool:
	for t in targets:
		if t.start:
			return true
	return false


## Turns the challenge on (the START plate stands, waiting) or off (free practice: a run under way is dropped, with no
## score). Pop-ups go back to standing by themselves (random times from `rng`). Without a START plate it stays off.
func set_on(on: bool, targets: Array[RangeTarget], cfg: RangeConfig, rng: RandomNumberGenerator) -> void:
	if (phase != Phase.OFF) == on or (on and not has_start(targets)):
		return
	phase = Phase.READY if on else Phase.OFF
	_clear(targets, on)
	RangeTargets.set_popups_auto(targets, true, cfg, rng)


## One tick of `dt` s, after the targets' (this tick's events in `events`): the player's hit on the START plate starts
## the countdown; in a run, their BBs are counted, a lit target they hit scores, a lit target whose time is up goes out
## (a miss), another lights in each one's place (from `rng`), and the run ends when its time is up, raising the best
## unless `cheating` (a Dev setting that changes play is on) was true at any tick since START. Cues are added to
## `events`.
func step(targets: Array[RangeTarget], events: SimEvents, cfg: RangeConfig, dt: float, rng: RandomNumberGenerator,
		cheating: bool) -> void:
	match phase:
		Phase.READY:
			if _start_shot(targets, events):
				phase = Phase.COUNTDOWN
				clock = cfg.challenge_countdown
				helped = cheating
				_cue(events, Cue.COUNT, ceili(clock))
				_clear(targets, false)
				RangeTargets.set_popups_auto(targets, false, cfg, rng)
		Phase.COUNTDOWN:
			helped = helped or cheating
			var before := ceili(clock)
			clock -= dt
			if clock > 0.0:
				if ceili(clock) < before:
					_cue(events, Cue.COUNT, ceili(clock))
				return
			phase = Phase.RUNNING
			clock = cfg.challenge_run_time
			hits = 0
			shots = 0
			missed = 0
			last = null
			_cue(events, Cue.GO, 0)
			for i in cfg.challenge_lit_at_once:
				_light_one(targets, cfg, rng)
		Phase.RUNNING:
			helped = helped or cheating
			_step_run(targets, events, cfg, dt, rng)


## A tick of the run itself (step).
func _step_run(targets: Array[RangeTarget], events: SimEvents, cfg: RangeConfig, dt: float,
		rng: RandomNumberGenerator) -> void:
	for i in events.count:
		var e := events.items[i]
		if e.actor != player_id:
			continue
		if e.kind == GameEvent.Kind.SHOT:
			shots += 1
		elif e.kind == GameEvent.Kind.TARGET_HIT and e.target >= 0 and e.target < targets.size():
			var t := targets[e.target]
			if t.lit > 0.0:
				hits += 1
				_put_out(t, cfg)
	var lit := 0
	for t in targets:
		if t.lit < 0.0:
			t.lit = minf(0.0, t.lit + dt)
		elif t.lit > 0.0:
			t.lit -= dt
			if t.lit > 0.0:
				lit += 1
			else:
				missed += 1
				_put_out(t, cfg)
	while lit < cfg.challenge_lit_at_once and _light_one(targets, cfg, rng):
		lit += 1
	clock -= dt
	if clock > 0.0:
		return
	# Time: the run's score is kept if it's the best, and the START plate stands for another go.
	_run.hits = hits
	_run.shots = shots
	_run.missed = missed
	_run.helped = helped
	_run.best = not helped and hits > best
	if _run.best:
		best = hits
	last = _run
	phase = Phase.READY
	clock = 0.0
	_cue(events, Cue.TIME, 0)
	_clear(targets, true)
	for t in targets:
		if t.motion == RangeTarget.Motion.POPUP and t.down <= 0.0:
			RangeTargets.knock_down(t, cfg.figure_down_time)
	RangeTargets.set_popups_auto(targets, true, cfg, rng)


## Whether this tick's events hold the player's hit on the START plate.
func _start_shot(targets: Array[RangeTarget], events: SimEvents) -> bool:
	for i in events.count:
		var e := events.items[i]
		if e.kind == GameEvent.Kind.TARGET_HIT and e.actor == player_id and e.target >= 0 \
				and e.target < targets.size() and targets[e.target].start:
			return true
	return false


## Lights one target picked at random (from `rng`) among those that can light, for its lit time; false when none can.
func _light_one(targets: Array[RangeTarget], cfg: RangeConfig, rng: RandomNumberGenerator) -> bool:
	if _candidates.size() < targets.size():
		_candidates.resize(targets.size())
	var n := 0
	for i in targets.size():
		if _can_light(targets[i], cfg):
			_candidates[n] = i
			n += 1
	if n == 0:
		return false
	var t := targets[_candidates[mini(n - 1, int(rng.randf() * n))]]
	t.lit = _lit_time(t, cfg)
	return true


## The target's lit time when it lights: longer for a far one (the BB's flight), and a lying pop-up's rise on top.
static func _lit_time(t: RangeTarget, cfg: RangeConfig) -> float:
	var rise := cfg.rise_time if t.motion == RangeTarget.Motion.POPUP and t.down > 0.0 else 0.0
	return cfg.challenge_lit_time + cfg.challenge_lit_per_metre * t.distance + rise


## Whether `t` can light now: in play, not lit or resting, and standing (or a held pop-up lying ready to rise).
static func _can_light(t: RangeTarget, cfg: RangeConfig) -> bool:
	if t.start or t.hidden or t.lit != 0.0:
		return false
	if t.kind == RangeTarget.Kind.STEEL:
		return true
	return t.down <= 0.0 or (t.motion == RangeTarget.Motion.POPUP and not t.auto and t.down <= cfg.rise_time)


## Puts `t` out: it rests a moment before it can light again (negative lit), and a standing pop-up drops.
static func _put_out(t: RangeTarget, cfg: RangeConfig) -> void:
	t.lit = -cfg.challenge_rest
	if t.motion == RangeTarget.Motion.POPUP and t.down <= 0.0:
		RangeTargets.knock_down(t, cfg.figure_down_time)


## Every target out and rested, the START plate shown or hidden.
static func _clear(targets: Array[RangeTarget], start_shown: bool) -> void:
	for t in targets:
		t.lit = 0.0
		if t.start:
			t.hidden = not start_shown


## Adds the cue `cue` (with `count`, the countdown's seconds left) to this tick's events, as the player's.
func _cue(events: SimEvents, cue: Cue, count: int) -> void:
	var e := events.add(GameEvent.Kind.CHALLENGE)
	e.actor = player_id
	e.value = cue
	e.value2 = count
