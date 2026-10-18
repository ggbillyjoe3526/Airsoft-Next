extends GutTest
## The HUD's magazine gauges (game/ui/mag_gauges.gd): one per magazine, the loaded one first and the spares fullest
## first, each its share of a full magazine; empty ones stay hollow; they follow shots, swaps and switches, and a frame
## with no change redraws nothing.

var c: Character
var a: Armament
var shares: PackedFloat32Array


func before_each() -> void:
	c = Character.new(1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	a = c.armament
	shares = PackedFloat32Array()


func test_one_gauge_per_magazine_carried_all_full_at_the_start() -> void:
	var r := a.replica()
	var n := MagGauges.fill_shares(a, shares)
	assert_eq(n, r.mags)
	for i in n:
		assert_almost_eq(shares[i], 1.0, 0.0001)


func test_the_loaded_magazine_first_then_the_spares_fullest_first() -> void:
	var r := a.replica()
	var ammo := a.ammo[a.active]
	ammo.mag = r.mag_size / 2
	ammo.pouch = PackedInt32Array([0, r.mag_size, r.mag_size / 4])
	var n := MagGauges.fill_shares(a, shares)
	assert_eq(n, 4)
	assert_almost_eq(shares[0], float(r.mag_size / 2) / r.mag_size, 0.0001)
	assert_almost_eq(shares[1], 1.0, 0.0001)
	assert_almost_eq(shares[2], float(r.mag_size / 4) / r.mag_size, 0.0001)
	assert_almost_eq(shares[3], 0.0, 0.0001, "the empty spare last, drawn hollow")


func test_the_gauges_are_the_replica_in_hand() -> void:
	a.ammo[1].mag = 0
	a.active = 1
	var n := MagGauges.fill_shares(a, shares)
	assert_eq(n, a.replicas[1].mags)
	assert_almost_eq(shares[0], 0.0, 0.0001)


func test_no_replica_no_gauges() -> void:
	var bare := Character.new(2, 0, Vector3.ZERO, 0.0, [] as Array[ReplicaConfig])
	assert_eq(MagGauges.fill_shares(bare.armament, shares), 0)


func test_a_frame_with_no_change_rebuilds_nothing_and_a_change_does() -> void:
	var g := MagGauges.new()
	g.setup(HudConfig.new())
	add_child_autofree(g)
	g.refresh(a)
	var before := g._shares.duplicate()
	g._shares.fill(-1.0)
	g.refresh(a)
	assert_eq(g._shares[0], -1.0, "unchanged state left the gauges alone")
	a.ammo[a.active].mag -= 1
	g.refresh(a)
	assert_lt(g._shares[0], before[0], "a shot shows on the loaded gauge")
	assert_eq(g._count, a.replica().mags)
