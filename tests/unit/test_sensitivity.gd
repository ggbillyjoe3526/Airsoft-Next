extends GutTest
## Sensitivity as cm/360 at a DPI (game/input/sensitivity.gd), from the browser game's sensitivity.test.ts.

var rpc: float = ControlsConfig.new().radians_per_count


func test_the_travel_for_a_full_turn_comes_from_the_dpi() -> void:
	# 0.001 rad per count at 1.00: 6283 counts a turn, 7.85 inches at 800 DPI
	assert_almost_eq(Sensitivity.cm_per_360(rpc, 1.0, 800.0), 19.95, 0.01)
	assert_almost_eq(Sensitivity.cm_per_360(rpc, 2.0, 800.0), Sensitivity.cm_per_360(rpc, 1.0, 800.0) / 2.0, 1e-9)
	assert_almost_eq(Sensitivity.cm_per_360(rpc, 1.0, 1600.0), Sensitivity.cm_per_360(rpc, 1.0, 800.0) / 2.0, 1e-9)


func test_a_typed_cm_turns_back_into_the_same_sensitivity() -> void:
	for dpi: float in [400.0, 800.0, 1600.0, 3200.0]:
		for sens: float in [Sensitivity.MIN, 0.73, 1.0, 2.5, Sensitivity.MAX]:
			assert_almost_eq(Sensitivity.for_cm(rpc, Sensitivity.cm_per_360(rpc, sens, dpi), dpi), sens, 1e-9)


func test_a_typed_cm_is_kept_exactly_within_the_range() -> void:
	for dpi: float in [400.0, 800.0, 1600.0]:
		for cm: float in [7.7, 19.95, 33.3, 36.4, 61.0, 99.7]:
			var v := Sensitivity.from_typed_cm(rpc, cm, dpi)
			if v <= Sensitivity.MIN or v >= Sensitivity.MAX:
				continue
			assert_lt(absf(Sensitivity.cm_per_360(rpc, v, dpi) - cm), 0.001, "%s cm at %s DPI" % [cm, dpi])
	assert_eq(Sensitivity.from_typed_cm(rpc, 1.0, 800.0), Sensitivity.MAX, "a very fast turn is held to the range")
	assert_eq(Sensitivity.from_typed_cm(rpc, 500.0, 800.0), Sensitivity.MIN, "a very slow one too")
	assert_true(is_nan(Sensitivity.from_typed_cm(rpc, 0.0, 800.0)), "no figure is not a sensitivity")
	assert_true(is_nan(Sensitivity.from_typed_cm(rpc, 30.0, 0.0)))
	assert_lte(Sensitivity.STEP, 0.01, "fine steps, so 0.20 to 0.21 is not a jump")
