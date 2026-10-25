extends GutTest
## QA's hunt on WL5 (bushes): what the first tests leave open. A BB that stops in leaves hits no one behind its stop,
## someone standing in a bush is still hit by a BB that reaches them, a BB fired from inside one stops 0.6 m on, a
## reused pool BB forgets its leaves, and the leaves' random turn is drawn only where a BB flies on.

const DT := 1.0 / 60.0
const KILL_Y := -10.0
const MASS := 0.25e-3
const SPEED := 90.0

var tuning: SimTuning = SimTuning.new()
var events: SimEvents = SimEvents.new()
var ends: Array[MapEnd] = []


func before_each() -> void:
	tuning = SimTuning.new()
	events = SimEvents.new()


## A bush (radius 1, 2 m tall) at z = -10, and a standing enemy of the shooter `body_z` m along -Z; one BB fired from
## `origin` along -Z until it stops (60 ticks at most). Returns the last tick's events kinds seen, by kind.
func _shoot(bushy: bool, body_z: float, origin: Vector3, rng: RandomNumberGenerator = null) -> Dictionary:
	var world := BoxWorld.new()
	if bushy:
		world.add_bush(Vector3(0.0, 0.0, -10.0), 1.0, 2.0)
	var roster: Array[Character] = [Character.new(1, 0, Vector3(0.0, 0.0, 5.0), 0.0),
			Character.new(2, 1, Vector3(0.0, 0.0, body_z), 0.0)]
	var pool := BBPool.new(4)
	var bb := pool.spawn(1, origin, Vector3.FORWARD, SPEED, 0.0, MASS, tuning.ballistics.spin_per_hop)
	var seen := {}
	for t in 60:
		events.clear()
		BBStep.step(pool, roster, world, tuning, KILL_Y, false, ends, events, DT, Vector3.ZERO, rng)
		for i in events.count:
			var e := events.items[i]
			seen[e.kind] = int(seen.get(e.kind, 0)) + 1
			if e.kind == GameEvent.Kind.BB_IMPACT:
				seen["value"] = e.value
		if not bb.active:
			break
	seen["bb"] = bb
	seen["foe_out"] = not Elimination.is_in_play(roster[1])
	return seen


func test_a_bb_stopped_in_leaves_hits_no_one_standing_behind_its_stop_in_the_same_tick() -> void:
	# Muzzles every 0.25 m along a tick's 1.5 m, so the stop falls early, late and mid tick among them.
	for k in 6:
		var origin := Vector3(0.0, 1.0, -0.25 * k)
		var open := _shoot(false, -9.9, origin)
		assert_true(open.foe_out, "control: without the bush the BB reaches the body (muzzle %d)" % k)
		var leafy := _shoot(true, -9.9, origin)
		assert_false(leafy.foe_out, "the leaves stopped it 0.6 m in, before the body (muzzle %d)" % k)
		assert_false(leafy.has(GameEvent.Kind.CHARACTER_HIT), "no hit (muzzle %d)" % k)
		assert_eq(leafy.value, BBStep.IN_LEAVES, "a stop in the leaves (muzzle %d)" % k)


func test_someone_standing_in_a_bush_is_hit_by_a_bb_that_reaches_them_within_the_leaves() -> void:
	var leafy := _shoot(true, -9.3, Vector3(0.0, 1.0, 0.0))
	assert_true(leafy.foe_out, "a body only just inside the bush is hit")
	assert_false(leafy.has(GameEvent.Kind.BB_LEAVES), "and the BB does not fly on")


func test_a_bb_fired_from_inside_a_bush_stops_0_6_m_from_where_it_started() -> void:
	var seen := _shoot(true, 40.0, Vector3(0.0, 1.0, -9.5))
	var bb: BB = seen.bb
	assert_false(bb.active)
	assert_almost_eq(bb.position.z, -9.5 - 0.6, 5e-3)
	assert_eq(seen.value, BBStep.IN_LEAVES)


func test_a_pool_bb_that_is_reused_starts_with_no_leaves_crossed() -> void:
	var pool := BBPool.new(1)
	var bb := pool.spawn(1, Vector3.ZERO, Vector3.FORWARD, SPEED, 0.0, MASS, 0.0)
	bb.leaf = 0.5
	bb.active = false
	var again := pool.spawn(1, Vector3.ZERO, Vector3.FORWARD, SPEED, 0.0, MASS, 0.0)
	assert_eq(again.leaf, 0.0)
	# A full pool reuses its oldest BB too.
	again.leaf = 0.4
	var third := pool.spawn(2, Vector3.ZERO, Vector3.FORWARD, SPEED, 0.0, MASS, 0.0)
	assert_eq(third.leaf, 0.0)


func test_a_bb_thrown_off_its_line_by_an_edge_draws_its_turn_from_the_match_stream() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var before := rng.state
	var world := BoxWorld.new()
	world.add_bush(Vector3(0.24, 0.0, -10.0), 0.3, 2.0)
	var pool := BBPool.new(2)
	pool.spawn(1, Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, SPEED, 0.0, MASS, 0.0)
	for t in 20:
		BBStep.step(pool, [] as Array[Character], world, tuning, KILL_Y, false, ends, events, DT, Vector3.ZERO, rng)
	assert_ne(rng.state, before, "a BB thrown off its line draws its turn from the match's stream")


func test_a_bush_free_world_leaves_the_stream_alone() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var before := rng.state
	_shoot(false, 40.0, Vector3(0.0, 1.0, 0.0), rng)
	assert_eq(rng.state, before)


func test_the_leaves_event_is_appended_after_every_older_kind() -> void:
	assert_eq(GameEvent.Kind.BB_LEAVES, GameEvent.Kind.PROP_RING + 1, "no older id shifts")
	assert_eq(GameEvent.Kind.TORCH, GameEvent.Kind.BB_LEAVES + 1, "and the next kind (WL7's) comes after it")


func test_a_foliage_entry_that_is_not_a_list_is_ignored_with_a_warning() -> void:
	for raw: Variant in ["bushes", {"x": 1}, 7]:
		var text := JSON.stringify({"blocks": [{"kind": "floor", "x": 0, "y": -0.5, "z": 0, "w": 20, "h": 1, "d": 20}],
				"foliage": raw})
		var map := MapData.parse(text, MapStyle.new(), 1)
		assert_true(map.foliage.is_empty(), "no bushes from %s" % JSON.stringify(raw))
		var warned := false
		for w in map.warnings:
			warned = warned or w.begins_with("foliage ")
		assert_true(warned, "warned for %s" % JSON.stringify(raw))
