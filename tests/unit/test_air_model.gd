extends GutTest
## The air a BB flies through (game/sim/air_model.gd; the browser game's sim/air.test.ts, M30).


func test_density_and_viscosity_of_real_air() -> void:
	var cfg := BallisticsConfig.new()
	var rho := AirModel.air_density(cfg.air_temperature, cfg.air_pressure)
	var mu := AirModel.air_viscosity(cfg.air_temperature)
	assert_almost_eq(rho, 1.204, 0.0005)
	assert_almost_eq(mu, 1.81e-5, 5e-8)
	# Colder air is denser (and a little less viscous): drag grows on a cold day.
	assert_gt(AirModel.air_density(0.0, cfg.air_pressure), rho)
	assert_lt(AirModel.air_viscosity(0.0), mu)


func test_sphere_drag_follows_the_measured_curve() -> void:
	# Stokes' 24/Re when slow.
	assert_almost_eq(AirModel.sphere_drag_coefficient(0.01) * 0.01, 24.0, 0.5)
	# A 6 mm BB between 10 and 110 m/s flies at Re ~4,000-44,000: the flat part of the curve.
	for re: float in [4000.0, 10000.0, 20000.0, 44000.0]:
		assert_between(AirModel.sphere_drag_coefficient(re), 0.36, 0.48, "Re %s" % re)
	# The drag crisis past Re ~300,000, which a BB never reaches.
	assert_lt(AirModel.sphere_drag_coefficient(600000.0), 0.2)
	assert_eq(AirModel.sphere_drag_coefficient(0.0), 0.0)


func test_drag_table_matches_its_formula_and_is_real_bb_drag() -> void:
	var cfg := BallisticsConfig.new()
	var air := AirModel.of(cfg)
	var rho := AirModel.air_density(cfg.air_temperature, cfg.air_pressure)
	var mu := AirModel.air_viscosity(cfg.air_temperature)
	var d := cfg.bb_diameter
	var area := PI * d * d / 4.0
	for v: float in [5.0, 30.25, 55.5, 88.0, 120.7]:
		var exact := 0.5 * rho * area * AirModel.sphere_drag_coefficient(rho * v * d / mu)
		assert_almost_eq(air.drag_factor(v) / exact, 1.0, 0.0005, "%s m/s" % v)
	# ~7.2e-6 kg/m for a 5.95 mm BB at 88 m/s.
	assert_between(air.drag_factor(88.0), 6.5e-6, 7.5e-6)
	# Off the top of the table it holds the last value rather than reading past the end.
	assert_true(is_finite(air.drag_factor(10000.0)))
	assert_same(AirModel.of(cfg), air, "built once per config")
	assert_ne(AirModel.of(BallisticsConfig.new()), air, "another config has its own")


func test_spin_turns_into_lift_like_a_spinning_ball() -> void:
	var air := AirModel.of(BallisticsConfig.new())
	assert_eq(air.lift_coefficient(0.0), 0.0)
	assert_almost_eq(air.lift_coefficient(0.02) / 0.02, 1.0, 0.05)
	assert_gt(air.lift_coefficient(0.5), air.lift_coefficient(0.2))
	assert_between(air.lift_coefficient(100.0), 0.45, 0.5)


func test_a_colder_day_tabulates_more_drag() -> void:
	var cold := BallisticsConfig.new()
	cold.air_temperature = 0.0
	assert_gt(AirModel.of(cold).drag_factor(88.0), AirModel.of(BallisticsConfig.new()).drag_factor(88.0))
