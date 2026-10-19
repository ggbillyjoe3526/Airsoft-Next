class_name Loadout
extends RefCounted
## One saved loadout (the browser game's pool/savedLoadouts.ts slot): its name, the replica in each slot (pool.md IDs:
## primary, then secondary) and each replica's setup. Plain data; LoadoutRules says what is allowed and what it plays
## as.

enum Slot { PRIMARY, SECONDARY }

var name: String = ""
## The replica's pool.md ID in each Slot.
var equipped: PackedStringArray = PackedStringArray(["", ""])
## Each replica's setup by its pool.md ID: every replica the player has set up, carried now or not.
var tunes: Dictionary[String, ReplicaTune] = {}


## The replica in `slot`.
func replica_id(slot: Slot) -> String:
	return equipped[slot]


## A deep copy named `new_name`.
func copy(new_name: String) -> Loadout:
	var l := Loadout.new()
	l.name = new_name
	l.equipped = equipped.duplicate()
	for id: String in tunes:
		l.tunes[id] = tunes[id].copy()
	return l


func to_dict() -> Dictionary:
	var t := {}
	for id: String in tunes:
		t[id] = tunes[id].to_dict()
	return {"name": name, "equipped": Array(equipped), "tunes": t}
