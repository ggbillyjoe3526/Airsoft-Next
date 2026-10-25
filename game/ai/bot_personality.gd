class_name BotPersonality
## Bot personalities (the browser game's ai/personality.ts, bots.md): how a bot plays on top of its difficulty. A
## personality scales the level's habits (pauses, cover, searching, bursts, angles and corners) into the bot's own
## BotSkill once, when the bot is made, and leaves its senses, reaction, turning and aim as the level has them; the
## habits no level has (pushing in, waiting for the team, its own lane, holding short of the middle, aiming from cover,
## watching the overtime flag first) are read from Bot.style where they apply. Pure.


## `skill` with `style` laid over it: a copy, or `skill` itself when the style changes nothing. Reaction, turning, aim
## error, leading and the team habits stay the level's, whatever the personality.
static func personal_skill(skill: BotSkill, style: BotsFile.Style) -> BotSkill:
	if style.is_neutral():
		return skill
	var s: BotSkill = skill.duplicate()
	s.hold_time = skill.hold_time * style.hold_time
	s.hold_cover_chance = clampf(skill.hold_cover_chance * style.hold_cover_chance, 0.0, 1.0)
	s.contact_cover_min_distance = skill.contact_cover_min_distance * style.contact_cover_min_distance
	s.search_walk_distance = skill.search_walk_distance * style.search_walk_distance
	s.flank_chance = clampf(skill.flank_chance + style.flank_chance, 0.0, 1.0)
	s.burst = skill.burst * style.burst
	s.burst_pause = skill.burst_pause * style.burst_pause
	if style.has_peek_watch:
		s.peek_watch_time = style.peek_watch_time
	if style.holds_angles != BotsFile.Habit.SAME:
		s.holds_angles = style.holds_angles == BotsFile.Habit.ON
	if style.slices_corners != BotsFile.Habit.SAME:
		s.slices_corners = style.slices_corners == BotsFile.Habit.ON
	return s


## Pushes in (bots.md › Habits): closes in on its target as it sidesteps, takes no cover on a fresh sighting and runs at
## where someone was. Not under a squad order: it does what it was asked.
static func pushes_in(b: Bot) -> bool:
	return b.style.pushes_in and b.order == SquadOrder.Kind.NONE


## An anchor holding (bots.md › Holds until), in Elimination: on its lane, not hunting, while the round clock is above
## the personality's mark and a teammate is still in play. It stops at the last lane point short of the middle
## (RoundPlanner.plan) and holds there; once it hunts (the late push, its mark passed, or a squad order ended) it goes
## on from where it stands. Not under a squad order: it does what it was asked.
static func anchor_holding(b: Bot, w: BotWorld) -> bool:
	if w.mode != RoundState.Mode.ELIMINATION or not b.style.holds or b.hunting or w.round_clock <= b.style.hold_until \
			or b.order != SquadOrder.Kind.NONE:
		return false
	var me := b.character
	for c in w.characters:
		if c != me and c.team == me.team and Elimination.is_in_play(c):
			return true
	return false


## Watching the overtime flag first (bots.md › Watches the flag first, OV2): from the moment it would go for the flag
## (Bot.overtime_at) and for the personality's seconds, it holds cover by the flag, aiming at it, as an attacker guards
## the pole. Not under a squad order, nor once BotConfig.overtime_go_by or less of the overtime is left, nor as the last
## of its team in play: then it goes in for the touch.
static func overtime_watching(b: Bot, w: BotWorld) -> bool:
	var flag := w.overtime_flag
	if not b.style.watches_flag or not flag.up or b.order != SquadOrder.Kind.NONE \
			or w.time >= b.overtime_at + b.style.flag_watch or flag.left <= w.cfg.overtime_go_by:
		return false
	var me := b.character
	for c in w.characters:
		if c != me and c.team == me.team and Elimination.is_in_play(c):
			return true
	return false
