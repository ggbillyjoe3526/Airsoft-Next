extends GutTest
## The Attack / Defend match guards (FG2; the browser game's depotMatch.flag.test.ts and
## depotMatch.neonHeightsFlag.test.ts): whole bot-against-bot Attack / Defend matches over 16 seeds on each field at
## Normal, checking what must never happen on any seed (as test_match_guards.gd does for Elimination: only the attackers
## must leave their spawn, defenders hold by their pole) and that the pole matters: no round runs past the clock and the
## longest overtime, few run out the clock, and flags go up and win rounds. Who wins is the balance report's (BR1).
## Thresholds are the browser's, re-measured over these seeds (docs/records/FG2.md). Run by tools/match_guards.sh, a CI
## job of its own beside the Elimination guards.

const SEEDS := 16
const MAX_MATCH_SECONDS := 30.0 * 60.0
const STALLED_ROUNDS_MAX := 0.25
const HELD_UP_MAX := 10
const BELOW_FLOOR := 0.25
const ABOVE_TOP := 2.0
const LONGEST_AIR := 1.0
## A round never lasts past the clock and the longest overtime by more than a tick or two (s).
const ROUND_SLACK := 0.1
## Depot: rounds won by raising the flag over the 16 seeds, at least this many and this share of all rounds, and matches
## where a flag went all the way up (the browser's 9, 0.07 and 5).
const DEPOT_CAPTURES_MIN := 9
const DEPOT_CAPTURE_SHARE_MIN := 0.07
const DEPOT_FLAGS_RAISED_MIN := 5


## Plays `map_id` over SEEDS seeds; returns [rounds, captures, matches with a flag raised, rounds on time].
func _guard(map_id: String) -> PackedInt32Array:
	var runner := MatchRunner.new(self, map_id)
	runner.mode = RoundState.Mode.ATTACK_DEFEND
	await wait_physics_frames(2)
	assert_eq(runner.map.problems, [] as Array[String], "%s loads" % map_id)
	assert_true(runner.map.has_pole, "%s has a pole" % map_id)
	var longest := runner.tuning.rounds.round_time + runner.tuning.flag.max_overtime + ROUND_SLACK
	var rounds := 0
	var captures := 0
	var raised := 0
	var on_time := 0
	for seed_value in range(1, SEEDS + 1):
		var m := runner.play(seed_value, MAX_MATCH_SECONDS)
		var at := "%s A/D seed %d" % [map_id, seed_value]
		assert_true(m.finished, "%s: the match is won" % at)
		rounds += m.rounds.size()
		captures += m.captures()
		on_time += m.on_time()
		raised += 1 if m.flag_raised() else 0
		for r in m.rounds:
			assert_lte(r.seconds, longest, "%s: no round runs past the clock and its overtime" % at)
		assert_gte(m.min_y, runner.lowest_floor - BELOW_FLOOR, "%s: nobody falls through the floor" % at)
		assert_lte(m.max_y, runner.highest_top + ABOVE_TOP, "%s: nobody flies" % at)
		assert_lte(m.longest_air, LONGEST_AIR, "%s: nobody stays in the air" % at)
		assert_eq(m.stayed_home, 0, "%s: every attacker leaves its spawn each round" % at)
		assert_lte(m.held_up, HELD_UP_MAX, "%s: bots aren't held up on their way" % at)
		assert_eq(m.friendly_hits, 0, "%s: no bot knocks out a teammate" % at)
		assert_eq(m.rescued, 0, "%s: nobody leaves the level" % at)
	gut.p("%s A/D: %d rounds over %d seeds, %d captures, flag raised in %d matches, %d on time" % [map_id, rounds,
			SEEDS, captures, raised, on_time])
	assert_gt(rounds, 0)
	assert_lt(float(on_time) / maxf(rounds, 1.0), STALLED_ROUNDS_MAX, "%s A/D: rounds settle, not stand-offs" % map_id)
	runner.free_level()
	return PackedInt32Array([rounds, captures, raised, on_time])


func test_depot_attack_defend_plays_the_pole() -> void:
	var t: PackedInt32Array = await _guard("depot")
	assert_gte(t[1], DEPOT_CAPTURES_MIN, "Depot: rounds are won by raising the flag")
	assert_gt(float(t[1]) / maxf(t[0], 1.0), DEPOT_CAPTURE_SHARE_MIN, "Depot: the pole matters")
	assert_gte(t[2], DEPOT_FLAGS_RAISED_MIN, "Depot: flags go up")


func test_neon_heights_attack_defend_plays_the_pole() -> void:
	var t: PackedInt32Array = await _guard("neonHeights")
	assert_gt(t[1], 0, "Neon Heights: some rounds are won by raising the flag")
