extends GutTest
## MH2 QA: what the bots' magazine hand-off does when a walk is cut short (a giver or an asker hit, the round ending),
## with two askers for one giver, and how often a bot presses (game/ai/bot_mag_share.gd). On an open field, headless:
## the last character is the opponent, far off, driven by nobody.

const DT := 1.0 / 60.0
const KILL_Y := -10.0
const EAST := -PI * 0.5
const YOU := 0
const FAR_ORANGE := Vector3(40.0, 0.0, -40.0)
## You out of every ask's reach, for the bot-only cases.
const YOU_AWAY := Vector3(-45.0, 0.0, -45.0)

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()
var rules: MagShareConfig = tuning.mag_share

var map: MapData = null
var nav: NavGrid = null
var state: GameState = null
var sim: Simulation = null
var bots: BotController = null
var commands: Array[PlayerCommand] = []
var you: Character = null
## Every event of the ticks run since the squad was made, by kind (GameEvent.Kind): how many, and the last of each.
var counts: Dictionary[int, int] = {}
var tosses: Array[Vector2i] = []
var catches: Array[Vector2i] = []
var _navs: Dictionary[String, NavGrid] = {}


## The open field, with a wall (centre, size) for each pair in `walls`.
func _field(walls: Array) -> MapData:
	var m := MapData.new()
	m.id = "open field"
	m.kill_y = KILL_Y
	var floor_block := MapData.Block.new()
	floor_block.kind = &"floor"
	floor_block.center = Vector3(0.0, -0.25, 0.0)
	floor_block.size = Vector3(100.0, 0.5, 100.0)
	m.blocks.append(floor_block)
	for pair: Array in walls:
		var wall := MapData.Block.new()
		wall.kind = &"wall"
		wall.center = pair[0]
		wall.size = pair[1]
		m.blocks.append(wall)
	for e in 2:
		var end := MapEnd.new()
		for i in 2:
			end.spawns.append(SpawnPoint.new(Vector3(-30.0 + 2.0 * i, 0.0, 20.0) if e == 0
					else FAR_ORANGE + Vector3(2.0 * i, 0.0, 0.0), EAST))
		end.dead_zone.append(SpawnPoint.new(Vector3(-45.0, 0.0, 45.0) if e == 0 else Vector3(45.0, 0.0, -45.0), 0.0))
		m.ends.append(end)
	return m


## Characters at `at` (you first; teams 0, 0, 0, 1 unless `teams` says), round 1 live and half a second gone, the bots
## holding their fire. With
## `player` -1 every character is a bot; the opponent is driven by nobody unless `enemy_bot`. `level` both teams';
## `walls` as _field.
func _squad(at: Array[Vector3], level: StringName = &"normal", teams: Array[int] = [0, 0, 0, 1], player: int = YOU,
		enemy_bot: bool = false, walls: Array = []) -> void:
	map = _field(walls)
	var w := BoxWorld.new(tuning.body)
	w.add_floor(100.0, 100.0)
	for pair: Array in walls:
		w.add_box(pair[0], pair[1])
	var layout := str(walls)
	if not _navs.has(layout):
		_navs[layout] = NavGrid.build(map, tuning.nav, tuning.body)
	nav = _navs[layout]
	sim = Simulation.new(tuning, w, w.mover(), map.ends, KILL_Y)
	sim.nav = nav
	state = GameState.new(5, tuning)
	var loadout := ReplicaStats.default_loadout()
	commands.clear()
	for i in at.size():
		state.characters.append(Character.new(i, teams[i], at[i], EAST, loadout))
		commands.append(PlayerCommand.new())
	var levels: Dictionary[int, StringName] = {0: level, 1: level}
	bots = BotController.new(state, player, map, nav, w, tuning, config, levels)
	sim.start_match(state)
	bots.observe(state)
	if not enemy_bot:
		for b in bots.world.bots:
			if b.character.id == at.size() - 1:
				bots.world.bots.erase(b)
				break
	for i in at.size():
		state.characters[i].position = at[i]
	# Nobody's BB ends the round under a test (a bot hunting its way to the opponent would): the hand-off alone.
	state.cheats.bots_hold_fire = true
	you = state.characters[YOU]
	commands[YOU].reset(EAST, 0.0)
	counts.clear()
	tosses.clear()
	catches.clear()
	_run(0.5)


func _tick() -> void:
	bots.think(state, commands, DT)
	sim.step(state, commands, DT)
	bots.observe(state)
	for i in state.events.count:
		var e := state.events.items[i]
		counts[e.kind] = counts.get(e.kind, 0) + 1
		if e.kind == GameEvent.Kind.MAG_TOSS:
			tosses.append(Vector2i(e.actor, e.target))
		elif e.kind == GameEvent.Kind.MAG_CATCH:
			catches.append(Vector2i(e.actor, e.target))
	# Your command stays as you left it but for the one-shot press.
	commands[YOU].mag_hand_off = false


func _run(seconds: float) -> void:
	for t in roundi(seconds / DT):
		_tick()


## Runs until a magazine is caught, for at most `seconds`; whether one was.
func _run_to_catch(seconds: float) -> bool:
	var before := catches.size()
	for t in roundi(seconds / DT):
		_tick()
		if catches.size() > before:
			return true
	return false


func _count(kind: GameEvent.Kind) -> int:
	return counts.get(kind, 0)


func _bot(id: int) -> Bot:
	for b in bots.world.bots:
		if b.character.id == id:
			return b
	return null


## You press the hand-off this tick.
func _press() -> void:
	commands[YOU].mag_hand_off = true
	_tick()


## `c` on its last magazine for `slot`.
static func _empty(c: Character, slot: int = 0) -> void:
	c.armament.ammo[slot].pouch.fill(0)


## `c` holds `n` full spares for `slot`, nothing else.
static func _spares(c: Character, n: int, slot: int = 0) -> void:
	var pouch := c.armament.ammo[slot].pouch
	pouch.fill(0)
	for i in mini(n, pouch.size()):
		pouch[i] = c.armament.replicas[slot].mag_size


## Every BB team 0 carries for `slot`, loaded and spare.
func _total(slot: int = 0) -> int:
	var n := 0
	for c in state.characters:
		if c.team == 0:
			n += c.armament.ammo[slot].mag + c.armament.ammo[slot].spare_bbs()
	return n


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- A walk cut short ---

## Bot 1 is the asker (low), bot 2 the giver 25 m off; you are out of every reach. The giver is walking over.
func _walking() -> void:
	_squad([YOU_AWAY, Vector3(-30.0, 0.0, 20.0), Vector3(-5.0, 0.0, 20.0), FAR_ORANGE])
	_empty(state.characters[1])
	_run(1.0)
	assert_eq(_bot(2).mag_for, state.characters[1], "set up: the giver is bringing it")
	assert_eq(_bot(2).mode, Bot.Mode.MAG, "set up: and walking")


func test_a_giver_hit_mid_walk_lets_go_and_the_asker_plays_on_without_a_press() -> void:
	_walking()
	var giver := _bot(2)
	var asker := _bot(1)
	giver.character.status = Character.Status.CALLING
	_run(0.5)
	assert_eq(giver.mag_for, null, "the job is let go")
	assert_lt(asker.character.mag.asked, 0, "the ask ends with its giver out")
	assert_ne(asker.mode, Bot.Mode.MAG, "the asker no longer waits for it")
	_run(rules.bot_ask_gap)
	assert_eq(_count(GameEvent.Kind.MAG_REFUSED), 0, "no press the simulation refuses")
	assert_eq(_count(GameEvent.Kind.MAG_TOSS), 0)
	assert_lte(_count(GameEvent.Kind.MAG_ASK), 1, "and no new ask inside the bot's gap")


func test_an_asker_hit_mid_walk_frees_the_giver_to_go_on() -> void:
	_walking()
	var giver := _bot(2)
	state.characters[1].status = Character.Status.CALLING
	_run(0.5)
	assert_eq(giver.mag_for, null, "the job is let go")
	assert_ne(giver.mode, Bot.Mode.MAG, "and the giver is back to its business")
	_run(5.0)
	assert_eq(_count(GameEvent.Kind.MAG_TOSS), 0, "nothing tossed to a bot that is out")
	assert_eq(_count(GameEvent.Kind.MAG_REFUSED), 0)


func test_the_round_ending_mid_walk_clears_the_jobs_and_the_next_round_starts_clean() -> void:
	_walking()
	var giver := _bot(2)
	var asker := _bot(1)
	state.characters[state.characters.size() - 1].status = Character.Status.CALLING # the opponent is out
	var starts := 0
	var guard := 0
	while guard < roundi(20.0 / DT) and starts == 0:
		_tick()
		starts += state.events.count_of(GameEvent.Kind.ROUND_START)
		guard += 1
	assert_eq(starts, 1, "the next round started")
	assert_eq(giver.mag_for, null, "no job carried over")
	assert_lt(asker.character.mag.asked, 0, "no ask carried over")
	assert_eq(state.characters[1].mag.coming, 0)
	_run(2.0)
	assert_ne(giver.mode, Bot.Mode.MAG)
	assert_ne(asker.mode, Bot.Mode.MAG)
	assert_eq(_count(GameEvent.Kind.MAG_REFUSED), 0, "nothing was pressed into the round break")


# --- Two askers for one giver ---

func test_two_askers_for_one_giver_are_both_served_and_neither_press_storms() -> void:
	_squad([YOU_AWAY, Vector3(-30.0, 0.0, 20.0), Vector3(-5.0, 0.0, 20.0), Vector3(-28.0, 0.0, 24.0), FAR_ORANGE],
			&"normal", [0, 0, 0, 0, 1])
	_empty(state.characters[1])
	_empty(state.characters[3])
	var giver := _bot(2)
	var caught := 0
	for i in roundi(20.0 / DT):
		_tick()
		caught = catches.size()
		if caught >= 2:
			break
	assert_eq(catches.size(), 2, "both askers get a magazine")
	assert_eq(giver.mag_for, null)
	assert_lte(_count(GameEvent.Kind.MAG_REFUSED), 2, "a refusal or two at most, never a storm")
	assert_false(MagShare.low_on(state.characters[1].armament, rules.low_mags))
	assert_false(MagShare.low_on(state.characters[3].armament, rules.low_mags))


# --- How often a bot presses ---

func test_a_giver_who_cannot_toss_yet_presses_no_more_than_once_a_second() -> void:
	# Two askers for one giver, one toss still in the air for the second: every press (a refusal or a toss) is spaced.
	_squad([YOU_AWAY, Vector3(-30.0, 0.0, 20.0), Vector3(-29.0, 0.0, 20.0), Vector3(-28.0, 0.0, 20.0), FAR_ORANGE],
			&"normal", [0, 0, 0, 0, 1])
	_empty(state.characters[1])
	_empty(state.characters[3])
	var presses: Array[float] = []
	for i in roundi(10.0 / DT):
		_tick()
		for n in state.events.count:
			var k := state.events.items[n].kind
			if state.events.items[n].actor == 2 and (k == GameEvent.Kind.MAG_TOSS or k == GameEvent.Kind.MAG_REFUSED):
				presses.append(state.time)
	for i in range(1, presses.size()):
		assert_gte(presses[i] - presses[i - 1], config.mag_press_gap - 0.05, "presses %d and %d" % [i - 1, i])


# --- Cover comes first ---

func test_a_giver_in_cover_stays_there_until_the_cover_episode_is_over_then_brings_it() -> void:
	_squad([YOU_AWAY, Vector3(-30.0, 0.0, 20.0), Vector3(-5.0, 0.0, 20.0), FAR_ORANGE])
	var giver := _bot(2)
	# The giver is down behind cover where it stands.
	giver.mode = Bot.Mode.COVER
	giver.cover.position = giver.character.position
	giver.cover.lean = 0
	giver.cover_phase = Bot.CoverPhase.DOWN
	giver.cover_since = state.time
	giver.cover_held = 0.0
	giver.cover_left = 30.0
	giver.cover_give_up = 30.0
	giver.peeks_left = 0
	giver.route_state = Bot.RouteState.NONE
	var at := giver.character.position
	_empty(state.characters[1])
	_run(2.0)
	assert_eq(giver.mag_for, state.characters[1], "the ask is taken")
	assert_eq(giver.mode, Bot.Mode.COVER, "but it stays down in cover")
	assert_lt(_flat(giver.character.position, at), 0.3, "and does not walk")
	giver.cover_since = state.time - config.cover_episode_max - 1.0 # the episode is over
	_run(1.0)
	assert_eq(giver.mode, Bot.Mode.MAG, "then it brings the magazine")
	assert_true(_run_to_catch(10.0), "and the ask is answered")
