extends GutTest
## Manual reloads (RL2; owner, 2026-10-29): with Settings › Controls › Reload on Manual, the default, a trigger pull on
## an empty replica only clicks dry and the Reload key loads it, under a prompt by the crosshair; Automatic reloads on
## the dry click as before. The setting reaches the simulation through the player's command (manual_reload); bots
## reload by their own command, so a match plays the same with every bot's command marked manual.

const DT := 1.0 / 60.0
const EYE := Vector3(0.0, 1.6, 0.0)
const SEED := 1
## Seconds of a Depot match the bots play with and without the dry click's reload.
const MATCH_SECONDS := 60.0
## BBs each bot's loaded magazine is left with as that match starts.
const PRIMED_BBS := 3

var tuning: SimTuning
var aeg: ReplicaConfig
var c: Character
var a: Armament
var cmd: PlayerCommand
var pool: BBPool
var rng: RandomNumberGenerator
var events: SimEvents
var counts: Dictionary[int, int] = {}


func before_each() -> void:
	tuning = SimTuning.new()
	var loadout := ReplicaStats.default_loadout()
	aeg = loadout[0]
	c = Character.new(1, 0, Vector3.ZERO, 0.0, loadout)
	a = c.armament
	cmd = PlayerCommand.new()
	pool = BBPool.new(64)
	rng = Seeds.stream(7)
	events = SimEvents.new()


## Runs `ticks` ticks with the trigger `fire` and the command's other fields as they are; the reload press is one-shot.
func run(ticks: int, fire: bool) -> void:
	counts.clear()
	cmd.fire = fire
	for i in ticks:
		events.clear()
		Armament.step(c, cmd, EYE, 1.0, true, pool, rng, events, tuning, DT)
		for k in events.count:
			var kind: int = events.items[k].kind
			counts[kind] = counts.get(kind, 0) + 1
		cmd.reload = false


func n(kind: GameEvent.Kind) -> int:
	return counts.get(kind, 0)


# --- the simulation ---

func test_a_manual_reload_never_starts_on_a_dry_click() -> void:
	cmd.manual_reload = true
	a.ammo[0].mag = 0
	for pull: int in 3:
		run(1, true)
		assert_eq(n(GameEvent.Kind.DRY_FIRE), 1, "pull %d clicks dry" % pull)
		assert_eq(n(GameEvent.Kind.RELOAD_START), 0, "pull %d never reloads" % pull)
		run(30, true)
		assert_eq(n(GameEvent.Kind.DRY_FIRE), 0, "a held trigger clicks once")
		run(1, false)
	assert_eq(a.mag(), 0, "still empty")
	assert_false(a.reloading())
	assert_true(a.reload_due())


func test_the_reload_key_loads_an_empty_replica_under_manual() -> void:
	cmd.manual_reload = true
	a.ammo[0].mag = 0
	run(1, true)
	cmd.reload = true
	run(1, false)
	assert_eq(n(GameEvent.Kind.RELOAD_START), 1)
	assert_false(a.reload_due(), "a reload under way is not due")
	run(ceili(aeg.reload_time / DT) + 1, false)
	assert_eq(a.mag(), aeg.mag_size)
	assert_false(a.reload_due())


func test_automatic_still_reloads_on_the_dry_click() -> void:
	a.ammo[0].mag = 0
	run(1, true)
	assert_eq(n(GameEvent.Kind.DRY_FIRE), 1)
	assert_eq(n(GameEvent.Kind.RELOAD_START), 1)


func test_a_reload_is_due_only_when_empty_with_a_spare_to_load() -> void:
	assert_false(a.reload_due(), "a full magazine")
	a.ammo[0].mag = 0
	assert_true(a.reload_due())
	a.ammo[0].pouch.fill(0)
	assert_false(a.reload_due(), "no magazine left to load")
	a.ammo[0].pouch[0] = aeg.mag_size
	a.holstered = true
	assert_false(a.reload_due(), "holstered: nothing in hand")
	a.holstered = false
	a.reload_queued = true
	assert_false(a.reload_due(), "one queued for the end of a draw")


func test_the_command_keeps_the_setting_through_a_copy_and_drops_it_on_reset() -> void:
	cmd.manual_reload = true
	var other := PlayerCommand.new()
	other.copy_from(cmd)
	assert_true(other.manual_reload)
	other.reset()
	assert_false(other.manual_reload, "bots and the pilots reset to automatic")


# --- the player's controller and the bots ---

func test_the_player_s_controller_writes_the_setting_into_each_command() -> void:
	var controls := ControlsConfig.new()
	assert_false(controls.auto_reload, "Manual by default")
	var input := PlayerInput.new()
	input.setup(controls, 1.5)
	add_child_autofree(input)
	input.active = true
	input.fill(cmd)
	assert_true(cmd.manual_reload)
	controls.auto_reload = true
	input.fill(cmd)
	assert_false(cmd.manual_reload)
	controls.auto_reload = false
	input.active = false
	input.fill(cmd)
	assert_true(cmd.manual_reload, "kept while the mouse is free too")


func test_a_bot_asks_for_its_own_reload_when_empty() -> void:
	var w := BotWorld.new()
	w.tuning = tuning
	w.cfg = BotConfig.load_default()
	var b := Bot.new(c, 1, w.cfg.skill_for(&"normal"), 2)
	a.ammo[0].mag = 0
	BotCombat.reload_when_due(b, w, cmd)
	assert_true(cmd.reload)


func test_a_match_plays_the_same_with_every_bot_on_manual_reload() -> void:
	var r := MatchRunner.new(self, "depot")
	await wait_physics_frames(2)
	var reloads: Array[int] = [0]
	var stuck: Array[int] = [0]
	# Each match's first tick leaves every bot a few BBs, so they run dry within the match.
	var primed: Array[bool] = [false]
	r.each_tick = func(state: GameState, _bots: BotController) -> void:
		if not primed[0]:
			primed[0] = true
			for ch in state.characters:
				var held := ch.armament.ammo[ch.armament.active]
				held.mag = mini(held.mag, PRIMED_BBS)
		for i in state.events.count:
			if state.events.items[i].kind == GameEvent.Kind.RELOAD_START:
				reloads[0] += 1
		for ch in state.characters:
			if Elimination.is_in_play(ch) and state.round_state.is_live() and ch.armament.reload_due():
				stuck[0] += 1
	var auto := r.play(SEED, MATCH_SECONDS)
	var auto_reloads := reloads[0]
	reloads[0] = 0
	stuck[0] = 0
	primed[0] = false
	r.manual_reload = true
	var manual := r.play(SEED, MATCH_SECONDS)
	r.free_level()
	assert_gt(reloads[0], 0, "the bots reloaded (%d shots)" % manual.shots)
	assert_eq(reloads[0], auto_reloads, "as many reloads as with the dry click's")
	assert_eq(manual.shots, auto.shots)
	assert_eq(manual.hits, auto.hits)
	assert_eq(manual.farthest, auto.farthest, "the same match")
	assert_lt(stuck[0], manual.ticks / 100, "no bot waits on an empty replica: %d ticks" % stuck[0])


# --- the setting ---

func test_the_setting_defaults_to_manual_and_a_save_from_before_loads_manual() -> void:
	assert_false(Settings.new().auto_reload)
	for version: int in [1, 2]:
		var s := Settings.new()
		s.from_dict(Settings.migrate_defaults({"aim_toggle": true}, version))
		assert_false(s.auto_reload, "a version %d file without it" % version)
		assert_true(s.aim_toggle)
	var saved := Settings.new()
	saved.auto_reload = true
	var back := Settings.new()
	back.from_dict(saved.to_dict())
	assert_true(back.auto_reload, "Automatic is kept")
	var wrong := Settings.new()
	wrong.from_dict({"auto_reload": "yes"})
	assert_false(wrong.auto_reload, "a wrong value keeps Manual")


func test_applying_the_controls_takes_the_setting() -> void:
	var play := PlayTuning.new()
	var s := Settings.new(play)
	s.auto_reload = true
	SettingsApply.apply_controls(s)
	assert_true(play.controls.auto_reload)
	s.auto_reload = false
	SettingsApply.apply_controls(s)
	assert_false(play.controls.auto_reload)


# --- the prompt ---

func _hud(you: Character) -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(HudConfig.new(), TeamConfig.new(), ViewConfig.new(), SimTuning.new(), you)
	return hud


func test_the_prompt_shows_while_a_manual_reload_is_due_and_hides_after() -> void:
	var hud := _hud(c)
	var state := GameState.new(1)
	state.characters.append(c)
	hud.manual_reload = true
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "a full magazine")
	a.ammo[0].mag = 0
	hud.update(state, 1.0, DT)
	assert_true(hud.reload_prompt_shown(), "empty, a spare to load")
	assert_eq(hud.reload_prompt().key_text(), KeyNames.of_action(&"reload"), "the key as bound")
	hud.manual_reload = false
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "Automatic: no prompt")
	hud.manual_reload = true
	a.reload_left = aeg.reload_time
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "gone once the reload starts")
	a.reload_left = 0.0
	state.round_state.phase = RoundState.Phase.MATCH_OVER
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "gone when the match ends")
	state.round_state.phase = RoundState.Phase.LIVE
	hud.update(state, 1.0, DT)
	assert_true(hud.reload_prompt_shown())
	c.status = Character.Status.CALLING
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "gone when you are hit")
	c.status = Character.Status.ALIVE
	a.ammo[0].pouch.fill(0)
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "no magazine left: no prompt")


func test_the_prompt_names_the_reload_key_as_rebound() -> void:
	var hud := _hud(c)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T
	InputMap.action_erase_events(&"reload")
	InputMap.action_add_event(&"reload", key)
	var state := GameState.new(1)
	state.characters.append(c)
	hud.manual_reload = true
	a.ammo[0].mag = 0
	hud.update(state, 1.0, DT)
	assert_eq(hud.reload_prompt().key_text(), KeyNames.name_of(KeyBindings.code_of_event(key)))
	InputMap.load_from_project_settings()
