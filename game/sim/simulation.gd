class_name Simulation
extends RefCounted
## The fixed 60 Hz step (the browser game's sim/simulation.ts): everything the rules need from outside (tuning, the
## level, the map's ends) and one `step` that advances a GameState by a tick. The player and bots are indistinguishable
## here: each character follows the PlayerCommand stored under its id. Nodes call `step` from _physics_process and read
## the state and its events; headless tests call it directly.
##
## Order within a tick: each character moves (stance, pace, jump, collision; a Jump press at a low obstacle vaults it
## instead, and a vault under way follows its path), its legs swing, it leans and its aim settles, then it uses its
## replica (BBs leave from the new, leaned eye position); then every BB flies (hitting the level, bodies or range
## targets); then the round flow, or in practice (RoundState.practice) the range's targets, the timed challenge and full
## spares instead.
## Characters without a command keep their view and stand still; hit characters follow the hit-calling routine instead
## of their command, and once out and standing in the dead zone they are only timed. A squad order in a command becomes
## an event for the bots' controller and changes nothing here. A run into a noisy prop knocks it, and a BB landing hard
## on steel rings it (PropNoise, NP1). The weapon torch switches after the replica (Torch); hit, it goes out.

var tuning: SimTuning = null
var query: WorldQuery = null
var mover: CharacterMover = null
## The map's two ends: spawns and dead zones.
var ends: Array[MapEnd] = []
## Anything below this height has left the level (map data).
var kill_y: float = -10.0
## The map's nav grid, for walk-off routes round cover (set once the map is built); null walks them off in a straight
## line, as headless BoxWorld tests do.
var nav: NavGrid = null
## The level's noisy props (WorldQuery.block_kinds that tuning.noise lists), made with the simulation.
var noise: PropNoise = null
## Followed by characters with no command this tick.
var _idle: PlayerCommand = PlayerCommand.new()
## Followed by characters that have been hit: they take no orders from their controller.
var _eliminated: PlayerCommand = PlayerCommand.new()
## Followed while vaulting (the view, the trigger as the vault found it), and the first command after a vault, with the
## presses made during it (Vault).
var _vaulting: PlayerCommand = PlayerCommand.new()
var _after_vault: PlayerCommand = PlayerCommand.new()


func _init(sim_tuning: SimTuning, world: WorldQuery, character_mover: CharacterMover, map_ends: Array[MapEnd],
		level_kill_y: float) -> void:
	tuning = sim_tuning
	query = world
	mover = character_mover
	ends = map_ends
	kill_y = level_kill_y
	noise = PropNoise.new(sim_tuning.noise, world)


## A fresh match: a new breeze, everyone at their end's spawns, round 1 live.
func start_match(state: GameState) -> void:
	state.events.clear()
	state.match_number += 1
	state.off_record = state.dev_content or state.cheats.any()
	state.wind.draw(Seeds.wind_seed(state.match_seed, state.match_number), tuning.wind)
	Round.start_match(state.round_state, state.characters, ends, state.bbs, tuning, state.events)


## Advances `state` by one tick of `dt` seconds (none at all when `dt` isn't positive). `commands[id]` drives character `id` (null or missing: no input).
func step(state: GameState, commands: Array[PlayerCommand], dt: float) -> void:
	state.events.clear()
	# A step of no time is no tick: speeds are worked out as distance over dt.
	if not (dt > 0.0):
		return
	# Once the round is decided it's a cease-fire, as after the end whistle at a site: nobody can fire, and BBs still in
	# the air stop on whoever they reach without knocking them out.
	var live := state.round_state.is_live()
	Elimination.plan_walk_off_routes(state.characters, nav)
	var noisy := noise.count() > 0
	if noisy:
		noise.prepare(state)
	for c in state.characters:
		c.prev_position = c.position
		c.prev_crouch_amount = c.crouch_amount
		c.prev_lean = c.lean
		c.prev_walk_cycle = c.walk_cycle
		c.prev_yaw = c.yaw
		c.prev_pitch = c.pitch
		_squad_order(c, commands, live, state.events)
		var in_play := Elimination.is_in_play(c)
		# Hit, the torch goes out as the hand goes up (silently: the hit call is the sound).
		if not in_play:
			Torch.put_out(c)
		# Out and standing in the dead zone: only its clock runs (audit SIM-15).
		if Elimination.is_parked(c):
			Elimination.step(c, tuning.hits, dt)
			continue
		var cmd: PlayerCommand = null
		if in_play:
			cmd = commands[c.id] if c.id >= 0 and c.id < commands.size() else null
		else:
			cmd = Elimination.fill_eliminated_command(c, tuning, _eliminated)
		if cmd == null:
			cmd = _idle
			cmd.reset(c.yaw, c.pitch)
		# The torch's thumb switch works through a vault too (the vault's own command drops other presses until its end).
		var toggle_torch := in_play and cmd.toggle_torch
		# A Jump press at a low obstacle vaults it instead; while vaulting only the view follows the command, the trigger
		# stays as it was and other presses wait for the vault's end (BP5).
		if in_play and not c.vault.active:
			cmd = Vault.with_held_presses(c.vault, cmd, _after_vault)
			Vault.try_start(c, cmd, tuning, query, state.events)
		if in_play and c.vault.active:
			cmd = Vault.vaulting_command(c, cmd, _vaulting)
		if in_play:
			Aiming.step(c, cmd, tuning.movement, dt)
		else:
			c.aiming = false
			c.aim_raise = 0.0
		# A vault under way finishes even if its vaulter is hit meanwhile: nobody is left hanging over the obstacle.
		if c.vault.active:
			Vault.step(c, cmd, tuning, dt, mover)
		else:
			Movement.step(c, cmd, tuning.movement, tuning.accuracy, dt, mover)
			# Ran into a noisy prop: it knocks. A vault makes its own noise; someone hit and walking off makes none.
			if in_play and noisy:
				noise.knock(c, tuning.body, dt, state)
		c.rescue_if_out_of_world(kill_y)
		Hitbox.step_walk_cycle(c, tuning.hits) # the legs' swing, for their hit volumes and the drawn figure
		Lean.step(c, cmd, tuning, query, dt)
		Accuracy.step(c, tuning.movement, tuning.accuracy, dt)
		if not in_play:
			Elimination.step(c, tuning.hits, dt)
			continue
		Footsteps.step(c, tuning.footsteps, state.events, query, tuning.noise)
		# Fired on the run the kick grows, as the spread does (the owner's 0.1 Dev 5 note 9).
		var kick := tuning.accuracy.sprint_kick if c.sprinting else 1.0
		# BBs leave from the eyes, wherever a lean puts them; none through a vault or the moment after it.
		Armament.step(c, cmd, Lean.eye(c, tuning.body, tuning.hits), kick, live and c.fire_lockout <= 0.0, state.bbs,
				state.rng, state.events, tuning, dt, 0.0 if c.vault.active else c.fire_lockout)
		# After the armament: a switch or holster this tick to no light in hand puts the torch out.
		Torch.step(c, toggle_torch, state.events, dt)
	var first_bb_event := state.events.count
	BBStep.step(state.bbs, state.characters, query, tuning, kill_y, not live, ends, state.events, dt,
			state.wind.at(state.time), state.rng, state.targets)
	if noisy:
		noise.ring(state, first_bb_event)
	if state.round_state.practice:
		# Practice has no rounds: it's always live, with no clock.
		RangeTargets.step(state.targets, tuning, dt, state.rng)
		state.challenge.step(state.targets, state.events, tuning.targets, dt, state.rng, state.cheats.any())
		for c in state.characters:
			RangeTargets.refill_spares(c.armament)
	else:
		Round.step(state.round_state, state.characters, ends, state.bbs, tuning, state.events, dt)
	state.tick += 1
	state.time += dt


## A squad order in `c`'s command this tick: a SQUAD_ORDER event from a character in play in a `live` round, otherwise
## a refused one (out, or between rounds).
static func _squad_order(c: Character, commands: Array[PlayerCommand], live: bool, events: SimEvents) -> void:
	var cmd: PlayerCommand = commands[c.id] if c.id >= 0 and c.id < commands.size() else null
	if cmd == null or cmd.squad_order == SquadOrder.Kind.NONE:
		return
	var taken := live and Elimination.is_in_play(c)
	var e := events.add(GameEvent.Kind.SQUAD_ORDER if taken else GameEvent.Kind.SQUAD_ORDER_REFUSED)
	e.actor = c.id
	e.value = cmd.squad_order
	e.value2 = 1 if cmd.order_from_wheel else 0
