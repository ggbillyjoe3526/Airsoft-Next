extends GutTest
## The match's breeze (game/sim/wind.gd, its part in game/sim/ballistics.gd; the browser game's sim/wind.test.ts and
## the wind cases of ballistics.test.ts and bbs.test.ts, M30): drawn from the match's seed, level, between calm and a
## light breeze, gusting smoothly; it drifts BBs downwind, more the further they fly.

const DT := 1.0 / 60.0

var cfg: WindConfig
var tuning: SimTuning


func before_each() -> void:
	tuning = SimTuning.new()
	cfg = tuning.wind


func drawn(seed_value: int) -> Wind:
	var w := Wind.new()
	w.draw(seed_value, cfg)
	return w


func test_the_same_seed_gives_the_same_wind_and_matches_differ() -> void:
	var a := drawn(7)
	var b := drawn(7)
	assert_eq(a.speed, b.speed)
	assert_eq(a.yaw, b.yaw)
	assert_eq(a.phases, b.phases)
	var speeds := {}
	for i in 20:
		speeds[snappedf(drawn(i + 1).speed, 0.001)] = true
	assert_gt(speeds.size(), 15)


func test_level_from_any_direction_between_calm_and_a_light_breeze_gusting_round_its_mean() -> void:
	var quarters := {}
	for seed_value in range(1, 65):
		var w := drawn(seed_value)
		assert_between(w.speed, cfg.min_speed, cfg.max_speed)
		quarters[floori(w.yaw / TAU * 4.0)] = true
		var sum := 0.0
		var most := 0.0
		var least := INF
		var level := true
		for i in 1000:
			var v := w.at(i * 0.5)
			level = level and v.y == 0.0
			var s := Vector2(v.x, v.z).length()
			most = maxf(most, s)
			least = minf(least, s)
			sum += s
		assert_true(level)
		assert_lte(most, w.speed * (1.0 + cfg.gust) + 1e-6)
		assert_gte(least, w.speed * (1.0 - cfg.gust) - 1e-6)
		assert_almost_eq(sum / 1000.0 / w.speed, 1.0, 0.05, "the gusts average out")
	assert_eq(quarters.size(), 4, "every quarter of the compass")


func test_changes_smoothly_from_tick_to_tick() -> void:
	var w := drawn(3)
	assert_lt((w.at(10.0 + DT) - w.at(10.0)).length(), 0.01)


func test_blows_towards_its_yaw_the_way_a_character_faces() -> void:
	var w := drawn(1)
	w.yaw = 0.0
	cfg.gust = 0.0
	cfg.veer = 0.0
	var v := w.at(5.0)
	assert_almost_eq(v.z, -w.speed, 1e-6) # Vector3 holds 32-bit floats
	assert_almost_eq(v.x, 0.0, 1e-6)


func test_salted_not_the_simulations_own_first_draws() -> void:
	for seed_value in range(1, 21):
		var stream := Seeds.stream(seed_value)
		var first := stream.randf()
		var w := drawn(seed_value)
		assert_ne(snappedf(w.speed, 1e-6), snappedf(lerpf(cfg.min_speed, cfg.max_speed, first), 1e-6))


func test_still_air_before_a_match_and_a_new_breeze_each_rematch() -> void:
	var state := GameState.new(42, tuning)
	assert_eq(state.wind.at(3.0), Vector3.ZERO)
	var first := Seeds.wind_seed(42, 1)
	var second := Seeds.wind_seed(42, 2)
	assert_ne(first, second)
	assert_ne(drawn(first).speed, drawn(second).speed)


## Flies a level, unhopped `grams` BB from the origin along -Z at 90 m/s in `wind` for `distance` m; returns where it is.
func fly_to(distance: float, wind: Vector3, grams: float = 0.25) -> Vector3:
	var bb := BBPool.new(1).spawn(0, Vector3.ZERO, Vector3.FORWARD, 90.0, 0.0, grams * 1e-3, 0.0)
	var air := AirModel.of(tuning.ballistics)
	while -bb.position.z < distance and bb.age < 3.0:
		Ballistics.step_flight(bb, air, DT, wind)
	return bb.position


func test_a_crosswind_drifts_a_bb_downwind_more_and_more_with_distance() -> void:
	var cross := Vector3(1.5, 0.0, 0.0)
	var near := fly_to(10.0, cross).x
	var far := fly_to(40.0, cross).x
	assert_gt(near, 0.0)
	assert_gt(far, near * 4.0, "drift grows faster than distance")
	assert_lt(far, 1.0, "a light breeze nudges, never blows a BB away at 40 m")
	assert_almost_eq(fly_to(40.0, -cross).x, -far, 1e-6, "mirrored by the opposite wind")
	assert_almost_eq(fly_to(40.0, Vector3.ZERO).x, 0.0, 1e-9, "still air leaves it on its line")


func test_a_lighter_bb_drifts_more() -> void:
	var cross := Vector3(1.5, 0.0, 0.0)
	assert_gt(fly_to(30.0, cross, 0.20).x, fly_to(30.0, cross, 0.28).x * 1.1)


func test_a_tailwind_carries_it_further_than_a_headwind() -> void:
	var tail := BBPool.new(1).spawn(0, Vector3.ZERO, Vector3.FORWARD, 90.0, 0.0, 0.25e-3, 0.0)
	var head := BBPool.new(1).spawn(0, Vector3.ZERO, Vector3.FORWARD, 90.0, 0.0, 0.25e-3, 0.0)
	var air := AirModel.of(tuning.ballistics)
	for i in 60:
		Ballistics.step_flight(tail, air, DT, Vector3(0.0, 0.0, -1.5))
		Ballistics.step_flight(head, air, DT, Vector3(0.0, 0.0, 1.5))
	assert_lt(tail.position.z, head.position.z)
