class_name BotFlag
## Attack / Defend for bots (the browser game's ai/bot.ts flagRole and wantsFlag, roundPlanner.ts pickRetakers and
## pickRaiser): which side of the pole a bot's team is on, which pole is in play on a map with two (AB1), which defenders
## go to pull its flag down, which attacker raises it while the others guard, and when a bot wants the pole; in
## Elimination, when a bot goes for the overtime flag (OV2). Where it walks there is BotMovement's flag mode.
## Allocates nothing.

enum Role { NONE, ATTACK, DEFEND }


## Whether `b`'s team attacks or defends the pole this round (NONE in Elimination).
static func role(b: Bot, w: BotWorld) -> Role:
	if w.mode != RoundState.Mode.ATTACK_DEFEND or w.attackers < 0:
		return Role.NONE
	return Role.ATTACK if b.character.team == w.attackers else Role.DEFEND


## The pole in play (BotWorld.flag): Flag.in_play's (the highest flag going up, else the highest), so both teams go
## where a flag is going up (the player's too), else the one the attackers drew for the round (RoundPlanner.attack_flag).
static func in_play(w: BotWorld) -> int:
	var up := Flag.in_play(w.flags)
	if up >= 0:
		return up
	return clampi(w.planner.attack_flag, 0, w.flags.size() - 1) if w.planner != null else 0


## Where defender `b` holds and searches round (BotBrain): the pole nearest the end of the lane it was dealt, its site.
static func post_of(b: Bot, w: BotWorld) -> Vector3:
	return w.flags[maxi(0, Flag.nearest(w.flags, b.lane_goal))].position


## Holding a post rather than hunting once its lane is walked: a defender (at the point it was dealt) or an anchor.
static func holds_post(b: Bot, w: BotWorld) -> bool:
	return role(b, w) == Role.DEFEND or BotPersonality.anchor_holding(b, w)


## True if `b` should be at the pole now: an attacker that has swept its lane, or a defender picked to retake while the
## flag is off the bottom (the flag on its pole is in plain view). The others hold their posts. In Elimination's
## overtime (OV2), every bot once its reaction to the flag going up is over (Bot.overtime_at), while the round is live:
## the flag comes before chasing noises, as the pole does.
static func wants_flag(b: Bot, w: BotWorld) -> bool:
	match role(b, w):
		Role.ATTACK:
			return b.lane_done
		Role.DEFEND:
			return w.flag.progress > 0.0 and b.retake
	return w.overtime_flag.up and w.live and w.time >= b.overtime_at


## Where flag mode heads: Elimination's overtime flag while it is up (its foot), else Attack / Defend's pole.
static func spot(w: BotWorld) -> Vector3:
	return w.overtime_flag.foot if w.overtime_flag.up else w.flag.position


## Each tick: the `retakers` defending bots in play nearest the pole are the ones who go to pull the flag down; the rest
## hold their posts, so tagging the pole doesn't empty every lane. Re-picked every tick, so if one is hit the next
## nearest takes over. A bot under a squad order isn't picked: it does what it was asked, and the next nearest goes.
static func pick_retakers(w: BotWorld) -> void:
	for b in w.bots:
		b.retake = false
		var c := b.character
		if role(b, w) != Role.DEFEND or not Elimination.is_in_play(c) or b.order != SquadOrder.Kind.NONE:
			continue
		var d := _to_pole(c, w)
		var closer := 0
		for o in w.bots:
			var oc := o.character
			if o == b or oc.team != c.team or not Elimination.is_in_play(oc) or o.order != SquadOrder.Kind.NONE:
				continue
			var od := _to_pole(oc, w)
			if od < d or (od == d and oc.id < c.id):
				closer += 1
		b.retake = closer < w.cfg.retakers


## Each tick: of the attacking bots in play that have swept their lane, one raises the flag and the others guard the pole
## (a second raiser adds nothing: the rope goes up no faster). Bots in flag mode first, then the nearest the pole, the
## current raiser counted raiser_switch_margin nearer; never a bot under a squad order. Nobody raises while an attacker
## who isn't a bot (the player) is at the pole already.
static func pick_raiser(w: BotWorld) -> void:
	var raiser: Bot = null
	var best_rank := 2
	var best := INF
	for b in w.bots:
		var keep := b.raiser
		b.raiser = false
		if role(b, w) != Role.ATTACK or not Elimination.is_in_play(b.character) or not b.lane_done \
				or b.order != SquadOrder.Kind.NONE:
			continue
		var rank := 0 if b.mode == Bot.Mode.FLAG else 1
		var d := _to_pole(b.character, w) - (w.cfg.raiser_switch_margin if keep else 0.0)
		if rank < best_rank or (rank == best_rank and d < best):
			best_rank = rank
			best = d
			raiser = b
	if raiser == null:
		return
	for c in w.characters:
		if c.team == w.attackers and not _is_bot(c, w) and Flag.at_pole(c, w.flag, w.tuning.flag):
			return
	raiser.raiser = true


static func _to_pole(c: Character, w: BotWorld) -> float:
	return Vector2(c.position.x - w.flag.position.x, c.position.z - w.flag.position.z).length()


static func _is_bot(c: Character, w: BotWorld) -> bool:
	for b in w.bots:
		if b.character == c:
			return true
	return false
