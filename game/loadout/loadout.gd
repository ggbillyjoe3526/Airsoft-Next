class_name Loadout
extends RefCounted
## One saved loadout (the browser game's pool/savedLoadouts.ts slot): its name, the replica in each slot (pool.md IDs:
## primary, then secondary), each replica's setup and its Glowing BBs choice. Plain data; LoadoutRules says what is
## allowed and what it plays as.

enum Slot { PRIMARY, SECONDARY }
## Glowing BBs (the browser game's config/glowBBs.ts, WL8): green BBs with a longer streak, loaded on night fields only
## (the default), on every field, or never. Presentation only: they fly as any BB.
enum Glow { NIGHT, ALWAYS, OFF }

## Each Glow as saved, in its order.
const GLOW_NAMES: PackedStringArray = ["night", "always", "off"]

var name: String = ""
## The replica's pool.md ID in each Slot.
var equipped: PackedStringArray = PackedStringArray(["", ""])
## Each replica's setup by its pool.md ID: every replica the player has set up, carried now or not.
var tunes: Dictionary[String, ReplicaTune] = {}
## Each replica's Glowing BBs choice by its pool.md ID; a replica not here loads them At Night.
var glow: Dictionary[String, Glow] = {}


## The replica in `slot`.
func replica_id(slot: Slot) -> String:
	return equipped[slot]


## Replica `id`'s Glowing BBs choice.
func glow_of(id: String) -> Glow:
	return glow.get(id, Glow.NIGHT)


## Loads replica `id` with Glowing BBs as `choice`; false when it already was.
func set_glow(id: String, choice: Glow) -> bool:
	if glow_of(id) == choice:
		return false
	glow[id] = choice
	return true


## Whether BBs loaded with `choice` glow on a field lit by a preset with `night` as its flag (the browser's bbsGlow).
static func glows(choice: Glow, night: bool) -> bool:
	return choice == Glow.ALWAYS or (choice == Glow.NIGHT and night)


## A deep copy named `new_name`.
func copy(new_name: String) -> Loadout:
	var l := Loadout.new()
	l.name = new_name
	l.equipped = equipped.duplicate()
	for id: String in tunes:
		l.tunes[id] = tunes[id].copy()
	l.glow = glow.duplicate()
	return l


func to_dict() -> Dictionary:
	var t := {}
	for id: String in tunes:
		t[id] = tunes[id].to_dict()
	var g := {}
	for id: String in glow:
		g[id] = GLOW_NAMES[glow[id]]
	return {"name": name, "equipped": Array(equipped), "tunes": t, "glow": g}
