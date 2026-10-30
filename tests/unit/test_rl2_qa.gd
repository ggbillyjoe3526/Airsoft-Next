extends GutTest
## QA hunt for RL2 (manual reloads): the states test_manual_reload.gd leaves out. Mid-burst and held-trigger runs dry,
## no spare, a swap to the pistol and back, a draw, sprint, the vault, a spare arriving while empty, round phases,
## a rebind while the prompt is up, a corrupt setting. Agent: qa

const DT := 1.0 / 60.0
const EYE := Vector3(0.0, 1.6, 0.0)

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
	cmd.manual_reload = true
	pool = BBPool.new(64)
	rng = Seeds.stream(7)
	events = SimEvents.new()


func run(ticks: int, fire: bool, can_fire: bool = true) -> void:
	counts.clear()
	cmd.fire = fire
	for i in ticks:
		events.clear()
		Armament.step(c, cmd, EYE, 1.0, can_fire, pool, rng, events, tuning, DT)
		for k in events.count:
			var kind: int = events.items[k].kind
			counts[kind] = counts.get(kind, 0) + 1
		cmd.reload = false
		cmd.switch_to = -1


func n(kind: GameEvent.Kind) -> int:
	return counts.get(kind, 0)


func test_a_held_auto_trigger_that_runs_dry_clicks_once_and_does_not_reload() -> void:
	a.modes[0] = ReplicaConfig.FireMode.AUTO
	a.ammo[0].mag = 3
	run(120, true)
	assert_eq(n(GameEvent.Kind.SHOT), 3, "three BBs fired")
	assert_eq(n(GameEvent.Kind.DRY_FIRE), 1, "then one dry click for the held pull")
	assert_eq(a.mag(), 0, "ran dry")
	assert_false(a.reloading(), "no reload on running dry under Manual")
	assert_true(a.reload_due())
	run(120, true)
	assert_eq(n(GameEvent.Kind.RELOAD_START), 0)


func test_a_burst_that_runs_dry_midway_ends_without_a_reload() -> void:
	a.modes[0] = ReplicaConfig.FireMode.BURST
	a.ammo[0].mag = 1
	run(1, true)
	run(1, false)
	run(60, true)
	run(60, false)
	assert_eq(a.mag(), 0)
	assert_eq(a.burst_shots_left, 0, "the burst is over")
	assert_false(a.reloading())
	assert_eq(n(GameEvent.Kind.RELOAD_START), 0)


func test_with_no_spare_the_pull_clicks_dry_and_r_is_refused_without_a_prompt() -> void:
	a.ammo[0].mag = 0
	a.ammo[0].pouch.fill(0)
	assert_false(a.reload_due(), "nothing to load: no prompt")
	run(1, true)
	assert_eq(n(GameEvent.Kind.DRY_FIRE), 1)
	cmd.reload = true
	run(1, false)
	assert_eq(n(GameEvent.Kind.RELOAD_REFUSED), 1)
	assert_eq(n(GameEvent.Kind.RELOAD_START), 0)


func test_swapping_to_the_pistol_and_back_never_loads_the_empty_rifle() -> void:
	a.ammo[0].mag = 0
	cmd.switch_to = 1
	run(ceili(a.replicas[1].draw_time / DT) + 5, false)
	assert_eq(a.active, 1)
	assert_false(a.reload_due(), "the pistol is full")
	run(1, true)
	assert_eq(n(GameEvent.Kind.SHOT), 1, "the pistol fires")
	run(1, false)
	cmd.switch_to = 0
	run(ceili(aeg.draw_time / DT) + 5, false)
	assert_eq(a.active, 0)
	assert_true(a.reload_due(), "back on the empty rifle the prompt is due again")
	run(1, true)
	assert_eq(n(GameEvent.Kind.DRY_FIRE), 1)
	assert_eq(n(GameEvent.Kind.RELOAD_START), 0)


func test_r_pressed_during_a_draw_loads_once_it_is_up_and_the_prompt_is_not_due_meanwhile() -> void:
	a.ammo[1].mag = 0
	cmd.switch_to = 1
	run(1, false)
	assert_gt(a.draw_left, 0.0)
	assert_true(a.reload_due(), "drawing, nothing pressed yet")
	cmd.reload = true
	run(1, false)
	assert_false(a.reload_due(), "queued for the end of the draw")
	run(ceili(a.replicas[1].draw_time / DT) + 5, false)
	assert_true(a.reloading() or a.mag() > 0, "the queued reload ran")


func test_the_reload_key_works_while_sprinting_and_a_sprinting_pull_does_not_click() -> void:
	a.ammo[0].mag = 0
	run(5, true, false)
	assert_eq(n(GameEvent.Kind.DRY_FIRE), 0, "cannot fire while sprinting: no dry click either")
	run(1, false, false)
	cmd.reload = true
	run(1, false, false)
	assert_eq(n(GameEvent.Kind.RELOAD_START), 1, "R loads while sprinting")


func test_a_spare_arriving_while_empty_makes_the_prompt_due_but_never_loads_it() -> void:
	a.ammo[0].mag = 0
	a.ammo[0].pouch.fill(0)
	assert_false(a.reload_due())
	a.ammo[0].pouch[0] = aeg.mag_size # what a magazine toss lands as
	assert_true(a.reload_due())
	run(1, true)
	run(1, false)
	assert_false(a.reloading(), "the dry click does not load it")
	assert_true(a.reload_due())


func test_the_setting_holds_through_a_vault() -> void:
	a.modes[0] = ReplicaConfig.FireMode.AUTO
	a.ammo[0].mag = 0
	a.trigger_was_down = true # the trigger was held as the vault began
	var out := PlayerCommand.new()
	var vaulting := Vault.vaulting_command(c, cmd, out)
	assert_true(vaulting.manual_reload, "the vault's own command keeps the setting")
	assert_true(vaulting.fire)
	events.clear()
	Armament.step(c, vaulting, EYE, 1.0, true, pool, rng, events, tuning, DT)
	assert_false(a.reloading(), "a dry click during a vault does not load it under Manual")
	var v := VaultState.new()
	v.held_any = true
	v.held_reload = true
	var after := Vault.with_held_presses(v, cmd, PlayerCommand.new())
	assert_true(after.manual_reload, "the first command after the vault keeps it")
	assert_true(after.reload, "and the R pressed in the vault is played")


func test_automatic_through_a_vault_still_reloads_on_the_click() -> void:
	cmd.manual_reload = false
	a.modes[0] = ReplicaConfig.FireMode.AUTO
	a.ammo[0].mag = 0
	a.trigger_was_down = true
	var vaulting := Vault.vaulting_command(c, cmd, PlayerCommand.new())
	assert_false(vaulting.manual_reload)
	events.clear()
	Armament.step(c, vaulting, EYE, 1.0, true, pool, rng, events, tuning, DT)
	assert_true(a.reloading(), "Automatic: the click loads it")


func test_an_eliminated_player_s_command_is_not_manual_and_does_not_matter() -> void:
	c.status = Character.Status.WALKING_OFF
	var out := PlayerCommand.new()
	out.manual_reload = true
	var filled := Elimination.fill_eliminated_command(c, tuning, out)
	assert_false(filled.fire, "an eliminated character never pulls the trigger")
	assert_false(filled.reload)


# --- the prompt ---

func _hud(you: Character) -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(HudConfig.new(), TeamConfig.new(), ViewConfig.new(), SimTuning.new(), you)
	return hud


func _state() -> GameState:
	var state := GameState.new(1)
	state.characters.append(c)
	return state


func test_the_prompt_hides_between_rounds_and_comes_back_in_the_next() -> void:
	var hud := _hud(c)
	var state := _state()
	hud.manual_reload = true
	a.ammo[0].mag = 0
	hud.update(state, 1.0, DT)
	assert_true(hud.reload_prompt_shown())
	state.round_state.phase = RoundState.Phase.OVER
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "round over")
	state.round_state.phase = RoundState.Phase.LIVE
	hud.update(state, 1.0, DT)
	assert_true(hud.reload_prompt_shown(), "next round, still empty")


func test_the_prompt_hides_while_the_replica_is_holstered_and_after_a_swap_to_a_full_one() -> void:
	var hud := _hud(c)
	var state := _state()
	hud.manual_reload = true
	a.ammo[0].mag = 0
	hud.update(state, 1.0, DT)
	assert_true(hud.reload_prompt_shown())
	a.holstered = true
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "holstered")
	a.holstered = false
	a.active = 1
	hud.update(state, 1.0, DT)
	assert_false(hud.reload_prompt_shown(), "the pistol in hand is full")


func test_a_rebind_while_the_prompt_is_up_shows_on_refresh() -> void:
	var hud := _hud(c)
	var state := _state()
	hud.manual_reload = true
	a.ammo[0].mag = 0
	hud.update(state, 1.0, DT)
	var before := hud.reload_prompt().key_text()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T
	InputMap.action_erase_events(&"reload")
	InputMap.action_add_event(&"reload", key)
	hud.update(state, 1.0, DT)
	assert_eq(hud.reload_prompt().key_text(), before, "unchanged until the resume refreshes it")
	hud.reload_prompt().refresh_key()
	var after := hud.reload_prompt().key_text()
	InputMap.load_from_project_settings()
	assert_ne(after, before, "the resume shows the new key")


func test_the_prompt_ignores_the_mouse_and_leaves_no_orphans() -> void:
	var before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var prompt := HudReloadPrompt.new()
	assert_eq(prompt.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a click through it never misses")
	assert_false(prompt.visible)
	prompt.free()
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), before)


# --- the setting ---

func test_a_corrupt_or_missing_value_loads_manual_and_automatic_survives_a_file() -> void:
	for bad: Variant in [null, "true", 1, 0.0, [], {}]:
		var s := Settings.new()
		s.from_dict({"auto_reload": bad})
		assert_false(s.auto_reload, "%s keeps Manual" % str(bad))
	var path := "user://rl2_qa_settings.json"
	var saved := Settings.new()
	saved.auto_reload = true
	assert_true(saved.save(path))
	var back := Settings.new()
	back.load_file(path)
	assert_true(back.auto_reload, "Automatic round-trips through the file")
	DirAccess.remove_absolute(path)
	var empty := Settings.new()
	empty.load_file("user://rl2_qa_missing.json")
	assert_false(empty.auto_reload, "a missing file is Manual")
