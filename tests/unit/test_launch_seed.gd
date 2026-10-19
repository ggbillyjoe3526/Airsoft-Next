extends GutTest
## The `--seed <n>` launch option (game/debug/launch_seed.gd): a good number is taken, a bad or missing one is ignored.


func test_a_seed_after_the_option_is_taken() -> void:
	assert_eq(LaunchSeed.parse(PackedStringArray(["--seed", "1234"])), 1234)
	assert_eq(LaunchSeed.parse(PackedStringArray(["--smoke", "--seed", "0", "--perf"])), 0)
	assert_eq(LaunchSeed.parse(PackedStringArray(["--seed", str(Seeds.MAX_SEED)])), Seeds.MAX_SEED)


func test_the_equals_form_works_too() -> void:
	assert_eq(LaunchSeed.parse(PackedStringArray(["--seed=77"])), 77)


func test_a_missing_option_is_none() -> void:
	assert_eq(LaunchSeed.parse(PackedStringArray()), LaunchSeed.NONE)
	assert_eq(LaunchSeed.parse(PackedStringArray(["--perf", "5"])), LaunchSeed.NONE, "a number alone isn't a seed")


func test_a_bad_value_is_ignored() -> void:
	for bad: Array in [["--seed"], ["--seed", "abc"], ["--seed", "1.5"], ["--seed", "-3"], ["--seed", ""],
			["--seed=", ], ["--seed=x"], ["--seed", str(Seeds.MAX_SEED + 1)], ["--seed", "--perf"]]:
		assert_eq(LaunchSeed.parse(PackedStringArray(bad)), LaunchSeed.NONE, str(bad))


func test_the_first_seed_counts() -> void:
	assert_eq(LaunchSeed.parse(PackedStringArray(["--seed", "5", "--seed", "9"])), 5)


func test_a_fresh_seed_is_a_valid_match_seed() -> void:
	for i in 20:
		var s := LaunchSeed.fresh()
		assert_between(s, 0, Seeds.MAX_SEED)
