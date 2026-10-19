class_name MatchRunner
extends RefCounted
## Whole Elimination matches of bots against bots, headless and as fast as the machine allows: the map's level built
## once (its Jolt colliders, so it must be in the tree), then each match stepped tick by tick with no rendering and no
## waiting for frames. Each match comes back as a MatchTally of what the guards (tests/guards/) and the balance report
## (BR1) read. Test-only (tests/ never ships).

const DT := 1.0 / 60.0
const TICKS_PER_SECOND := 60
## Held up: a bot walking its lane or hunting (Bot.Mode ADVANCE or SEARCH) that has moved less than HELD_UP_DISTANCE
## (m) over the last HELD_UP_SECONDS (sampled once a second) counts one episode until it moves on.
const HELD_UP_SECONDS := 10
const HELD_UP_DISTANCE := 0.5
## A character that ends a round in play without ever getting this far from its spawn (m) stayed home that round.
const LEAVES_SPAWN := 8.0


## One round, as it ended.
class RoundTally:
	extends RefCounted
	## The winning team, or -1 for a draw; why it ended (GameEvent.RoundEnd); how long it lasted (s).
	var winner: int = -1
	var reason: int = 0
	var seconds: float = 0.0
	## Which end of the map each team started from this round (ends swap at half time): Alpha's end.
	var alpha_end: int = 0
	## The round's first knock-out: when (s into the round), and how far the shooter stood from the target (m); -1
	## if nobody was hit.
	var first_hit_time: float = -1.0
	var first_hit_range: float = -1.0
	## Each character's farthest distance from this round's spawn (m, level).
	var farthest: PackedFloat32Array = PackedFloat32Array()


## One match: its rounds and everything that must never happen, counted.
class MatchTally:
	extends RefCounted
	var map_id: String = ""
	var seed_value: int = 0
	## The kit each bot picked, by character id ("" for one carrying its replicas as they come).
	var kits: PackedStringArray = PackedStringArray()
	var rounds: Array[RoundTally] = []
	## A team won the match before the tick limit.
	var finished: bool = false
	var ticks: int = 0
	## Each character's farthest distance from its round's spawn (m, level), over the whole match.
	var farthest: PackedFloat32Array = PackedFloat32Array()
	## Rounds a character ended still in play but never more than LEAVES_SPAWN from its spawn (one per character and
	## round).
	var stayed_home: int = 0
	## Bots held up on their way (episodes; see HELD_UP_SECONDS).
	var held_up: int = 0
	## Lowest and highest feet over the match (m), and the longest a character spent off the ground outside a vault
	## (s): one figure each for the whole match, all the guards need (BR1 reads rounds and hits, not these).
	var min_y: float = INF
	var max_y: float = -INF
	var longest_air: float = 0.0
	## Knock-outs in all; those by a teammate's BB (direct), and by the shooter's own bounced BB. A teammate reached
	## by a bounced BB while ricochets don't count (a RICOCHET_TICK) is counted apart.
	var hits: int = 0
	var friendly_hits: int = 0
	var self_hits: int = 0
	var friendly_ricochets: int = 0
	## Ticks a character in or out of play spent within a metre above the kill height (falling out of the level; the
	## simulation puts it back below it).
	var rescued: int = 0

	## Rounds that ran out the clock.
	func on_time() -> int:
		var n := 0
		for r in rounds:
			if r.reason == GameEvent.RoundEnd.TIME:
				n += 1
		return n


var tuning: SimTuning = null
## Every bot, on both teams, picks a kit from data/bot-kits.md at its team's difficulty (the same weights for both at one
## level, so the map's ends stay comparable); off, they all carry their replicas as they come.
var kitted: bool = true
## Both teams' level (MatchOptions.BOT_LEVELS), or team 0's when `beta_difficulty` is set: a ladder match, one level
## against another.
var difficulty: StringName = &"normal"
var beta_difficulty: StringName = &""
var _kits: BotKits = null
var _kit_rules: LoadoutRules = null
var config: BotConfig = null
var map: MapData = null
var level: MapLevel = null
var nav: NavGrid = null
## The lowest floor's top and the highest block's top on the map (m), for the height guards.
var lowest_floor: float = INF
var highest_top: float = -INF


## Builds `map_id`'s level under `parent` (it stays there until `free_level`). Check `map.problems` before trusting
## the height bounds: a map refused for having no floor leaves `lowest_floor` at INF.
func _init(parent: Node, map_id: String, sim_tuning: SimTuning = null, bot_config: BotConfig = null) -> void:
	tuning = sim_tuning if sim_tuning != null else SimTuning.load_default()
	config = bot_config if bot_config != null else BotConfig.load_default()
	var style := MapStyle.new()
	map = MapData.load_map(map_id, style, tuning.rounds.team_size)
	level = MapLevel.new()
	parent.add_child(level)
	level.build(map, style, tuning.body)
	nav = NavGrid.build(map, tuning.nav, tuning.body)
	for b in map.blocks:
		var top := b.center.y + b.size.y * 0.5
		highest_top = maxf(highest_top, top)
		if b.kind == &"floor" or b.rise != MapData.Rise.NONE:
			lowest_floor = minf(lowest_floor, top if b.rise == MapData.Rise.NONE else b.center.y - b.size.y * 0.5)


## Team `team`'s level.
func team_level(team: int) -> StringName:
	return beta_difficulty if team == 1 and beta_difficulty != &"" else difficulty


func free_level() -> void:
	if level != null:
		level.free()
		level = null


## Plays one whole match on `seed_value`, every character a bot, for at most `max_seconds` of match time.
func play(seed_value: int, max_seconds: float) -> MatchTally:
	var sim := Simulation.new(tuning, level.query(), level.mover(tuning.body), map.ends, map.kill_y)
	sim.nav = nav
	var state := GameState.new(seed_value, tuning)
	var loadout := ReplicaStats.default_loadout()
	var commands: Array[PlayerCommand] = []
	var size := tuning.rounds.team_size
	var kit_names := PackedStringArray()
	if kitted and _kits == null:
		_kits = BotKits.shared()
		_kit_rules = LoadoutRules.standard()
	var levels: Dictionary[int, StringName] = {0: difficulty, 1: team_level(1)}
	for i in size * 2:
		var kit_level := levels[0 if i < size else 1]
		var plan := _kits.pick(kit_level, _kit_rules, Seeds.kit_seed(seed_value, i)) if kitted else null
		kit_names.append(plan.kit_name if plan != null else "")
		if plan == null:
			state.characters.append(Character.new(i, 0 if i < size else 1, Vector3.ZERO, 0.0, loadout))
		else:
			var kit := BotKits.kit_of(plan, _kit_rules)
			state.characters.append(Character.new(i, 0 if i < size else 1, Vector3.ZERO, 0.0, kit.replicas,
					kit.bb_weights))
		commands.append(PlayerCommand.new())
	var bots := BotController.new(state, -1, map, nav, level.query(), tuning, config, levels)
	var t := MatchTally.new()
	t.kits = kit_names
	t.map_id = map.id
	t.seed_value = seed_value
	t.farthest.resize(state.characters.size())
	sim.start_match(state)
	bots.observe(state)
	var round_now := _new_round(state)
	var round_start := state.time
	var limit := roundi(max_seconds / DT)
	var n := state.characters.size()
	# Each character's position once a second for the last HELD_UP_SECONDS, and whether it is held up now.
	var trail: Array[PackedVector3Array] = []
	var held := PackedByteArray()
	held.resize(n)
	for i in n:
		var ring := PackedVector3Array()
		ring.resize(HELD_UP_SECONDS)
		ring.fill(Vector3.INF)
		trail.append(ring)
	while t.ticks < limit and not t.finished:
		bots.think(state, commands, DT)
		sim.step(state, commands, DT)
		bots.observe(state)
		t.ticks += 1
		_watch(state, t, round_now)
		if t.ticks % TICKS_PER_SECOND == 0:
			_watch_held_up(state, bots, t, trail, held, (t.ticks / TICKS_PER_SECOND) % HELD_UP_SECONDS)
		for i in state.events.count:
			var e := state.events.items[i]
			match e.kind:
				GameEvent.Kind.CHARACTER_HIT:
					count_hit(state, e, t)
					var shooter := state.character(e.actor)
					var target := state.character(e.target)
					if shooter != null and target != null and round_now.first_hit_time < 0.0:
						round_now.first_hit_time = state.time - round_start
						round_now.first_hit_range = shooter.position.distance_to(target.position)
				GameEvent.Kind.RICOCHET_TICK:
					count_ricochet(state, e, t)
				GameEvent.Kind.ROUND_OVER:
					for c in state.characters:
						if Elimination.is_in_play(c) and round_now.farthest[c.id] <= LEAVES_SPAWN:
							t.stayed_home += 1
					round_now.winner = e.value
					round_now.reason = int(e.value2)
					round_now.seconds = state.time - round_start
					t.rounds.append(round_now)
				GameEvent.Kind.ROUND_START:
					round_now = _new_round(state)
					round_start = state.time
					for ring in trail:
						ring.fill(Vector3.INF)
				GameEvent.Kind.MATCH_OVER:
					t.finished = true
	return t


## One knock-out (a CHARACTER_HIT) counted: by a teammate's BB, or by the shooter's own bounced BB.
static func count_hit(state: GameState, e: GameEvent, t: MatchTally) -> void:
	t.hits += 1
	var shooter := state.character(e.actor)
	var target := state.character(e.target)
	if shooter == null or target == null:
		return
	if e.actor == e.target:
		t.self_hits += 1
	elif shooter.team == target.team:
		t.friendly_hits += 1


## A bounced BB that reached someone while ricochets don't count (a RICOCHET_TICK): counted if it was a teammate's.
static func count_ricochet(state: GameState, e: GameEvent, t: MatchTally) -> void:
	var from := state.character(e.actor)
	var reached := state.character(e.target)
	if from != null and reached != null and e.actor != e.target and from.team == reached.team:
		t.friendly_ricochets += 1


func _new_round(state: GameState) -> RoundTally:
	var r := RoundTally.new()
	r.farthest.resize(state.characters.size())
	for c in state.characters:
		if c.team == 0:
			r.alpha_end = c.end
			break
	return r


## Once a second: a bot that should be walking (its lane, or a hunt) but has barely moved for HELD_UP_SECONDS starts
## a held-up episode, which lasts until it moves on.
func _watch_held_up(state: GameState, bots: BotController, t: MatchTally, trail: Array[PackedVector3Array],
		held: PackedByteArray, slot: int) -> void:
	for c in state.characters:
		var ring := trail[c.id]
		var then := ring[slot]
		ring[slot] = c.position
		var mode := bots.mode_of(c.id)
		var walking := mode == Bot.Mode.ADVANCE or mode == Bot.Mode.SEARCH
		var still := then != Vector3.INF and c.position.distance_to(then) < HELD_UP_DISTANCE
		var now := 1 if Elimination.is_in_play(c) and state.round_state.is_live() and walking and still else 0
		if now == 1 and held[c.id] == 0:
			t.held_up += 1
		held[c.id] = now


## The tick's heights, air time and distances from spawn, for everyone still in play. Distances only while the round
## is live: between rounds the ends may swap, so a spawn moves before its character does.
func _watch(state: GameState, t: MatchTally, r: RoundTally) -> void:
	var live := state.round_state.is_live()
	for c in state.characters:
		if c.position.y < map.kill_y + 1.0:
			t.rescued += 1
		if not Elimination.is_in_play(c):
			continue
		t.min_y = minf(t.min_y, c.position.y)
		t.max_y = maxf(t.max_y, c.position.y)
		if not c.vault.active:
			t.longest_air = maxf(t.longest_air, 0.0 if c.grounded else c.air_time)
		if not live:
			continue
		var away := Vector2(c.position.x - c.spawn_position.x, c.position.z - c.spawn_position.z).length()
		t.farthest[c.id] = maxf(t.farthest[c.id], away)
		r.farthest[c.id] = maxf(r.farthest[c.id], away)
