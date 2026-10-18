extends GutTest
## Holster edge cases beyond test_holster.gd: the player's press ordering, a press made through a vault, a respawn, and
## the bots' rules (own half only, a threat draws it).

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


func before_each() -> void:
	sim = Simulation.new(tuning, level.query(), level.mover(tuning.body), map.ends, map.kill_y)
	sim.nav = nav
	state = GameState.new(7, tuning)
	commands.clear()
	for i in tuning.rounds.team_size * 2:
		state.characters.append(Character.new(i, 0 if i < tuning.rounds.team_size else 1, Vector3.ZERO, 0.0,
				ReplicaStats.default_loadout()))
		commands.append(PlayerCommand.new())
	bots = BotController.new(state, -1, map, nav, level.query(), tuning, config)
	sim.start_match(state)
	bots.observe(state)
	for i in 5:
		bots.think(state, commands, DT)
		sim.step(state, commands, DT)
		bots.observe(state)


func after_each() -> void:
	Input.action_release(&"holster")


## A calm bot sprinting long enough, `in_half` of the field it is in.
func _calm_sprinter(enemy_half: bool) -> Bot:
	var b: Bot = bots.world.bots[0]
	b.last_threat_at = -INF
	b.target_visible = false
	b.sprint_run = config.holster_after + 1.0
	b.sprint_gap = 0.0
	var home := bots.world.planner.spawn_centre[b.character.team]
	var enemy := bots.world.planner.spawn_centre[1 - b.character.team]
	var at := home.lerp(enemy, 0.9 if enemy_half else 0.1)
	b.character.position = Vector3(at.x, b.character.position.y, at.z)
	return b


func _step_bot(b: Bot, sprint: bool) -> PlayerCommand:
	var cmd := PlayerCommand.new()
	cmd.sprint = sprint
	BotHolster.step(b, bots.world, cmd, DT)
	return cmd


func test_a_calm_bot_in_its_own_half_puts_the_replica_away() -> void:
	var b := _calm_sprinter(false)
	assert_false(bots.world.planner.in_enemy_half(b))
	var cmd := _step_bot(b, true)
	assert_true(cmd.holster)
	assert_eq(cmd.switch_to, -1, "and keeps it away")


func test_a_bot_in_the_enemy_half_keeps_it_in_hand() -> void:
	var b := _calm_sprinter(true)
	assert_true(bots.world.planner.in_enemy_half(b))
	assert_false(_step_bot(b, true).holster)


func test_a_threat_draws_a_holstered_bot_replica() -> void:
	var b := _calm_sprinter(false)
	b.character.armament.holstered = true
	assert_eq(_step_bot(b, true).switch_to, -1, "calm: stays away")
	b.last_threat_at = bots.world.time
	var cmd := _step_bot(b, true)
	assert_false(cmd.holster)
	assert_eq(cmd.switch_to, 0, "a threat draws it")


func test_an_aim_pressed_mid_vault_is_not_seen_until_it_is_over() -> void:
	var c := state.characters[0]
	var a := c.armament
	a.holstered = true
	a.aim_was_down = false
	c.vault.active = true
	var held := PlayerCommand.new()
	held.aim = true
	var mid := Vault.vaulting_command(c, held, PlayerCommand.new())
	assert_false(mid.aim, "an aim pressed mid-vault is not seen during it")
	c.vault.active = false


func test_a_respawned_character_has_the_replica_in_hand() -> void:
	var c := state.characters[0]
	c.armament.holstered = true
	c.armament.refill()
	assert_false(c.armament.holstered)
	assert_false(c.armament.drawing())


func test_holster_pressed_while_holstered_says_nothing_again() -> void:
	var total := 0
	for i in 3:
		commands[0].reset(state.characters[0].yaw, state.characters[0].pitch)
		commands[0].holster = true
		sim.step(state, commands, DT)
		total += state.events.count_of(GameEvent.Kind.HOLSTER)
	assert_eq(total, 1, "said once")
	assert_true(state.characters[0].armament.holstered)
