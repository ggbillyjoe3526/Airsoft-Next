class_name LoadoutRules
extends RefCounted
## What a loadout may hold and what it plays as (the browser game's pool/loadoutModel.ts and pool/kit.ts): the
## replicas on offer, each replica's setup as it comes, the edits the Loadout makes (each checked and snapped), and the
## kit a loadout is carried as. Pure: the pool, stats.md and the replica rules are handed in.
##
## Gear that is saved but not on offer now (a dev replica with Dev content off) stays picked and plays as the slot's
## default (docs/DECISIONS.md › Loadout).

var pool: Pool = null
var stats: ReplicaStats = null
var rules: ReplicaRulesConfig = null
## Dev content on: dev items are offered too.
var dev_content: bool = false
var _configs: Dictionary[StringName, ReplicaConfig] = {}


func _init(pool_in: Pool, stats_in: ReplicaStats, rules_in: ReplicaRulesConfig) -> void:
	pool = pool_in
	stats = stats_in
	rules = rules_in


## The rules as shipped: data/pool.md, data/stats.md and the default replica rules.
static func standard() -> LoadoutRules:
	var s := ReplicaStats.read_file()
	s.warn()
	return LoadoutRules.new(Pool.shared(), s, SimTuning.load_default().replica_rules)


## The replicas a player can carry now, in pool order: those the game can play (a built-in config), public ones and,
## with Dev content on, dev ones.
func offered() -> Array[Pool.Item]:
	var out: Array[Pool.Item] = []
	for it in pool.replicas:
		if (dev_content or not it.is_dev()) and config(it) != null:
			out.append(it)
	return out


func is_offered(id: String) -> bool:
	for it in offered():
		if it.id == id:
			return true
	return false


## The replica's stats as it comes (stats.md over the built-in config), or null if the game can't play it.
func config(item: Pool.Item) -> ReplicaConfig:
	if item == null or item.kind != Pool.Kind.REPLICA:
		return null
	if not _configs.has(item.key):
		_configs[item.key] = stats.replica_config(item.key)
	return _configs[item.key]


## The replica the slot carries for a new player (ReplicaStats.DEFAULT_LOADOUT), or "" if the pool lacks it.
func default_id(slot: Loadout.Slot) -> String:
	var it := pool.replica_by_key(ReplicaStats.DEFAULT_LOADOUT[slot])
	return it.id if it != null else ""


## A new player's loadout: the default replicas, each as it comes.
func default_loadout(loadout_name: String) -> Loadout:
	var l := Loadout.new()
	l.name = loadout_name
	for slot: Loadout.Slot in [Loadout.Slot.PRIMARY, Loadout.Slot.SECONDARY]:
		l.equipped[slot] = default_id(slot)
	return l


## `item` as it comes: its factory BB weight and dial, its class's colour and the first power source that fits.
func default_tune(item: Pool.Item) -> ReplicaTune:
	var t := ReplicaTune.new()
	var r := config(item)
	if r == null:
		return t
	t.bb_weight = clampf(r.bb_weight, rules.bb_weight_min, rules.bb_weight_max)
	t.hop_up = clampf(r.hop_up_dial, rules.hop_up_min_dial, rules.hop_up_max_dial)
	t.paint = ReplicaSchemes.OWN if ReplicaSchemes.OWN_COLOURS.has(item.key) \
			else ReplicaSchemes.default_paint(r.site_class)
	var powers := pool.powers_for(item, false)
	t.power_id = powers[0].id if not powers.is_empty() else ""
	return t


## The setup of replica `id` in `loadout`: the one saved, else as it comes.
func tune_of(loadout: Loadout, id: String) -> ReplicaTune:
	if loadout.tunes.has(id):
		return loadout.tunes[id]
	return default_tune(pool.item(id))


## Carries replica `id` in `slot`; one already in the other slot swaps places. False if it isn't on offer.
func equip(loadout: Loadout, slot: Loadout.Slot, id: String) -> bool:
	if not is_offered(id):
		return false
	var other := 1 - int(slot)
	if loadout.equipped[other] == id:
		loadout.equipped[other] = loadout.equipped[slot]
	loadout.equipped[slot] = id
	return true


## Loads `grams` into replica `id`, kept within the range and snapped to its step; returns the weight set.
func set_bb_weight(loadout: Loadout, id: String, grams: float) -> float:
	var t := _editable(loadout, id)
	t.bb_weight = snap_bb_weight(grams)
	return t.bb_weight


## Sets replica `id`'s hop-up dial, kept within its range and snapped to the dial's notches; returns the dial set.
func set_hop_up(loadout: Loadout, id: String, dial: float) -> float:
	var t := _editable(loadout, id)
	t.hop_up = snap_hop_up(dial)
	return t.hop_up


## Paints replica `id`; false (and nothing changed) for an unknown paint or a replica that keeps its own colours.
func set_paint(loadout: Loadout, id: String, paint: StringName) -> bool:
	var it := pool.item(id)
	if it == null or ReplicaSchemes.OWN_COLOURS.has(it.key) or not ReplicaSchemes.is_paint(paint):
		return false
	_editable(loadout, id).paint = paint
	return true


## Fits power source `power_id` to replica `id`; false (and nothing changed) if it doesn't fit or isn't on offer.
func set_power(loadout: Loadout, id: String, power_id: String) -> bool:
	var it := pool.item(id)
	var pw := pool.item(power_id)
	if it == null or pw == null or pw.kind != Pool.Kind.POWER or not pool.powers_for(it, dev_content).has(pw):
		return false
	_editable(loadout, id).power_id = power_id
	return true


func snap_bb_weight(grams: float) -> float:
	var g := clampf(grams, rules.bb_weight_min, rules.bb_weight_max)
	return snappedf(g, rules.bb_weight_step)


func snap_hop_up(dial: float) -> float:
	var d := clampf(dial, rules.hop_up_min_dial, rules.hop_up_max_dial)
	return clampf(snappedf(d, rules.hop_up_dial_step), rules.hop_up_min_dial, rules.hop_up_max_dial)


## Puts back the default for every saved value that won't do (an unknown replica, a weight out of range, a power
## source that doesn't fit), each listed. Replicas not on offer now stay: they play as the default (carried).
func clean(loadout: Loadout) -> Array[String]:
	var out: Array[String] = []
	for slot: Loadout.Slot in [Loadout.Slot.PRIMARY, Loadout.Slot.SECONDARY]:
		var id := loadout.equipped[slot]
		var it := pool.item(id)
		if it == null or it.kind != Pool.Kind.REPLICA:
			out.append("%s: slot %d held \"%s\", no replica: the default" % [loadout.name, slot + 1, id])
			loadout.equipped[slot] = default_id(slot)
	if loadout.equipped[0] == loadout.equipped[1]:
		out.append("%s: the same replica in both slots: the default secondary" % loadout.name)
		loadout.equipped[1] = default_id(Loadout.Slot.SECONDARY) if loadout.equipped[0] != default_id(
				Loadout.Slot.SECONDARY) else default_id(Loadout.Slot.PRIMARY)
	for id: String in loadout.tunes.keys():
		var it := pool.item(id)
		if it == null or it.kind != Pool.Kind.REPLICA:
			out.append("%s: a setup for \"%s\", no replica: dropped" % [loadout.name, id])
			loadout.tunes.erase(id)
			continue
		var t := loadout.tunes[id]
		var fallback := default_tune(it)
		if is_nan(t.bb_weight) or not is_equal_approx(t.bb_weight, snap_bb_weight(t.bb_weight)):
			out.append("%s: %s's BB weight %s won't do: as it comes" % [loadout.name, it.display_name, t.bb_weight])
			t.bb_weight = fallback.bb_weight
		if is_nan(t.hop_up) or not is_equal_approx(t.hop_up, snap_hop_up(t.hop_up)):
			out.append("%s: %s's hop-up %s won't do: as it comes" % [loadout.name, it.display_name, t.hop_up])
			t.hop_up = fallback.hop_up
		var own := ReplicaSchemes.OWN_COLOURS.has(it.key)
		if (own and t.paint != ReplicaSchemes.OWN) or (not own and not ReplicaSchemes.is_paint(t.paint)):
			out.append("%s: %s's colour \"%s\" won't do: as it comes" % [loadout.name, it.display_name, t.paint])
			t.paint = fallback.paint
		var pw := pool.item(t.power_id)
		if t.power_id != fallback.power_id and (pw == null or pw.kind != Pool.Kind.POWER or not pool.fits(pw, it)):
			out.append("%s: %s's power source \"%s\" won't do: as it comes" % [loadout.name, it.display_name,
					t.power_id])
			t.power_id = fallback.power_id
	return out


## What `loadout` plays as: each slot's replica (the slot's default if it isn't on offer now) with its power source
## (the default one if it isn't on offer now) and dial, and its BB weight and paint. A slot whose replica the game can't play is left out.
func carried(loadout: Loadout) -> Kit:
	var kit := Kit.new()
	var used := PackedStringArray()
	for slot: Loadout.Slot in [Loadout.Slot.PRIMARY, Loadout.Slot.SECONDARY]:
		var id := loadout.equipped[slot]
		if not is_offered(id) or used.has(id):
			id = default_id(slot) if not used.has(default_id(slot)) else default_id(1 - int(slot) as Loadout.Slot)
		var it := pool.item(id)
		var base := config(it)
		if base == null or used.has(id):
			continue
		used.append(id)
		var t := tune_of(loadout, id)
		var power_id := t.power_id
		var pw := pool.item(power_id)
		if pw == null or not pool.powers_for(it, dev_content).has(pw):
			power_id = default_tune(it).power_id
			pw = pool.item(power_id)
		var r := base.duplicate() as ReplicaConfig
		var p := stats.power(power_id)
		var energy := base.muzzle_energy * (1.0 + p.energy)
		var limit := stats.energy_limit(base.site_class)
		r.muzzle_energy = minf(energy, limit)
		r.fire_rate = base.fire_rate * (1.0 + p.fire_rate)
		r.recoil_deg = base.recoil_deg * (1.0 + p.recoil)
		r.hop_up_dial = t.hop_up
		kit.replicas.append(r)
		kit.bb_weights.append(t.bb_weight)
		kit.paints.append(t.paint)
		kit.capped.append(energy > limit)
		kit.dev = kit.dev or it.is_dev() or (pw != null and pw.is_dev())
	return kit


## The setup of replica `id` to edit: the saved one, made from the default the first time.
func _editable(loadout: Loadout, id: String) -> ReplicaTune:
	if not loadout.tunes.has(id):
		loadout.tunes[id] = default_tune(pool.item(id))
	return loadout.tunes[id]
