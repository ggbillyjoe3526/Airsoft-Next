extends GutTest
## The Attack / Defend match guards (FG2; the browser game's depotMatch.flag.test.ts and
## depotMatch.neonHeightsFlag.test.ts): whole bot-against-bot Attack / Defend matches over 16 seeds on each field at
## Normal, checking what must never happen on any seed (as test_match_guards.gd does for Elimination: only the attackers
## must leave their spawn, defenders hold by their pole) and that the pole matters: no round runs past the clock and the
## longest overtime, few run out the clock, and flags go up and win rounds. Who wins is the balance report's (BR1).
## Thresholds are the browser's, re-measured over these seeds (docs/records/FG2.md). Run by tools/match_guards.sh, a CI
## job of its own beside the Elimination guards.

## Depot: rounds won by raising the flag over the 16 seeds, at least this many and this share of all rounds, and matches
## where a flag went all the way up (the browser's 9, 0.07 and 5).
const DEPOT_CAPTURES_MIN := 9
const DEPOT_CAPTURE_SHARE_MIN := 0.07
const DEPOT_FLAGS_RAISED_MIN := 5


func test_depot_attack_defend_plays_the_pole() -> void:
	var t: PackedInt32Array = await MatchGuard.attack_defend(self, "depot")
	assert_gte(t[1], DEPOT_CAPTURES_MIN, "Depot: rounds are won by raising the flag")
	assert_gt(float(t[1]) / maxf(t[0], 1.0), DEPOT_CAPTURE_SHARE_MIN, "Depot: the pole matters")
	assert_gte(t[2], DEPOT_FLAGS_RAISED_MIN, "Depot: flags go up")


func test_neon_heights_attack_defend_plays_the_pole() -> void:
	var t: PackedInt32Array = await MatchGuard.attack_defend(self, "neonHeights")
	assert_gt(t[1], 0, "Neon Heights: some rounds are won by raising the flag")
