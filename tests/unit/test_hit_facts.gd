extends GutTest
## What the "What got you" card is told about a hit on you (HitFacts, kept by BotController; the browser game's
## hitFacts.test.ts): whether the bot was holding the angle, how long it had you in view, where it shot from and whether
## you were moving. A teammate's BB, or a hit on someone else, says nothing of the bot's side.

const DT := 1.0 / 60.0
const PLAYER := 0
const SHOOTER := 3

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


func _start() -> void:
	sim = Simulation.new(tuning, level.query(), level.mover(tuning.body), map.ends, map.kill_y)
	sim.nav = nav
	state = GameState.new(3, tuning)
	var loadout := ReplicaStats.default_loadout()
	commands.clear()
	for i in tuning.rounds.team_size * 2:
		state.characters.append(Character.new(i, 0 if i < tuning.rounds.team_size else 1, Vector3.ZERO, 0.0, loadout))
		commands.append(PlayerCommand.new())
	bots = BotController.new(state, PLAYER, map, nav, level.query(), tuning, config)
	sim.start_match(state)
	bots.observe(state)


func _bot(id: int) -> Bot:
	for b in bots.world.bots:
		if b.character.id == id:
			return b
	return null


## A Pro bot 12 m up East yard from you, facing you (its view `off_deg` off you), standing at a post when `holding`;
## everyone else out. Plays until it hits you (at most 12 s); returns when it first saw you.
func _duel(holding: bool, off_deg: float = 0.0, walk: bool = false) -> float:
	_start()
	var me := state.characters[PLAYER]
	var b := _bot(SHOOTER)
	me.position = Vector3(20.0, 0.0, 0.0)
	b.character.position = Vector3(20.0, 0.0, -12.0)
	b.character.yaw = PI
	me.yaw = 0.0
	b.skill = config.pro_skill.duplicate() as BotSkill
	b.skill.contact_cover_min_distance = INF
	b.aim_yaw = b.character.yaw + deg_to_rad(off_deg)
	b.aim_pitch = 0.0
	b.think_left = 0.0
	for c in state.characters:
		c.prev_position = c.position
		if c != me and c != b.character:
			c.status = Character.Status.OUT
	# Well into the round, so a first sight stamped as time zero would show.
	state.time = 5.0
	var first_seen := NAN
	for i in int(12.0 / DT):
		b.holding = holding
		bots.think(state, commands, DT)
		commands[PLAYER].reset(me.yaw, me.pitch)
		if walk:
			commands[PLAYER].forward = 1.0
		sim.step(state, commands, DT)
		bots.observe(state)
		if is_nan(first_seen) and b.contact != null:
			first_seen = b.contact.first_seen_at
		if bots.last_hit.time > -INF:
			break
	assert_gt(bots.last_hit.time, 0.0, "the bot hit you")
	return first_seen


func test_a_pro_bot_at_a_post_with_its_view_on_you_was_holding_the_angle() -> void:
	var first_seen := _duel(true)
	var f := bots.last_hit
	assert_eq([f.victim_id, f.shooter_id, f.friendly], [PLAYER, SHOOTER, false])
	assert_true(f.held_known)
	assert_true(f.held, "holding the angle")
	assert_almost_eq(f.in_view, f.time - first_seen, 0.02, "from its first sight to the hit")
	assert_gte(f.in_view, config.pro_skill.pre_aim_reaction_time.x - 0.02, "at least its reaction")
	assert_almost_eq(f.distance, 12.0, 0.5)
	assert_almost_eq(f.from_shooter.y, 1.0, 0.05, "the BB came down the yard from it to you")
	assert_false(f.moving, "you stood still")


func test_not_held_when_it_was_moving_or_looking_elsewhere() -> void:
	_duel(false)
	assert_true(bots.last_hit.held_known)
	assert_false(bots.last_hit.held, "not at a post")
	_duel(true, 40.0)
	assert_false(bots.last_hit.held, "its view was off you")


func test_moving_when_you_walk_into_the_hit() -> void:
	_duel(true, 0.0, true)
	assert_true(bots.last_hit.moving)


func test_a_teammates_bb_says_nothing_of_the_bot_side_and_a_hit_on_a_bot_is_not_kept() -> void:
	_start()
	state.characters[1].position = Vector3(3.0, 0.0, 4.0)
	state.characters[PLAYER].position = Vector3.ZERO
	_hit(1, PLAYER)
	var f := bots.last_hit
	assert_true(f.friendly)
	assert_false(f.held_known)
	assert_eq(f.in_view, -1.0)
	assert_almost_eq(f.distance, 5.0, 1e-4)
	var at := f.time
	state.time += 1.0
	_hit(SHOOTER, 1)
	_hit(PLAYER, SHOOTER)
	assert_eq(bots.last_hit.time, at, "only hits on you are kept")
	assert_eq(bots.last_hit.shooter_id, 1)


func test_no_controller_player_keeps_nothing() -> void:
	_start()
	bots = BotController.new(state, -1, map, nav, level.query(), tuning, config)
	_hit(SHOOTER, PLAYER)
	assert_eq(bots.last_hit.time, -INF, "every character a bot: no card")


## One CHARACTER_HIT of `target` by `actor` handed to the bots.
func _hit(actor: int, target: int) -> void:
	state.events.clear()
	var e := state.events.add(GameEvent.Kind.CHARACTER_HIT)
	e.actor = actor
	e.target = target
	bots.observe(state)


func test_a_new_match_clears_the_last_hit_but_a_drawn_round_1_does_not() -> void:
	_start()
	_hit(SHOOTER, PLAYER)
	state.events.clear()
	state.round_state.draws = 1
	state.events.add(GameEvent.Kind.ROUND_START).value = 1
	bots.observe(state)
	assert_gt(bots.last_hit.time, -INF, "round 1 played again after a draw: the same match")
	state.events.clear()
	state.round_state.draws = 0
	state.events.add(GameEvent.Kind.ROUND_START).value = 1
	bots.observe(state)
	assert_eq(bots.last_hit.time, -INF, "a rematch starts with no hit on you")
