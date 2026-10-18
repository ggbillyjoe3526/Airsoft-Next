extends GutTest
## The bots (game/ai/) on Depot, headless: whole matches of bots play out over several seeds with no friendly hits and
## nobody stuck or off the map; a bot sees only what it could, holds fire with a teammate in the line, hears gunfire
## through walls no better than you, finds cover that hides it, and settles its aim; a tick allocates nothing once warm.

const DT := 1.0 / 60.0

var tuning: SimTuning = SimTuning.load_default()
var config: BotConfig = BotConfig.load_default()
var style: MapStyle = MapStyle.new()
var map: MapData = null
var level: MapLevel = null
var nav: NavGrid = null

var state: GameState = null
var sim: Simulation = null
var bots: BotController = null
var commands: Array[PlayerCommand] = []


func before_all() -> void:
	map = MapData.load_map("depot", style, tuning.rounds.team_size)
	level = MapLevel.new()
	add_child(level)
	level.build(map, style, tuning.body)
	nav = NavGrid.build(map, tuning.nav, tuning.body)


func after_all() -> void:
	level.free()


## A match on Depot with seed `seed_value`: every character a bot when `player_id` is -1.
func _start(seed_value: int, player_id: int = -1) -> void:
	sim = Simulation.new(tuning, level.query(), level.mover(tuning.body), map.ends, map.kill_y)
	sim.nav = nav
	state = GameState.new(seed_value, tuning)
	var loadout := ReplicaStats.default_loadout()
	commands.clear()
	for i in tuning.rounds.team_size * 2:
		state.characters.append(Character.new(i, 0 if i < tuning.rounds.team_size else 1, Vector3.ZERO, 0.0, loadout))
		commands.append(PlayerCommand.new())
	bots = BotController.new(state, player_id, map, nav, level.query(), tuning, config)
	sim.start_match(state)
	bots.observe(state)


func _tick() -> void:
	bots.think(state, commands, DT)
	sim.step(state, commands, DT)
	bots.observe(state)


func _bot(id: int) -> Bot:
	for b in bots.world.bots:
		if b.character.id == id:
			return b
	return null


func test_whole_bot_matches_play_out_fairly_over_seeds() -> void:
	var friendly := 0
	var rescued := 0
	var timeouts := 0
	var rounds := 0
	var limit := roundi(tuning.rounds.round_time / DT) * 14
	for seed_value: int in [1, 2, 3]:
		_start(seed_value)
		var finished := false
		for t in limit:
			_tick()
			for i in state.events.count:
				var e := state.events.items[i]
				if e.kind == GameEvent.Kind.CHARACTER_HIT and e.actor >= 0 \
						and state.characters[e.actor].team == state.characters[e.target].team:
					friendly += 1
				elif e.kind == GameEvent.Kind.ROUND_OVER:
					rounds += 1
					if e.value2 == GameEvent.RoundEnd.TIME:
						timeouts += 1
				elif e.kind == GameEvent.Kind.MATCH_OVER:
					finished = true
			for c in state.characters:
				if c.position.y < map.kill_y + 1.0:
					rescued += 1
			if finished:
				break
		assert_true(finished, "seed %d: the match was won" % seed_value)
	gut.p("bot matches: %d rounds, %d by the clock, %d friendly hits" % [rounds, timeouts, friendly])
	assert_eq(friendly, 0, "no bot hit a teammate")
	assert_eq(rescued, 0, "nobody fell off the map")
	assert_lt(timeouts, rounds / 4 + 1, "rounds end in eliminations, not stand-offs")


func test_a_bot_does_not_see_an_enemy_behind_a_wall() -> void:
	_start(5)
	var watcher := _bot(0)
	var hidden := state.characters[3]
	# Either side of West yard's long wall (x = -17.5), facing each other, both still.
	watcher.character.position = Vector3(-14.0, 0.0, 0.0)
	watcher.character.yaw = PI * 0.5
	hidden.position = Vector3(-21.0, 0.0, 0.0)
	for c in state.characters:
		if c != watcher.character and c != hidden:
			c.status = Character.Status.OUT
	BotSenses.perceive(watcher, bots.world)
	assert_eq(watcher.target_id, -1, "a wall hides the enemy")
	hidden.position = Vector3(-16.0, 0.0, -2.5)
	BotSenses.perceive(watcher, bots.world)
	assert_eq(watcher.target_id, hidden.id, "in the open, in front, it is seen")


func test_a_bot_holds_fire_with_a_teammate_in_the_line() -> void:
	_start(6)
	var shooter := _bot(0)
	var mate := state.characters[1]
	var enemy := state.characters[3]
	shooter.character.position = Vector3(-10.0, 0.0, 0.0)
	enemy.position = Vector3(-10.0, 0.0, -12.0)
	mate.position = Vector3(-10.0, 0.0, -6.0)
	shooter.character.yaw = 0.0
	for c in state.characters:
		c.prev_position = c.position
		if c != shooter.character and c != mate and c != enemy:
			c.status = Character.Status.OUT
	var shots := 0
	for t in 180:
		mate.position = Vector3(-10.0, 0.0, -6.0)
		bots.think(state, commands, DT)
		if commands[0].fire:
			shots += 1
		state.time += DT
	assert_eq(shots, 0, "never fires through a teammate")


func test_gunfire_is_heard_and_walls_muffle_it() -> void:
	_start(7)
	var ear := _bot(0)
	ear.character.position = Vector3(-14.0, 0.0, 0.0)
	var shooter := state.characters[3]
	shooter.position = Vector3(-14.0, 0.0, -10.0)
	var e := state.events
	e.clear()
	var shot := e.add(GameEvent.Kind.SHOT)
	shot.actor = 3
	shot.position = shooter.position + Vector3(0.0, 1.5, 0.0)
	BotHearing.observe(state, bots.world)
	assert_true(ear.has_last_known, "a shot 10 m off is heard, walls or not")
	assert_lt(Vector2(ear.last_known.x + 14.0, ear.last_known.z + 10.0).length(), 4.0, "about where it was")
	ear.has_last_known = false
	ear.heard_at = -INF
	# 19 m through the yard wall: beyond the wall's share of the range.
	shooter.position = Vector3(-21.0, 0.0, -18.0)
	shot.position = shooter.position + Vector3(0.0, 1.5, 0.0)
	BotHearing.observe(state, bots.world)
	assert_false(ear.has_last_known, "a wall cuts the range")


func test_cover_found_hides_from_the_threat() -> void:
	_start(8)
	var b := _bot(0)
	var w := bots.world
	var found := 0
	for i in 20:
		var from := w.nav.random_walkable_near(Vector3(0.0, 0.0, 0.0), 14.0, b.rng)
		var threat := w.nav.random_walkable_near(from, 14.0, b.rng) + Vector3(0.0, tuning.body.stand_eye_height, 0.0)
		if BotCover.find(from, threat, w, b.rng, b.cover, config.cover_radius, config.cover_candidates, false,
				BotRoutes.taken(), 0):
			found += 1
			assert_true(b.cover.lean != 0 or BotCover.hides_from(b.cover.position, threat, w),
					"cover at %s hides from %s" % [b.cover.position, threat])
	assert_gt(found, 5, "Depot has cover nearly everywhere")


func test_aim_error_settles_with_time_on_target() -> void:
	var skill := config.skill
	var fresh := BotAim.error_size(0.0, false, 20.0, 0.0, skill)
	var settled := BotAim.error_size(skill.aim_settle_time * 2.0, false, 20.0, 0.0, skill)
	assert_gt(fresh, settled)
	assert_gt(BotAim.error_size(skill.aim_settle_time * 2.0, true, 20.0, 0.0, skill), settled, "worse on the move")


func test_bot_ticks_allocate_no_objects_once_warm() -> void:
	_start(9)
	# Warm: a whole round played (contacts, cover searches, BBs in flight, the round's reset).
	var rounds := 0
	for t in roundi(tuning.rounds.round_time / DT) * 2:
		_tick()
		rounds += state.events.count_of(GameEvent.Kind.ROUND_START)
		if rounds >= 1:
			break
	for t in 600:
		_tick()
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for t in 600:
		_tick()
	assert_eq(Performance.get_monitor(Performance.OBJECT_COUNT), before)
