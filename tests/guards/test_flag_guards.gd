extends GutTest
## The Attack / Defend match guards (FG2; the browser game's depotMatch.flag.test.ts): whole bot-against-bot Attack /
## Defend matches over 16 seeds on Depot at Normal (Woodland's in test_woodland_guards.gd), checking what must never
## happen on any seed (as test_match_guards.gd does for Elimination: only the attackers must leave their spawn,
## defenders hold by their pole) and that the pole matters: no round runs past the clock and the longest overtime, few
## run out the clock, and flags go up and win rounds. Who wins is the balance report's (BR1). Thresholds are the
## browser's, re-measured over these seeds (docs/records/FG2.md). Run by tools/match_guards.sh, a CI job of its own
## beside the Elimination guards. Elimination's overtime flag is guarded here too (OV2; the browser's
## depotMatch.overtime.test.ts): Depot with rounds cut short so most go to the flag, and the bots take it.

## Depot: rounds won by raising the flag over the 16 seeds, at least this many and this share of all rounds, and matches
## where a flag went all the way up (the browser's 9, 0.07 and 5).
const DEPOT_CAPTURES_MIN := 9
const DEPOT_CAPTURE_SHARE_MIN := 0.07
const DEPOT_FLAGS_RAISED_MIN := 5
## Depot's overtime guard: rounds this long (s, the browser's), at least this many overtimes over the 16 seeds (half the
## 34 measured, docs/records/OV2.md), and of those more than this share taken by a touch (most: 25 measured), and more
## than this many times as many touched as drawn on time (the browser's; none measured).
const OVERTIME_ROUND_TIME := 25.0
const OVERTIMES_MIN := 16
const OVERTIME_TOUCH_SHARE_MIN := 0.5
const OVERTIME_TOUCHED_PER_DRAWN := 3


func test_depot_attack_defend_plays_the_pole() -> void:
	var t: PackedInt32Array = await MatchGuard.attack_defend(self, "depot")
	assert_gte(t[1], DEPOT_CAPTURES_MIN, "Depot: rounds are won by raising the flag")
	assert_gt(float(t[1]) / maxf(t[0], 1.0), DEPOT_CAPTURE_SHARE_MIN, "Depot: the pole matters")
	assert_gte(t[2], DEPOT_FLAGS_RAISED_MIN, "Depot: flags go up")


func test_depot_bots_take_the_overtime_flag() -> void:
	var t: PackedInt32Array = await MatchGuard.overtime_flag(self, "depot", OVERTIME_ROUND_TIME)
	assert_gte(t[1], OVERTIMES_MIN, "Depot: short rounds go to the overtime flag")
	assert_gt(float(t[2]) / maxf(t[1], 1.0), OVERTIME_TOUCH_SHARE_MIN, "Depot: the bots take the flag in most overtimes")
	assert_gt(t[2], OVERTIME_TOUCHED_PER_DRAWN * t[4], "Depot: taken far more often than its time runs out")
	assert_eq(t[2] + t[3] + t[4], t[1], "Depot: every overtime ends by a touch, a wipe-out or its time")
