extends GutTest
## Woodland's match guards (WL10; the browser game's ai/woodlandNightMatch.test.ts): whole bot-against-bot matches at
## 5v5 at night, the size and time it plays, in Elimination and Attack / Defend, over 16 seeds at Normal and 8 at Easy,
## Hard and Pro, checking what must never happen on any seed (MatchGuard, as for Depot and Neon Heights): rounds settle,
## nobody is stuck or held up, falls through the ground, flies or leaves the level, and no bot knocks out a teammate. Who
## wins is the balance report's (BR1). A match there takes 50 to 70 s headless, so the tests run as five CI jobs of 16
## matches each (tools/match_guards.sh test_woodland_guards <part of a name>: elimination_at_normal,
## elimination_at_easy, attack_defend_at_normal, attack_defend_at_easy and at_pro).


func test_woodland_elimination_at_normal() -> void:
	await MatchGuard.elimination(self, "woodland")


func test_woodland_elimination_at_easy_and_hard() -> void:
	for level: StringName in [&"easy", &"hard"]:
		await MatchGuard.elimination(self, "woodland", level, MatchGuard.LEVEL_SEEDS)


func test_woodland_elimination_at_pro() -> void:
	await MatchGuard.elimination(self, "woodland", &"pro", MatchGuard.LEVEL_SEEDS)


func test_woodland_attack_defend_at_normal() -> void:
	var t: PackedInt32Array = await MatchGuard.attack_defend(self, "woodland")
	assert_gt(t[1], 0, "Woodland: some rounds are won by raising the flag")


func test_woodland_attack_defend_at_easy_and_hard() -> void:
	for level: StringName in [&"easy", &"hard"]:
		await MatchGuard.attack_defend(self, "woodland", level, MatchGuard.LEVEL_SEEDS)


func test_woodland_attack_defend_at_pro() -> void:
	await MatchGuard.attack_defend(self, "woodland", &"pro", MatchGuard.LEVEL_SEEDS)
