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


func test_a_swap_a_switch_and_a_new_round_each_change_the_gauges() -> void:
	var g := MagGauges.new()
	g.setup(HudConfig.new())
	add_child_autofree(g)
	a.ammo[0].mag = 3
	g.refresh(a)
	assert_almost_eq(g._shares[0], 3.0 / a.replicas[0].mag_size, 0.0001)
	# A reload's swap: the loaded and the fullest spare trade places.
	a.ammo[0].pouch[0] = a.replicas[0].mag_size
	var swapped := a.ammo[0].mag
	a.ammo[0].mag = a.ammo[0].pouch[0]
	a.ammo[0].pouch[0] = swapped
	g.refresh(a)
	assert_almost_eq(g._shares[0], 1.0, 0.0001)
	a.active = 1
	g.refresh(a)
	assert_eq(g._count, a.replicas[1].mags, "the pistol's gauges")
	a.refill()
	g.refresh(a)
	assert_eq(g._shown_slot, 0)
	assert_almost_eq(g._shares[g._count - 1], 1.0, 0.0001, "a new round: all full again")


func test_a_replica_with_one_magazine_has_one_gauge() -> void:
	var one := ReplicaStats.default_loadout()[0].duplicate() as ReplicaConfig
	one.mags = 1
	var loadout: Array[ReplicaConfig] = [one]
	var ch := Character.new(3, 0, Vector3.ZERO, 0.0, loadout)
	var g := MagGauges.new()
	g.setup(HudConfig.new())
	add_child_autofree(g)
	g.refresh(ch.armament)
	assert_eq(g._count, 1)
	ch.armament.ammo[0].mag = 0
	g.refresh(ch.armament)
	assert_almost_eq(g._shares[0], 0.0, 0.0001)
	g.size = Vector2(200.0, 40.0)
	await wait_physics_frames(2)
	assert_eq(g._count, 1, "drawing a lone empty gauge is safe")
