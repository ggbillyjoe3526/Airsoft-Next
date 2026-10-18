extends GutTest
## A BB's flight (game/sim/ballistics.gd; the browser game's sim/ballistics.test.ts, M30). Wind is a later task, so its
## cases here fly in still air. Godot's Vector3 is 32-bit, so positions compare to about 1e-5 m, not the browser's 1e-9.

const DT := 1.0 / 60.0
const MUZZLE_HEIGHT := 1.6
const Replicas := preload("res://tests/unit/replica_fixtures.gd")


## A BB's recorded flight: at each tick, the distance along the ground, the height change from the muzzle (negative is
## a drop), the time and the speed.
class Flight:
	extends RefCounted
	var d: PackedFloat64Array = PackedFloat64Array()
	var y: PackedFloat64Array = PackedFloat64Array()
	var t: PackedFloat64Array = PackedFloat64Array()
	var v: PackedFloat64Array = PackedFloat64Array()

	func at(distance: float) -> int:
		for i in d.size():
			if d[i] >= distance:
				return i
		assert(false, "the BB never reached %s m" % distance)
		return d.size() - 1

	func drop_at(distance: float) -> float:
		return y[at(distance)]

	func time_to(distance: float) -> float:
		return t[at(distance)]

	func speed_at(distance: float) -> float:
		return v[at(distance)]


var tuning: SimTuning = SimTuning.new()


## Fires level along -Z from the muzzle height and records the flight until the BB reaches the ground.
func fly(speed: float, hop_up: float, mass: float) -> Flight:
	var bb := BBPool.new(1).spawn(0, Vector3(0.0, MUZZLE_HEIGHT, 0.0), Vector3.FORWARD, speed, hop_up, mass,
			tuning.ballistics.spin_per_hop)
	var f := Flight.new()
	var t := 0.0
	while bb.position.y > 0.0 and t < 5.0:
		Ballistics.step_bb_flight(bb, tuning.ballistics, DT)
		t += DT
		f.d.append(-bb.position.z)
		f.y.append(bb.position.y - MUZZLE_HEIGHT)
		f.t.append(t)
		f.v.append(bb.velocity.length())
	return f


## `r` with its factory hop-up shooting `grams` BBs (its own weight by default).
func shoot(r: ReplicaConfig, grams: float = -1.0) -> Flight:
	var rules := tuning.replica_rules
	return fly(Ballistics.muzzle_velocity(r, rules, grams), Ballistics.hop_up_lift(r, r.hop_up_dial, rules),
			Ballistics.bb_mass(r, grams))


## The rifle's BB fired along `dir` from the muzzle height, stepped `steps` times a tick, flown on until `distance` m
## along the ground, in `wind`: where it is then (interpolated) and when (w).
func rifle_to(distance: float, dir: Vector3 = Vector3.FORWARD, steps: int = 1, wind: Vector3 = Vector3.ZERO) -> Vector4:
	var r := Replicas.aeg()
	var rules := tuning.replica_rules
	var bb := BBPool.new(1).spawn(0, Vector3(0.0, MUZZLE_HEIGHT, 0.0), dir, Ballistics.muzzle_velocity(r, rules),
			Ballistics.hop_up_lift(r, r.hop_up_dial, rules), Ballistics.bb_mass(r), tuning.ballistics.spin_per_hop)
	var air := AirModel.of(tuning.ballistics)
	var last := Vector4(bb.position.x, bb.position.y, bb.position.z, bb.age)
	while bb.age <= tuning.ballistics.max_lifetime:
		for i in steps:
			Ballistics.step_flight(bb, air, DT / steps, wind)
		var reached := Vector2(bb.position.x, bb.position.z).length()
		if reached >= distance:
			var before := Vector2(last.x, last.z).length()
			return last.lerp(Vector4(bb.position.x, bb.position.y, bb.position.z, bb.age),
					(distance - before) / (reached - before))
		last = Vector4(bb.position.x, bb.position.y, bb.position.z, bb.age)
	assert(false, "never reached %s m" % distance)
	return last


func test_joules_and_bb_weight_give_the_muzzle_velocity() -> void:
	var rules := tuning.replica_rules
	var r := Replicas.aeg()
	var v := Ballistics.muzzle_velocity(r, rules)
	assert_almost_eq(0.5 * Ballistics.bb_mass(r) * v * v, r.muzzle_energy, 1e-9, "E = ½mv²")
	assert_almost_eq(Ballistics.bb_mass(Replicas.pistol()), 0.0002, 1e-12)
	assert_between(v, 85.0, 92.0, "~1 J on 0.25 g: a typical site-legal AEG")
	assert_lt(Ballistics.muzzle_velocity(Replicas.pistol(), rules), v)


func test_flies_flat_with_hop_up_to_34_m_then_drops() -> void:
	var f := shoot(Replicas.aeg())
	for d: float in [10.0, 20.0, 25.0, 30.0, 34.0]:
		assert_lt(absf(f.drop_at(d)), 0.15, "%s m" % d)
	assert_gt(f.drop_at(20.0), 0.03, "a gentle rise")
	assert_lt(f.drop_at(45.0), -0.5, "then falling away")


func test_hop_up_makes_a_big_difference() -> void:
	var r := Replicas.aeg()
	var hopped := shoot(r)
	var none := fly(Ballistics.muzzle_velocity(r, tuning.replica_rules), 0.0, Ballistics.bb_mass(r))
	assert_lt(none.drop_at(30.0), hopped.drop_at(30.0) - 0.6)
	assert_lt(none.drop_at(30.0), -0.6)


func test_the_pistol_reaches_less_far_than_the_rifle() -> void:
	var rifle := shoot(Replicas.aeg())
	var sidearm := shoot(Replicas.pistol())
	assert_lt(sidearm.drop_at(30.0), rifle.drop_at(30.0) - 0.3)
	assert_lt(absf(sidearm.drop_at(15.0)), 0.1)


func test_visible_travel_time() -> void:
	var rifle := shoot(Replicas.aeg())
	assert_between(rifle.time_to(30.0), 0.48, 0.56, "about half a second to 30 m")
	assert_gt(shoot(Replicas.pistol()).time_to(20.0), rifle.time_to(20.0))


func test_only_slows_down_in_level_flight() -> void:
	var f := shoot(Replicas.aeg())
	for i in range(1, mini(f.v.size(), 30)):
		assert_lt(f.v[i], f.v[i - 1], "tick %d" % i)


func test_bb_weight_matters() -> void:
	var r := Replicas.aeg()
	var factory := shoot(r)
	var light := shoot(r, 0.2)
	var heavy := shoot(r, 0.28)
	# Same replica (same joules): the lighter BB is faster out of the barrel...
	assert_gt(light.v[0], factory.v[0])
	assert_lt(heavy.v[0], factory.v[0])
	# ...but loses a bigger share of its speed to drag by 30 m...
	assert_lt(light.speed_at(30.0) / light.v[0], factory.speed_at(30.0) / factory.v[0])
	assert_gt(heavy.speed_at(30.0) / heavy.v[0], factory.speed_at(30.0) / factory.v[0])
	# ...and a hop set for 0.25 g lifts a 0.20 g BB above the aim line, while a 0.28 g one sags sooner.
	assert_gt(light.drop_at(20.0), 0.02)
	assert_lt(heavy.drop_at(25.0), factory.drop_at(25.0))


func test_is_deterministic() -> void:
	assert_eq(shoot(Replicas.aeg()).drop_at(37.0), shoot(Replicas.aeg()).drop_at(37.0))


func test_slows_as_real_air_does() -> void:
	var f := shoot(Replicas.aeg())
	assert_between(f.speed_at(30.0) / f.v[0], 0.38, 0.5, "under half its speed by 30 m")


func test_one_step_a_tick_is_within_a_centimetre_of_a_fine_flight_at_50_m() -> void:
	var tick := rifle_to(50.0)
	var fine := rifle_to(50.0, Vector3.FORWARD, 100)
	assert_lt(absf(tick.y - fine.y), 0.01)
	assert_lt(absf(tick.x - fine.x), 0.01)
	assert_lt(absf(tick.w - fine.w), 0.005)


func test_one_step_a_tick_is_as_accurate_in_a_breeze() -> void:
	var wind := Vector3(1.5, 0.0, 0.5)
	var tick := rifle_to(50.0, Vector3.FORWARD, 1, wind)
	var fine := rifle_to(50.0, Vector3.FORWARD, 100, wind)
	assert_gt(absf(tick.x), 0.05, "the breeze moved it")
	assert_lt(absf(tick.y - fine.y), 0.01)
	assert_lt(absf(tick.x - fine.x), 0.01)
	assert_lt(absf(tick.w - fine.w), 0.005)


func test_lifts_the_same_whichever_way_it_is_fired() -> void:
	var north := rifle_to(30.0)
	var diagonal := rifle_to(30.0, Vector3(1.0, 0.0, 1.0).normalized())
	assert_almost_eq(diagonal.y, north.y, 1e-4)
	assert_eq(north.x, 0.0, "no sideways curl in still air")
	assert_almost_eq(diagonal.x, diagonal.z, 1e-4)


func test_spin_axis_is_level_and_square_to_the_barrel() -> void:
	var up := Vector3(0.0, sin(0.3), -cos(0.3))
	var bb := BBPool.new(1).spawn(0, Vector3.ZERO, up, 80.0, 0.2, 0.25e-3, tuning.ballistics.spin_per_hop)
	assert_eq(bb.spin_axis.y, 0.0)
	assert_almost_eq(bb.spin_axis.x * up.x + bb.spin_axis.z * up.z, 0.0, 1e-7)
	assert_almost_eq(bb.spin_axis.length(), 1.0, 1e-6)
	var straight_up := BBPool.new(1).spawn(0, Vector3.ZERO, Vector3.UP, 80.0, 0.2, 0.25e-3, tuning.ballistics.spin_per_hop)
	assert_almost_eq(straight_up.spin_axis.length(), 1.0, 1e-6)


func test_backspin_decays_faster_on_a_lighter_bb() -> void:
	assert_between(_spin_left_after_half_a_second(0.25), 0.4, 0.9)
	assert_lt(_spin_left_after_half_a_second(0.2), _spin_left_after_half_a_second(0.28))


func test_flight_time_estimate_is_within_5_percent_of_the_full_flight() -> void:
	for r: ReplicaConfig in [Replicas.aeg(), Replicas.pistol()]:
		var v := Ballistics.muzzle_velocity(r, tuning.replica_rules)
		for d: float in [10.0, 20.0, 30.0]:
			var exact := Ballistics.flight_time(r, r.hop_up_dial, d, tuning, DT)
			var estimate := Ballistics.flight_time_estimate(d, v, Ballistics.bb_mass(r), tuning.ballistics)
			assert_lt(absf(estimate / exact - 1.0), 0.05, "%s %s m" % [r.id, d])
		assert_gt(Ballistics.flight_time_estimate(30.0, v, Ballistics.bb_mass(r), tuning.ballistics), 30.0 / v * 1.3)
	assert_eq(Ballistics.flight_time_estimate(10.0, 0.0, 0.25e-3, tuning.ballistics), INF)


func test_flight_time_is_inf_out_of_reach() -> void:
	assert_eq(Ballistics.flight_time(Replicas.aeg(), 0.65, 1000.0, tuning, DT), INF)


func test_every_replica_flies() -> void:
	for r: ReplicaConfig in [Replicas.aeg(), Replicas.pistol()]:
		assert_gt(Ballistics.hop_up_lift(r, r.hop_up_dial, tuning.replica_rules), 0.0, r.id)
		assert_true(r.hop_up_dial <= 1.0, r.id)
		assert_true(is_finite(Ballistics.muzzle_velocity(r, tuning.replica_rules)), r.id)


func test_the_pool_refuses_a_bb_without_a_mass() -> void:
	assert_null(BBPool.new(1).spawn(0, Vector3.ZERO, Vector3.FORWARD, 80.0, 0.1, 0.0, tuning.ballistics.spin_per_hop))
	assert_push_error("mass must be positive")


func _spin_left_after_half_a_second(grams: float) -> float:
	var r := Replicas.aeg()
	var rules := tuning.replica_rules
	var bb := BBPool.new(1).spawn(0, Vector3.ZERO, Vector3.FORWARD, Ballistics.muzzle_velocity(r, rules, grams),
			Ballistics.hop_up_lift(r, r.hop_up_dial, rules), Ballistics.bb_mass(r, grams), tuning.ballistics.spin_per_hop)
	var start := bb.spin
	for i in 30:
		Ballistics.step_bb_flight(bb, tuning.ballistics, DT)
	return bb.spin / start
