extends GutTest
## Ricochets (game/sim/ricochet.gd and their part in game/sim/bb_step.gd; the browser game's sim/ricochet.test.ts and
## bbs.test.ts M20 cases): a BB bounces off concrete and steel, slower and without its backspin, and stops in wood; a
## bounced BB that reaches someone only ticks them unless the match counts ricochets; it can come back on its shooter.

const DT := 1.0 / 60.0
const KILL_Y := -10.0
const MASS := 0.25e-3


## A wall filling the plane z = wall_z, facing +Z, of `surface`.
class WallAt:
	extends WorldQuery
	var wall_z: float = 0.0
	var surface: RayHit.Surface = RayHit.Surface.CONCRETE

	func _init(z: float, made_of: RayHit.Surface) -> void:
		wall_z = z
		surface = made_of

	func ray(from: Vector3, to: Vector3, hit: RayHit) -> bool:
		if to.z >= from.z:
			return false
		var f := (wall_z - from.z) / (to.z - from.z)
		if f < 0.0 or f > 1.0:
			return false
		hit.fraction = f
		hit.position = from.lerp(to, f)
		hit.normal = Vector3.BACK
		hit.surface = surface
		return true


var tuning: SimTuning
var cfg: RicochetConfig
var events: SimEvents
var ends: Array[MapEnd] = []


func before_each() -> void:
	tuning = SimTuning.new()
	cfg = tuning.ricochet
	events = SimEvents.new()


## A BB at `speed` m/s along (x, 0, z), normalised, with hop.
func flying(x: float, z: float, speed: float = 80.0) -> BB:
	var dir := Vector3(x, 0.0, z).normalized()
	return BBPool.new(1).spawn(0, Vector3(0.0, 1.5, -5.0), dir, speed, 0.12, MASS, tuning.ballistics.spin_per_hop)


func wall_hit(surface: RayHit.Surface) -> RayHit:
	var h := RayHit.new()
	h.normal = Vector3.BACK
	h.surface = surface
	return h


func test_bounces_back_off_concrete_slower_spin_scrubbed_and_lifted_off() -> void:
	var bb := flying(0.0, -1.0)
	assert_true(Ricochet.bounce(bb, wall_hit(RayHit.Surface.CONCRETE), cfg, null))
	assert_almost_eq(bb.velocity.z, 80.0 * cfg.concrete, 1e-4)
	assert_almost_eq(bb.velocity.x, 0.0, 1e-6)
	assert_eq(bb.bounces, 1)
	assert_eq(bb.spin, 0.0)
	assert_gt(bb.position.z, -5.0)


func test_a_grazing_bb_skips_along_the_surface_keeping_most_of_its_speed() -> void:
	var bb := flying(1.0, -0.1)
	assert_true(Ricochet.bounce(bb, wall_hit(RayHit.Surface.CONCRETE), cfg, null))
	assert_gt(bb.velocity.length(), 80.0 * cfg.slide * 0.95)
	assert_gt(bb.velocity.z, 0.0)
	assert_gt(bb.velocity.x, absf(bb.velocity.z) * 5.0)


func test_harder_off_steel_than_concrete_and_not_at_all_off_wood_or_earth() -> void:
	var steel := flying(0.0, -1.0)
	var concrete := flying(0.0, -1.0)
	Ricochet.bounce(steel, wall_hit(RayHit.Surface.METAL), cfg, null)
	Ricochet.bounce(concrete, wall_hit(RayHit.Surface.CONCRETE), cfg, null)
	assert_gt(steel.velocity.z, concrete.velocity.z)
	for soft: RayHit.Surface in [RayHit.Surface.WOOD, RayHit.Surface.EARTH, RayHit.Surface.NONE]:
		var bb := flying(0.0, -1.0)
		assert_false(Ricochet.bounce(bb, wall_hit(soft), cfg, null))
		assert_eq(bb.bounces, 0)


func test_the_owners_g12_numbers_head_on_and_at_45_degrees() -> void:
	# Pinned, not the config's: M20's 0.4 and 0.55 (32 and 44 m/s head-on) fail this.
	var head := flying(0.0, -1.0)
	Ricochet.bounce(head, wall_hit(RayHit.Surface.CONCRETE), cfg, null)
	assert_almost_eq(head.velocity.length(), 24.0, 1e-4)
	var steel := flying(0.0, -1.0)
	Ricochet.bounce(steel, wall_hit(RayHit.Surface.METAL), cfg, null)
	assert_almost_eq(steel.velocity.length(), 32.8, 1e-4)
	var angled := flying(1.0, -1.0)
	assert_true(Ricochet.bounce(angled, wall_hit(RayHit.Surface.CONCRETE), cfg, null))
	assert_almost_eq(angled.velocity.length(), 80.0 * sqrt(0.5 * (0.75 * 0.75 + 0.3 * 0.3)), 1e-3)
	assert_almost_eq(angled.velocity.z, 80.0 * sqrt(0.5) * 0.3, 1e-3)


func test_too_slow_to_leave_or_out_of_bounces_it_stops() -> void:
	# Head-on at 25 m/s: 7.5 m/s back off concrete, under the minimum.
	assert_false(Ricochet.bounce(flying(0.0, -1.0, 25.0), wall_hit(RayHit.Surface.CONCRETE), cfg, null))
	var bb := flying(0.0, -1.0)
	bb.bounces = cfg.max_bounces
	assert_false(Ricochet.bounce(bb, wall_hit(RayHit.Surface.METAL), cfg, null))


func test_scatters_with_the_seeded_stream_never_into_the_surface_at_the_same_speed() -> void:
	var rng := Seeds.stream(5)
	for i in 50:
		var plain := flying(0.3, -1.0)
		var scattered := flying(0.3, -1.0)
		Ricochet.bounce(plain, wall_hit(RayHit.Surface.CONCRETE), cfg, null)
		Ricochet.bounce(scattered, wall_hit(RayHit.Surface.CONCRETE), cfg, rng)
		assert_gt(scattered.velocity.z, 0.0)
		assert_almost_eq(scattered.velocity.length(), plain.velocity.length(), 1e-3)


## Steps `pool` until every BB stops (or 90 ticks), against `wall` and `roster`.
func fly(pool: BBPool, roster: Array[Character], wall: WorldQuery) -> void:
	for i in 90:
		if pool.active_count() == 0:
			return
		events.clear()
		BBStep.step(pool, roster, wall, tuning, KILL_Y, false, ends, events, DT, Vector3.ZERO, Seeds.stream(3))


func test_in_flight_a_bb_bounces_off_concrete_and_flies_on_but_stops_in_wood() -> void:
	var pool := BBPool.new(1)
	var bb := pool.spawn(9, Vector3(0.0, 1.5, 0.0), Vector3.FORWARD, 80.0, 0.0, MASS, 0.0)
	var concrete := WallAt.new(-5.0, RayHit.Surface.CONCRETE)
	events.clear()
	for i in 6:
		BBStep.step(pool, [] as Array[Character], concrete, tuning, KILL_Y, false, ends, events, DT)
	assert_true(bb.active, "still flying after the bounce")
	assert_eq(bb.bounces, 1)
	assert_gt(bb.velocity.z, 0.0, "back the way it came")
	assert_gte(events.count_of(GameEvent.Kind.BB_IMPACT), 1, "the bounce puffs on the wall")
	var wood_pool := BBPool.new(1)
	var stopped := wood_pool.spawn(9, Vector3(0.0, 1.5, 0.0), Vector3.FORWARD, 80.0, 0.0, MASS, 0.0)
	for i in 6:
		BBStep.step(wood_pool, [] as Array[Character], WallAt.new(-5.0, RayHit.Surface.WOOD), tuning, KILL_Y, false, ends,
				events, DT)
	assert_false(stopped.active)
	assert_eq(stopped.bounces, 0)


func test_a_ricochet_only_ticks_someone_unless_the_match_counts_ricochets() -> void:
	for counts: bool in [false, true]:
		tuning.hits.ricochets_count = counts
		# The shooter (9) is off the roster; the target stands behind the muzzle, so only the bounce can reach them.
		var target := Character.new(1, 1, Vector3(0.0, 0.0, 1.0), 0.0)
		var roster: Array[Character] = [target]
		var pool := BBPool.new(1)
		pool.spawn(9, Vector3(0.0, 1.4, -1.0), Vector3.FORWARD, 80.0, 0.0, MASS, 0.0)
		var ticks := 0
		var hits := 0
		for i in 90:
			events.clear()
			BBStep.step(pool, roster, WallAt.new(-5.0, RayHit.Surface.METAL), tuning, KILL_Y, false, ends, events, DT)
			ticks += events.count_of(GameEvent.Kind.RICOCHET_TICK)
			hits += events.count_of(GameEvent.Kind.CHARACTER_HIT)
			if hits > 0:
				assert_eq(events.first(GameEvent.Kind.CHARACTER_HIT).value, 1, "marked a ricochet")
			if pool.active_count() == 0:
				break
		if counts:
			assert_eq(hits, 1, "counted: the bounce knocks them out")
			assert_ne(target.status, Character.Status.ALIVE)
		else:
			assert_eq(ticks, 1, "not counted: a tick")
			assert_eq(hits, 0)
			assert_eq(target.status, Character.Status.ALIVE, "they play on")


func test_a_ricochet_can_come_back_on_its_shooter() -> void:
	tuning.hits.ricochets_count = true
	var shooter := Character.new(1, 0, Vector3.ZERO, 0.0)
	var roster: Array[Character] = [shooter]
	var pool := BBPool.new(1)
	pool.spawn(1, Vector3(0.0, 1.4, -0.5), Vector3.FORWARD, 80.0, 0.0, MASS, 0.0)
	fly(pool, roster, WallAt.new(-4.0, RayHit.Surface.METAL))
	assert_ne(shooter.status, Character.Status.ALIVE, "their own BB came back off the steel")
