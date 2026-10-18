extends GutTest
## Turning the hop-up dial in play (game/sim/armament.gd; the browser game's sim/hopUpTurn.test.ts and hopUpKept.test.ts,
## HD1): a notch a press on the replica in hand, on the dial's steps and within its range, said in a HOP_UP event,
## used by the next BB, kept through rounds and back to the replica's setting for a new match.

const DT := 1.0 / 60.0
const EYE := Vector3(0.0, 1.6, 0.0)

var tuning: SimTuning
var rules: ReplicaRulesConfig
var c: Character
var a: Armament
var cmd: PlayerCommand
var pool: BBPool
var events: SimEvents


func before_each() -> void:
	tuning = SimTuning.new()
	rules = tuning.replica_rules
	c = Character.new(1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	a = c.armament
	cmd = PlayerCommand.new()
	pool = BBPool.new(16)
	events = SimEvents.new()


func turn(steps: int) -> GameEvent:
	cmd.hop_up_steps = steps
	events.clear()
	Armament.step(c, cmd, EYE, 1.0, true, pool, Seeds.stream(1), events, tuning, DT)
	cmd.hop_up_steps = 0
	return events.first(GameEvent.Kind.HOP_UP)


func test_no_notch_asked_leaves_the_dial_alone() -> void:
	var before := a.hop_ups.duplicate()
	assert_null(turn(0))
	assert_eq(a.hop_ups, before)


func test_a_notch_a_step_up_or_down_on_the_replica_in_hand_and_says_so() -> void:
	var start := a.hop_ups[0]
	var e := turn(1)
	assert_almost_eq(a.hop_ups[0], start + rules.hop_up_dial_step, 1e-9)
	assert_eq(e.value, roundi(a.hop_ups[0] * 100.0))
	assert_eq(e.value2, 1)
	assert_eq(e.slot, 0)
	turn(-2)
	assert_almost_eq(a.hop_ups[0], start - rules.hop_up_dial_step, 1e-9)
	assert_eq(a.hop_ups[1], a.replicas[1].hop_up_dial, "the other replica's dial didn't move")


func test_stays_on_the_steps_and_in_range_and_says_when_it_didnt_move() -> void:
	a.hop_ups[0] = 0.333
	turn(1)
	var notches := a.hop_ups[0] / rules.hop_up_dial_step
	assert_almost_eq(notches, roundf(notches), 1e-6, "back on a step")
	turn(100)
	assert_eq(a.hop_ups[0], rules.hop_up_max_dial)
	var e := turn(1)
	assert_eq(e.value2, 0, "already at the top")
	turn(-100)
	assert_eq(a.hop_ups[0], rules.hop_up_min_dial)


func test_the_next_bb_flies_with_the_new_dial() -> void:
	turn(-100)
	cmd.fire = true
	events.clear()
	Armament.step(c, cmd, EYE, 1.0, true, pool, Seeds.stream(1), events, tuning, DT)
	var none: BB = null
	for bb in pool.bbs:
		if bb.active:
			none = bb
	assert_not_null(none)
	assert_eq(none.spin, 0.0, "a dial at zero gives no backspin")


func test_turns_in_a_reload_without_cancelling_it() -> void:
	a.ammo[0].mag = 0
	cmd.reload = true
	Armament.step(c, cmd, EYE, 1.0, true, pool, Seeds.stream(1), events, tuning, DT)
	cmd.reload = false
	assert_true(a.reloading(), "the swap started")
	var start := a.hop_ups[0]
	turn(1)
	assert_almost_eq(a.hop_ups[0], start + rules.hop_up_dial_step, 1e-6)
	assert_true(a.reloading(), "turning the dial doesn't cancel the reload")


func test_kept_through_a_new_round_and_reset_for_a_new_match() -> void:
	turn(3)
	var turned := a.hop_ups[0]
	a.refill()
	assert_eq(a.hop_ups[0], turned, "a new round keeps it")
	a.reset_hop_ups()
	assert_eq(a.hop_ups[0], a.replicas[0].hop_up_dial, "a new match is back to the replica's setting")
