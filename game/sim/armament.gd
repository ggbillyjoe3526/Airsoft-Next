class_name Armament
extends RefCounted
## A character's replicas and what they're doing (the browser game's sim/armament.ts). STUB: the armament part of SC1
## fills this in.

var replicas: Array[ReplicaConfig] = []
var active: int = 0


static func create(loadout: Array[ReplicaConfig]) -> Armament:
	var a := Armament.new()
	a.replicas = loadout.duplicate()
	return a


## Full magazines again for a new round; selectors and dials kept.
func refill() -> void:
	pass


func reloading() -> bool:
	return false


func drawing() -> bool:
	return false


static func step(_c: Character, _cmd: PlayerCommand, _eye: Vector3, _kick_scale: float, _can_fire: bool, _pool: BBPool,
		_rng: RandomNumberGenerator, _events: SimEvents, _tuning: SimTuning, _dt: float) -> void:
	pass
