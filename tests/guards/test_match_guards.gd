extends GutTest
## The match guards (MG1; the browser game's depotMatch*.test.ts and depotMatchSupport.ts): whole bot-against-bot
## Elimination matches over 16 seeds on each field at Normal, and 8 at Easy, Hard and Pro, checking only what must never
## happen on any seed. Every match is won, few rounds run out the clock, every bot leaves its spawn each round and
## isn't held up on its way, nobody falls through the floor, flies or leaves the level, and no bot knocks out a
## teammate; on Depot, bot teammates told to follow a leader keep up with it (Follow me). Who wins is the balance
## report's (BR1), never asserted here. Thresholds are the browser's, re-measured over these seeds
## (docs/records/MG1.md); re-measure over all 16 before changing one.
## Run by tools/match_guards.sh, a CI job of its own (about ten minutes).

## Follow me on Depot (the browser's depotMatch.test.ts, M22): seeds 1 to FOLLOW_SEEDS of FOLLOW_SECONDS each, a leader
## bot giving it at each round start. Each seed judges more than FOLLOW_TICKS ticks, with more than FOLLOW_NEAR of them
## near the leader (MatchRunner.FOLLOW_NEAR_SLACK) and the farthest under catch_up, a follower sprinting for the leader
## beyond it counting as chasing, not left behind (MatchRunner.CHASE_PACE; lead ruling, DP4); standing still
## while the leader moves, under FOLLOW_STANDING of the ticks over all four (one seed's share swings with a single long
## wait).
const FOLLOW_SEEDS := 4
const FOLLOW_SECONDS := 90.0
const FOLLOW_TICKS := 1000
const FOLLOW_NEAR := 0.95
const FOLLOW_STANDING := 0.03


func test_depot_matches_play_out_on_every_seed() -> void:
	await MatchGuard.elimination(self, "depot")


func test_neon_heights_matches_play_out_on_every_seed() -> void:
	await MatchGuard.elimination(self, "neonHeights")


func test_depot_matches_play_out_at_easy_hard_and_pro() -> void:
	for level: StringName in [&"easy", &"hard", &"pro"]:
		await MatchGuard.elimination(self, "depot", level, MatchGuard.LEVEL_SEEDS)


func test_neon_heights_matches_play_out_at_easy_hard_and_pro() -> void:
	for level: StringName in [&"easy", &"hard", &"pro"]:
		await MatchGuard.elimination(self, "neonHeights", level, MatchGuard.LEVEL_SEEDS)


func test_bot_teammates_follow_a_leader_round_depot_without_being_left_behind() -> void:
	var runner := MatchRunner.new(self, "depot")
	runner.follow_leader = 0
	await wait_physics_frames(2)
	var catch_up := runner.config.squad.catch_up
	var counted := 0
	var standing := 0
	for seed_value in range(1, FOLLOW_SEEDS + 1):
		var m := runner.play(seed_value, FOLLOW_SECONDS)
		var at := "depot follow seed %d" % seed_value
		var near := float(m.follow_near) / maxf(m.follow_counted, 1.0)
		gut.p("%s: %d ticks judged, %.1f %% near, worst %.2f m, standing %.1f %%, chasing %d ticks" % [at,
				m.follow_counted, near * 100.0, m.follow_worst, 100.0 * m.follow_standing / maxf(m.follow_counted, 1.0),
				m.follow_chasing])
		assert_gt(m.follow_counted, FOLLOW_TICKS, "%s: enough ticks judged" % at)
		assert_gt(near, FOLLOW_NEAR, "%s: followers keep near the leader" % at)
		assert_lt(m.follow_worst, catch_up, "%s: never left behind" % at)
		counted += m.follow_counted
		standing += m.follow_standing
	var still := float(standing) / maxf(counted, 1.0)
	gut.p("depot follow: standing still %.2f %% of %d ticks" % [still * 100.0, counted])
	assert_lt(still, FOLLOW_STANDING, "followers rarely stand while the leader moves")
	runner.free_level()
