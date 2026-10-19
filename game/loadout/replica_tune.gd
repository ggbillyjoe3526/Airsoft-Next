class_name ReplicaTune
extends RefCounted
## How the player has set up one replica (the browser game's per-replica picks): its BB weight, hop-up dial, paint,
## power source and parts. Kept per replica, so a replica swapped out and back keeps its setup. LoadoutRules checks the
## values.

## BB weight loaded (g).
var bb_weight: float = 0.25
## The hop-up dial (0..1 of the replica's hop_up_max), where each match starts.
var hop_up: float = 0.5
## A ReplicaSchemes scheme or plain colour, or ReplicaSchemes.OWN.
var paint: StringName = &"cobalt"
## The power source's pool.md ID; "" for a replica with its power built in.
var power_id: String = ""
## Each fitted part's pool.md ID by its slot (Pool.PART_TABLES); a slot not listed is as it comes.
var parts: Dictionary[StringName, String] = {}


func copy() -> ReplicaTune:
	var t := ReplicaTune.new()
	t.bb_weight = bb_weight
	t.hop_up = hop_up
	t.paint = paint
	t.power_id = power_id
	t.parts = parts.duplicate()
	return t


func to_dict() -> Dictionary:
	var fitted: Dictionary = {}
	for slot: StringName in parts:
		fitted[String(slot)] = parts[slot]
	return {"bb_weight": bb_weight, "hop_up": hop_up, "paint": String(paint), "power": power_id, "parts": fitted}


## Saved values as they are; LoadoutRules.clean puts back the defaults for what won't do.
static func from_dict(data: Dictionary, fallback: ReplicaTune) -> ReplicaTune:
	var t := fallback.copy()
	var w: Variant = data.get("bb_weight")
	if w is float or w is int:
		t.bb_weight = float(w)
	var h: Variant = data.get("hop_up")
	if h is float or h is int:
		t.hop_up = float(h)
	var p: Variant = data.get("paint")
	if p is String:
		t.paint = StringName(p)
	var pw: Variant = data.get("power")
	if pw is String:
		t.power_id = pw
	var fitted: Variant = data.get("parts")
	if fitted is Dictionary:
		t.parts.clear()
		for slot: Variant in fitted:
			var id: Variant = (fitted as Dictionary)[slot]
			if slot is String and id is String:
				t.parts[StringName(slot)] = id
	return t
