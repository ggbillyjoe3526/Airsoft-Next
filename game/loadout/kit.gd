class_name Kit
extends RefCounted
## What a loadout plays as (the browser game's PlayerKit): each slot's replica as carried (its power source and
## hop-up dial applied), the BB weight loaded, its paint, and whether the site limit cut its energy. Made by
## LoadoutRules.carried; Armament takes the replicas and weights.

var replicas: Array[ReplicaConfig] = []
var bb_weights: PackedFloat64Array = PackedFloat64Array()
var paints: Array[StringName] = []
## True for a slot whose power source would have pushed it past its site limit (the Loadout says so).
var capped: Array[bool] = []
## Carries a dev item: the match stays off the record (docs/DECISIONS.md › Content tags and dev content).
var dev: bool = false


func size() -> int:
	return replicas.size()
