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
## The modes a map of each kind hosts (data/maps.md's Kind): every field hosts Elimination and Attack / Defend (the
## latter only with a flagpole), the range its own practice mode.
const KIND_MODES: Dictionary[StringName, PackedStringArray] = {
	&"field": ["elimination", "attack_defend"],
	&"range": ["practice"],
}
## The rule sets (concepts `rules-skirmish.png`, `rules-custom.png`): Skirmish plays the round tuning as it is, Custom
## the settings' CustomRules.
const RULES_SKIRMISH := "skirmish"
const RULES_CUSTOM := "custom"
const RULE_SETS: PackedStringArray = [RULES_SKIRMISH, RULES_CUSTOM]
## The words of a rule set: its name and its blurb (translation keys).
const RULES_NAME: Dictionary[String, String] = {RULES_SKIRMISH: "RULES_SKIRMISH", RULES_CUSTOM: "RULES_CUSTOM"}
const RULES_BLURB: Dictionary[String, String] = {
	RULES_SKIRMISH: "RULES_SKIRMISH_BLURB", RULES_CUSTOM: "RULES_CUSTOM_BLURB",
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
	var ricochets := "RULE_RICOCHETS_YES" if hits.ricochets_count else "RULE_RICOCHETS_NO"
	var out: Array[PackedStringArray] = []
	out.append(PackedStringArray(["", size_text(rounds.team_size)]))
	out.append(PackedStringArray([_tr("RULE_FIRST_TO"), str(rounds.wins_needed)]))
	out.append(PackedStringArray([_tr("RULE_ROUNDS"), clock_text(rounds.round_time)]))
	out.append(PackedStringArray([_tr("RULE_SWAP"), str(rounds.half_time_after)]))
	out.append(PackedStringArray([_tr("RULE_RICOCHETS"), _tr(ricochets)]))
	out.append(PackedStringArray([_tr("RULE_FRIENDLY_FIRE"), _tr(switch_key(hits.friendly_fire))]))
	return out


## A chip as one line of text.
static func chip_text(chip: PackedStringArray) -> String:
	return chip[1] if chip[0].is_empty() else "%s %s" % [chip[0], chip[1]]


## "3 v 3".
static func size_text(team_size: int) -> String:
	return _tr("RULE_SIZE") % [team_size, team_size]


## "2:30": `seconds` as minutes and seconds, a part-second counted whole.
static func clock_text(seconds: float) -> String:
	var clock := ceili(seconds)
	return "%d:%02d" % [clock / 60, clock % 60]


## "3v3": a Custom team size's button.
static func size_short(team_size: int) -> String:
	return _tr("RULE_SIZE_SHORT") % [team_size, team_size]


## The key of a switch's word: On or Off.
static func switch_key(on: bool) -> String:
	return "RULE_ON" if on else "RULE_OFF"


## What Skirmish says under its name: the match as the round tuning and the hit rules play it.
static func skirmish_blurb(rounds: RoundConfig, hits: HitConfig) -> String:
	return _tr(RULES_BLURB[RULES_SKIRMISH]) % [size_short(rounds.team_size), rounds.wins_needed,
			clock_text(rounds.round_time), _tr(switch_key(hits.friendly_fire)).to_lower()]


## What Custom says under its name, with its XP cap in bold and `lit` (bbcode): `cap` is the Custom multiplier.
static func custom_blurb(cap: float, lit: Color) -> String:
	var cap_text := _tr("RULE_XP_CAP") % ArmoryFacts.multiplier_text(cap)
	return _tr(RULES_BLURB[RULES_CUSTOM]) % ("[color=#%s][b]%s[/b][/color]" % [lit.to_html(false), cap_text])


## The line under a Custom row's buttons for the choice `value` (a team size, rounds to win, or a switch's 0 or 1): the
## browser game's blurb of that choice. `row` is "TEAM", "WINS", "FRIENDLY_FIRE" or "RICOCHETS".
static func choice_blurb(row: String, value: int) -> String:
	var words := _tr("RULE_%s_BLURB_%d" % [row, value])
	return words % value if words.contains("%d") else words


## The loading screen's kicker: "ELIMINATION · 3 V 3 · YOU'RE ALPHA".
static func kicker(mode: String, team_size: int, team: int) -> String:
	return (_tr("LOAD_KICKER") % [_tr(MODE_NAME[mode]), team_size, team_size, _tr(TEAM_KEYS[team])]).to_upper()


## The summary line's tail after the map's name: "Elimination · Alpha · Normal bots", or in Attack / Defend "Attack /
## Defend · Alpha attacks first · Normal bots"; it names the teammates' level when it differs from the opponents'
## (`mates`, "" for none), and with Custom rules (`custom`) it ends " · Custom 2v2".
static func summary_rest(mode: String, team: int, bots: String, custom: CustomRules = null,
		mates: String = "") -> String:
	var side := _tr(TEAM_KEYS[team])
	if POLE_MODES.has(mode):
		side = _tr("MENU_ATTACKS_FIRST_SHORT") % side
	var rest := _tr("MENU_SUMMARY_REST") % [_tr(MODE_NAME[mode]), side, _tr("BOT_" + bots.to_upper())]
	if not mates.is_empty() and mates != bots:
		rest += _tr("MENU_SUMMARY_MATES") % _tr("BOT_" + mates.to_upper())
	if custom != null:
		rest += _tr("MENU_SUMMARY_CUSTOM") % size_short(custom.team_size)
	return rest


## Your teammates' level as played: the one picked, or the opponents' as it follows (BotConfig.teammates_following).
static func teammates_level(opponents: String, picked: String) -> String:
	return picked if not picked.is_empty() else String(BotConfig.teammates_following(StringName(opponents)))


## The Opponents row's line for `level` (the browser game's DIFFICULTIES blurb), with the match's XP multiplier `xp` in
## bold and `lit` (bbcode).
static func opponents_blurb(level: String, xp: float, lit: Color) -> String:
	return "%s %s" % [_tr("BOT_%s_BLURB" % level.to_upper()), xp_note(xp, lit)]


## The Teammates row's line for `level` (the browser game's TEAMMATE_DIFFICULTIES blurb).
static func teammates_blurb(level: String) -> String:
	return _tr("BOT_%s_MATES" % level.to_upper())


## "XP ×1.5" in bold and `lit` (bbcode).
static func xp_note(xp: float, lit: Color) -> String:
	return "[color=#%s][b]%s[/b][/color]" % [lit.to_html(false), _tr("BOT_XP") % ArmoryFacts.multiplier_text(xp)]


static func _tr(key: String) -> String:
	return TranslationServer.translate(key)
