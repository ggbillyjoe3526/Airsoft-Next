class_name BotTorch
## Bots and their weapon torches on a field played at night (the browser game's ai/botTorch.ts, M33h; WL7). Every bot
## carries one there (BotKits.night_light). The torch light the bots' sight reads (NightField.update_torches) is brought
## up to date once per perception interval (`refresh`, before the bots think), and each bot with a light in hand
## switches it through its command by what it is doing (`wants_torch`), holding a state BotConfig.torch_min_hold at
## least: no strobing. By day (no night field) nothing here runs and the command's switch is never pressed, so a kit
## with a torch plays exactly as one without. Allocates nothing.


## The share of an interval a time may fall short of it by and still count as in it (floating point).
const INTERVAL_EPSILON := 1e-6


## The torch light, once per perception interval (BotConfig.think_interval) on a night field; nothing by day.
static func refresh(w: BotWorld) -> void:
	if w.night == null:
		return
	# A hair over, so a time a whole number of intervals in (10.1 s of 0.1 s) is that interval, not the one before.
	w.night.update_torches(w.characters, w.query, w.tuning, w.cfg.aim_height_fraction,
			floori(w.time / w.cfg.think_interval + INTERVAL_EPSILON))


## Whether `b` wants its torch on: fighting someone within `reach` it can still make out, and on the last stretch of a
## search (within its skill's search_walk_distance of where it last knew of someone); off advancing, on the way to a
## search, in cover, at the pole, on orders and between rounds. A bot that doesn't keep out of the light (Easy,
## BotSkill.keeps_dark off) keeps it on while advancing and searching too: a beam switched on far from the fight only
## gives its bot away (the browser's M71). Reads the last tick's mode and target (a tick's lag is nothing next to the
## hold).
static func wants_torch(b: Bot, w: BotWorld, reach: float) -> bool:
	if not w.live:
		return false
	var sloppy := not b.skill.keeps_dark
	match b.mode:
		Bot.Mode.SEARCH:
			return sloppy or _within(b.character.position, b.last_known, b.skill.search_walk_distance)
		Bot.Mode.ADVANCE:
			return sloppy
		Bot.Mode.FIGHT:
			if b.target_id < 0:
				return false
			for c in w.characters:
				if c.id == b.target_id:
					return Elimination.is_in_play(c) and _within(b.character.position, c.position, reach)
	return false


## One tick of `b`'s torch into `cmd` (after BotBrain.think wrote the rest): a press when its wish differs from the
## torch's state and that state has been held long enough; on a night field only.
static func step(b: Bot, w: BotWorld, cmd: PlayerCommand) -> void:
	cmd.toggle_torch = false
	if w.night == null:
		return
	var me := b.character
	var light := Torch.in_hand(me)
	if light == null or not Elimination.is_in_play(me):
		return
	var want := wants_torch(b, w, minf(w.cfg.torch_fight_reach, light.reach))
	if want != me.torch_on and me.torch_time >= w.cfg.torch_min_hold:
		cmd.toggle_torch = true


## Whether `a` and `p` are within `d` of each other across the ground.
static func _within(a: Vector3, p: Vector3, d: float) -> bool:
	var dx := a.x - p.x
	var dz := a.z - p.z
	return dx * dx + dz * dz <= d * d
