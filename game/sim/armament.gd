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
