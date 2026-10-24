class_name DevSettings
extends RefCounted
## The Dev tab's switches (the browser game's config/dev.ts), saved with the settings. They apply only while the Dev
## settings box is ticked (owner, 2026-10-04): `Settings.active_dev()` is these then, else the defaults. Game speed,
## bottomless magazines, ghost, bots hold fire, spectate any bot, bot intentions and Disable levelling keep a match
## out of the records and give it no XP (DevCheats); Dev content lists maps tagged dev and keeps a match on one out
## too; Retro pixels changes only the look. Disable levelling unlocks every item to carry; your own level and unlocks
## stay as they are and come back when it is off. Pretend slow frames counts every frame of a live round slow for the
## automatic graphics step-down (FrameWatch), to check it on a fast machine; it changes nothing else. A saved key
## no switch reads any more (Rigged figures, gone with FI7) is passed over.

const SPEED_STEP := 0.25

var dev_content: bool = false
var disable_levelling: bool = false
var game_speed: float = 1.0
var bottomless: bool = false
var ghost: bool = false
var bots_hold_fire: bool = false
var spectate_bots: bool = false
var bot_intent: bool = false
var retro_pixels: bool = false
var pretend_slow_frames: bool = false


## The cheats among them, as the simulation takes them.
func cheats() -> DevCheats:
	var c := DevCheats.new()
	c.game_speed = game_speed
	c.bottomless = bottomless
	c.ghost = ghost
	c.bots_hold_fire = bots_hold_fire
	c.watching = spectate_bots or bot_intent
	c.levelling_off = disable_levelling
	return c


func to_dict() -> Dictionary:
	return {
		"dev_content": dev_content, "disable_levelling": disable_levelling, "game_speed": game_speed,
		"bottomless": bottomless, "ghost": ghost,
		"bots_hold_fire": bots_hold_fire, "spectate_bots": spectate_bots, "bot_intent": bot_intent,
		"retro_pixels": retro_pixels, "pretend_slow_frames": pretend_slow_frames,
	}


## Saved values over the defaults, each checked on its own; game speed must be on its 25 % steps.
func from_dict(data: Dictionary) -> void:
	dev_content = _flag(data, "dev_content")
	disable_levelling = _flag(data, "disable_levelling")
	var speed: Variant = data.get("game_speed")
	game_speed = 1.0
	if (speed is float or speed is int) and float(speed) >= DevCheats.SPEED_MIN and float(speed) <= DevCheats.SPEED_MAX:
		game_speed = snappedf(float(speed), SPEED_STEP)
	bottomless = _flag(data, "bottomless")
	ghost = _flag(data, "ghost")
	bots_hold_fire = _flag(data, "bots_hold_fire")
	spectate_bots = _flag(data, "spectate_bots")
	bot_intent = _flag(data, "bot_intent")
	retro_pixels = _flag(data, "retro_pixels")
	pretend_slow_frames = _flag(data, "pretend_slow_frames")


static func _flag(data: Dictionary, key: String) -> bool:
	var v: Variant = data.get(key)
	return v if v is bool else false
