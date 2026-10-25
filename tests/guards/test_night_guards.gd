extends GutTest
## Neon Heights' night guards (WL10): the map that offers day and night plays at night by default, so its bots are
## guarded there too, at Normal over 16 seeds in Elimination and Attack / Defend (MatchGuard; by day every level stays in
## test_match_guards.gd and test_flag_guards.gd). Woodland, night only, has test_woodland_guards.gd. A CI job of its own
## beside Woodland's, since the day jobs are near their 30 minutes.


func test_neon_heights_matches_play_out_at_night() -> void:
	await MatchGuard.elimination(self, "neonHeights", &"normal", MatchGuard.SEEDS, true)


func test_neon_heights_attack_defend_plays_the_pole_at_night() -> void:
	var t: PackedInt32Array = await MatchGuard.attack_defend(self, "neonHeights", &"normal", MatchGuard.SEEDS, true)
	assert_gt(t[1], 0, "Neon Heights at night: some rounds are won by raising the flag")
