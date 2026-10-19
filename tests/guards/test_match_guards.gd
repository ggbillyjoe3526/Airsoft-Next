extends GutTest
## The match guards (MG1; the browser game's depotMatch*.test.ts and depotMatchSupport.ts): whole bot-against-bot
## Elimination matches over 16 seeds on each field at Normal, and 8 at Easy and at Hard, checking only what must never
## happen on any seed. Every match is won, few rounds run out the clock, every bot leaves its spawn each round and
## isn't held up on its way, nobody falls through the floor, flies or leaves the level, and no bot knocks out a
## teammate. Who wins is the balance report's (BR1), never asserted here. Thresholds are the browser's, re-measured
## over these seeds (docs/records/MG1.md); re-measure over all 16 before changing one.
## Run by tools/match_guards.sh, a CI job of its own (about ten minutes).

const SEEDS := 16
## Seeds at the other levels: enough to catch a level that stalls or strands its bots.
const LEVEL_SEEDS := 8
## Match time a match may take before it counts as stalled (s).
const MAX_MATCH_SECONDS := 30.0 * 60.0
## Rounds that run out the clock, at most this share of all (the browser's STALLED_ROUNDS_MAX).
const STALLED_ROUNDS_MAX := 0.25
## Every character gets at least this far from its spawn over a match, and every round unless it is hit first (m, the
## browser's; MatchRunner.LEAVES_SPAWN counts the rounds).
const LEAVES_SPAWN := MatchRunner.LEAVES_SPAWN
## Times a bot is held up on its way in one match (MatchRunner.HELD_UP_SECONDS), at most: twice the most measured.
const HELD_UP_MAX := 10
## Feet never below the lowest floor by more than this, nor above the highest block by more (m).
const BELOW_FLOOR := 0.25
const ABOVE_TOP := 2.0
## Longest time off the ground outside a vault (s): a drop off the tallest crate is about 0.7 s.
const LONGEST_AIR := 1.0


func _guard(map_id: String, level: StringName = &"normal", seeds: int = SEEDS) -> void:
	var runner := MatchRunner.new(self, map_id)
	runner.difficulty = level
	await wait_physics_frames(2)
	assert_eq(runner.map.problems, [] as Array[String], "%s loads" % map_id)
	assert_lt(runner.lowest_floor, INF, "%s has a floor to guard" % map_id)
	var rounds := 0
	var on_time := 0
	var ricochets := 0
	for seed_value in range(1, seeds + 1):
		var m := runner.play(seed_value, MAX_MATCH_SECONDS)
		var at := "%s %s seed %d" % [map_id, level, seed_value]
		assert_true(m.finished, "%s: the match is won" % at)
		rounds += m.rounds.size()
		on_time += m.on_time()
		ricochets += m.friendly_ricochets
		for id in m.farthest.size():
			assert_gt(m.farthest[id], LEAVES_SPAWN, "%s: character %d leaves its spawn" % [at, id])
		assert_gte(m.min_y, runner.lowest_floor - BELOW_FLOOR, "%s: nobody falls through the floor" % at)
		assert_lte(m.max_y, runner.highest_top + ABOVE_TOP, "%s: nobody flies" % at)
		assert_lte(m.longest_air, LONGEST_AIR, "%s: nobody stays in the air" % at)
		assert_eq(m.stayed_home, 0, "%s: every bot leaves its spawn each round" % at)
		assert_lte(m.held_up, HELD_UP_MAX, "%s: bots aren't held up on their way" % at)
		assert_eq(m.friendly_hits, 0, "%s: no bot knocks out a teammate" % at)
		assert_eq(m.rescued, 0, "%s: nobody leaves the level" % at)
	gut.p("%s %s: %d rounds over %d seeds, %d on time, %d teammates reached by a bounce" % [map_id, level, rounds,
			seeds, on_time, ricochets])
	assert_gt(rounds, 0)
	assert_lt(float(on_time) / maxf(rounds, 1.0), STALLED_ROUNDS_MAX, "%s %s: rounds settle, not stand-offs"
			% [map_id, level])
	runner.free_level()


func test_depot_matches_play_out_on_every_seed() -> void:
	await _guard("depot")


func test_neon_heights_matches_play_out_on_every_seed() -> void:
	await _guard("neonHeights")


func test_depot_matches_play_out_at_easy_and_hard() -> void:
	for level: StringName in [&"easy", &"hard"]:
		await _guard("depot", level, LEVEL_SEEDS)


func test_neon_heights_matches_play_out_at_easy_and_hard() -> void:
	for level: StringName in [&"easy", &"hard"]:
		await _guard("neonHeights", level, LEVEL_SEEDS)
