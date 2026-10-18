extends RefCounted
## The AEG Rifle and GBB Pistol as data/stats.md and pool.md set them out of the box, built in code so the simulation's
## tests don't depend on the data tables (preload this; it isn't a test itself).


## The AEG Rifle: 0.97 J on 0.25 g, its factory hop-up dial at 0.65.
static func aeg() -> ReplicaConfig:
	var r := ReplicaConfig.new()
	r.id = &"aeg"
	r.muzzle_energy = 0.97
	r.bb_weight = 0.25
	r.hop_up_max = 0.3
	r.hop_up_dial = 0.65
	return r


## The GBB Pistol: 0.52 J on 0.2 g, its factory hop-up dial at 0.55.
static func pistol() -> ReplicaConfig:
	var r := ReplicaConfig.new()
	r.id = &"pistol"
	r.muzzle_energy = 0.52
	r.bb_weight = 0.2
	r.hop_up_max = 0.3
	r.hop_up_dial = 0.55
	return r
