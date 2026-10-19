class_name ReplicaSchemes
extends RefCounted
## Replica colours (the browser game's config/schemes.ts; William, 2026-10-05 and 2026-10-16): every replica is
## two-tone, like a painted toy. A player picks, per replica, one of eight bold schemes or one of four plain colours
## (a "paint"); the Realistic colours setting shows each bold scheme as its plain family. Colour changes how a replica
## looks, never how it shoots. Ids are save keys: never rename one.

## The five colours of a paint, by the model's material names (assets/models/replicas/*.glb).
const PARTS: Array[StringName] = [&"Body", &"Furniture", &"Detail", &"Accent", &"Metal"]
## The Cyber Pistol's paint: it keeps its own colours and no scheme applies to it.
const OWN := &"own"
## The replica Keys that keep their own colours (the Cyber Pistol's light lines; schemes.ts hasFixedColours).
const OWN_COLOURS: Array[StringName] = [&"cyber"]

## The bold schemes in the order the Loadout lists them: name, the five colours (PARTS' order) and the plain family
## Realistic colours turns it into.
const SCHEMES: Dictionary[StringName, Dictionary] = {
	&"cobalt": {"name": "Cobalt", "colours": [0x24282f, 0x2f6fd6, 0x30343b, 0xf2f0ea, 0x484d56], "family": &"black"},
	&"signal": {"name": "Signal", "colours": [0xe8ebee, 0xff5a1f, 0x2a2d33, 0x2a2d33, 0x484d56], "family": &"tan"},
	&"acid": {"name": "Acid", "colours": [0x2a2e33, 0xb8e636, 0x1e2125, 0xb8e636, 0x40454c], "family": &"ranger"},
	&"teal": {"name": "Teal", "colours": [0x23272c, 0x22a196, 0x2e3238, 0xffb23a, 0x484d56], "family": &"ranger"},
	&"hazard": {"name": "Hazard", "colours": [0x2a2d32, 0xf0b429, 0x1f2226, 0x1f2226, 0x484d56], "family": &"tan"},
	&"coral": {"name": "Coral", "colours": [0xf1ece3, 0xff4f6d, 0x34373e, 0x34373e, 0x50555d], "family": &"tan"},
	&"onyx": {"name": "Onyx", "colours": [0x1d1f23, 0x34383e, 0x2a2d32, 0x7d838c, 0x40454c], "family": &"black"},
	&"ghost": {"name": "Ghost", "colours": [0xeef0f2, 0xc4c9cf, 0x3a3e45, 0x30f0ff, 0x6a7079], "family": &"grey"},
}
## The plain colours, picked as they are or shown for a scheme under Realistic colours.
const FAMILIES: Dictionary[StringName, Dictionary] = {
	&"black": {"name": "Black", "colours": [0x26292e, 0x30343a, 0x2b2e33, 0x4a4f56, 0x3c4046]},
	&"grey": {"name": "Wolf grey", "colours": [0x4f545b, 0x646a72, 0x464a50, 0x7a8088, 0x3c4046]},
	&"ranger": {"name": "Ranger green", "colours": [0x4a5439, 0x5a6645, 0x434c34, 0x6c7856, 0x3f4536]},
	&"tan": {"name": "Tan", "colours": [0xb49668, 0xc9ab79, 0x564a39, 0x8c7250, 0x45433f]},
}
## What a replica wears before the player picks, by its site class (William: a Cobalt rifle and a Ghost pistol).
const DEFAULTS: Dictionary[StringName, StringName] = {&"rifle": &"cobalt", &"pistol": &"ghost"}
## What a bot carries, by team (0 Alpha, 1 Beta) and site class.
const BOT_PAINTS: Array[Dictionary] = [
	{&"rifle": &"cobalt", &"pistol": &"onyx"},
	{&"rifle": &"signal", &"pistol": &"coral"},
]


## True if `paint` is a bold scheme or a plain colour a player can pick.
static func is_paint(paint: StringName) -> bool:
	return SCHEMES.has(paint) or FAMILIES.has(paint)


## The paint a replica of `site_class` wears before the player picks.
static func default_paint(site_class: StringName) -> StringName:
	return DEFAULTS.get(site_class, DEFAULTS[&"rifle"])


## The paint a bot on `team` carries on a replica of `site_class`.
static func bot_paint(team: int, site_class: StringName) -> StringName:
	var by_class: Dictionary = BOT_PAINTS[clampi(team, 0, BOT_PAINTS.size() - 1)]
	return by_class.get(site_class, by_class[&"rifle"])


## The five colours `paint` is drawn in (PARTS' order): a plain colour as it is, a scheme as itself or, under
## `realistic`, its family. Empty for OWN or an unknown paint (the model's own colours).
static func colours(paint: StringName, realistic: bool) -> Array[Color]:
	var entry: Dictionary = {}
	if FAMILIES.has(paint):
		entry = FAMILIES[paint]
	elif SCHEMES.has(paint):
		entry = FAMILIES[SCHEMES[paint]["family"]] if realistic else SCHEMES[paint]
	var out: Array[Color] = []
	for hex: int in entry.get("colours", []):
		out.append(Color.hex((hex << 8) | 0xff))
	return out


## The paint's name as the Loadout shows it ("Cobalt"; a scheme under `realistic` shows as its family's).
static func paint_name(paint: StringName, realistic: bool) -> String:
	if FAMILIES.has(paint):
		return FAMILIES[paint]["name"]
	if SCHEMES.has(paint):
		return FAMILIES[SCHEMES[paint]["family"]]["name"] if realistic else SCHEMES[paint]["name"]
	return ""
