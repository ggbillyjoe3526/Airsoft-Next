class_name MatchOptions
extends RefCounted
## What the Match page offers, as plain rules the page only draws (tests read them without a screen): the modes and
## which of them a map hosts, the rules as chips read from the round tuning, which maps can't load yet, and the words
## on the loading screen and the summary line.

const MODE_ELIMINATION := "elimination"
const MODE_ATTACK_DEFEND := "attack_defend"
const MODE_PRACTICE := "practice"
## Every mode, in the order the cards show them.
const MODES: PackedStringArray = ["elimination", "attack_defend", "practice"]
## The modes that are built; the others show greyed with a LATER tag.
const BUILT_MODES: PackedStringArray = ["elimination", "attack_defend"]
## The modes that need a map with a flagpole (MapData.has_pole).
const POLE_MODES: PackedStringArray = ["attack_defend"]
## The words of a mode: its name and its line (translation keys).
const MODE_NAME: Dictionary[String, String] = {
	"elimination": "MODE_ELIMINATION", "attack_defend": "MODE_ATTACK_DEFEND", "practice": "MODE_PRACTICE",
}
const MODE_BLURB: Dictionary[String, String] = {
	"elimination": "MODE_ELIMINATION_BLURB", "attack_defend": "MODE_ATTACK_DEFEND_BLURB",
	"practice": "MODE_PRACTICE_BLURB",
}
const MODE_ELIMINATION_NAME := "MODE_ELIMINATION"
## The modes a map of each kind hosts (data/maps.md's Kind): every field hosts Elimination and Attack / Defend (the
## latter only with a flagpole), the range its own practice mode.
const KIND_MODES: Dictionary[StringName, PackedStringArray] = {
	&"field": ["elimination", "attack_defend"],
	&"range": ["practice"],
}
## The bots' levels, in the order shown.
const BOT_LEVELS: PackedStringArray = ["easy", "normal", "hard", "pro"]
const TEAM_KEYS: PackedStringArray = ["TEAM_ALPHA", "TEAM_BETA"]


## The modes `map` hosts, in the order the cards show them; none for a map the catalogue doesn't know.
static func modes_offered(map: MapCatalog.Entry) -> PackedStringArray:
	var out := PackedStringArray()
	if map == null:
		return out
	var hosted: PackedStringArray = KIND_MODES.get(map.kind, PackedStringArray())
	for mode in MODES:
		if hosted.has(mode):
			out.append(mode)
	return out


## Whether `mode` can be picked on `map`: built, hosted by that map, and for a pole mode the map has a flagpole
## (`has_pole`).
static func mode_pickable(mode: String, map: MapCatalog.Entry, has_pole: bool) -> bool:
	return BUILT_MODES.has(mode) and modes_offered(map).has(mode) and (has_pole or not POLE_MODES.has(mode))


## Whether `mode` is held back on `map` only for want of a flagpole: the card says so.
static func needs_pole(mode: String, map: MapCatalog.Entry, has_pole: bool) -> bool:
	return not has_pole and POLE_MODES.has(mode) and BUILT_MODES.has(mode) and modes_offered(map).has(mode)


## `map_id` loaded as the Match page lists it: its problems (empty when it can be played) and whether it has a pole.
static func map_check(map_id: String, style: MapStyle, team_size: int) -> MapData:
	return MapData.load_map(map_id, style, team_size)


## Why `map_id` can't be played now (MapData's problems), empty when it loads.
static func map_problems(map_id: String, style: MapStyle, team_size: int) -> Array[String]:
	return map_check(map_id, style, team_size).problems


## The rules as chips, each a (label, value) pair; the first has no label. Read from the round tuning and the hit rules.
static func rule_chips(rounds: RoundConfig, hits: HitConfig) -> Array[PackedStringArray]:
	var clock := ceili(rounds.round_time)
	var ricochets := "RULE_RICOCHETS_YES" if hits.ricochets_count else "RULE_RICOCHETS_NO"
	var out: Array[PackedStringArray] = []
	out.append(PackedStringArray(["", size_text(rounds.team_size)]))
	out.append(PackedStringArray([_tr("RULE_FIRST_TO"), str(rounds.wins_needed)]))
	out.append(PackedStringArray([_tr("RULE_ROUNDS"), "%d:%02d" % [clock / 60, clock % 60]]))
	out.append(PackedStringArray([_tr("RULE_SWAP"), str(rounds.half_time_after)]))
	out.append(PackedStringArray([_tr("RULE_RICOCHETS"), _tr(ricochets)]))
	return out


## A chip as one line of text.
static func chip_text(chip: PackedStringArray) -> String:
	return chip[1] if chip[0].is_empty() else "%s %s" % [chip[0], chip[1]]


## "3 v 3".
static func size_text(team_size: int) -> String:
	return _tr("RULE_SIZE") % [team_size, team_size]


## The loading screen's kicker: "ELIMINATION · 3 V 3 · YOU'RE ALPHA".
static func kicker(mode: String, team_size: int, team: int) -> String:
	return (_tr("LOAD_KICKER") % [_tr(MODE_NAME[mode]), team_size, team_size, _tr(TEAM_KEYS[team])]).to_upper()


## The summary line's tail after the map's name: "Elimination · Alpha · Normal bots", or in Attack / Defend "Attack /
## Defend · Alpha attacks first · Normal bots".
static func summary_rest(mode: String, team: int, bots: String) -> String:
	var side := _tr(TEAM_KEYS[team])
	if POLE_MODES.has(mode):
		side = _tr("MENU_ATTACKS_FIRST_SHORT") % side
	return _tr("MENU_SUMMARY_REST") % [_tr(MODE_NAME[mode]), side, _tr("BOT_" + bots.to_upper())]


static func _tr(key: String) -> String:
	return TranslationServer.translate(key)
