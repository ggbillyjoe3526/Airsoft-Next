class_name BotController
extends RefCounted
## Drives every character but the player (the browser game's ai/bot.ts updateBots): before each simulation step it
## plans the routes the tick's search budget allows (NavConfig.search_budget: the nav search is the costly part, so
## bots queue for it; BotRoutes.plan), then writes each bot's
## PlayerCommand; after the step it lets the bots hear what happened, hands out the squad orders given in it and gives
## each new round a fresh plan. Bots are just another controller: they act only through their commands (ARCHITECTURE
## contract 2). Pure: no nodes.

var world: BotWorld = BotWorld.new()
## The last hit on the player, for the "What got you" card (one record, reused; time -INF until the first).
var last_hit: HitFacts = HitFacts.new()
## The player's character id (-1: every character is a bot).
var _player_id: int = -1
## Round-robin start for the route queue, so no bot waits behind another twice.
var _next_route: int = 0
## The squad orders in force (built with the bots); the last order's outcome and the held spots' middle are its, read
## here by the presentation.
var orders: SquadOrderBook = null
var order_outcome: SquadOrders.Outcome:
	get:
		return orders.order_outcome
var held_middle: Vector3:
	get:
		return orders.held_middle


## Bots for every character in `state` but `player_id` (-1: everyone), on `map` with its nav grid and level rays, each
## team at its level in `team_levels` (team: a MatchOptions.BOT_LEVELS id; a team not in it plays Normal), each with its
## name and personality in `identities` (by character id, BotRoster.draw; a bot not in it has neither). Their first
## plan comes with the match's first ROUND_START (observe).
func _init(state: GameState, player_id: int, map: MapData, nav: NavGrid, query: WorldQuery, tuning: SimTuning,
		config: BotConfig, team_levels: Dictionary[int, StringName] = {},
		identities: Dictionary[int, BotRoster.Identity] = {}) -> void:
	_player_id = player_id
	var w := world
	w.tuning = tuning
	w.cfg = config
	w.nav = nav
	w.query = query
	NavVaults.link(nav, query, tuning.vault, tuning.body, config.vault_price)
	w.characters = state.characters
	w.lanes = map.lanes
	w.low_cover = BotCover.low_blocks(map, nav, config, tuning)
	w.tall_cover = BotCover.tall_blocks(map, nav, config, tuning)
	w.planner = RoundPlanner.new(state.match_seed)
	for c in state.characters:
		if c.id != player_id:
			var skill := config.skill_for(team_levels.get(c.team, &"normal"))
			var who: BotRoster.Identity = identities.get(c.id)
			if who != null:
				skill = BotPersonality.personal_skill(skill, who.style)
			var b := Bot.new(c, Seeds.bot_seed(state.match_seed, c.id), skill, state.characters.size())
			if who != null:
				b.bot_name = who.bot_name
				b.personality = who.personality
				b.style = who.style
			w.bots.append(b)
	_measure_field(map)
	w.setup_sectors(w.planner.bounds_lo, w.planner.bounds_hi)
	orders = SquadOrderBook.new(w)


## Writes each bot's command for this tick into `commands` (indexed by character id). With the Dev settings' Bots hold
## fire on (`state.cheats`), no bot pulls its trigger. First, a bot back from Regroup turns to Follow me.
func think(state: GameState, commands: Array[PlayerCommand], dt: float) -> void:
	var w := world
	w.time = state.time
	w.live = state.round_state.is_live()
	w.round_clock = state.round_state.clock
	_sync_round(state)
	orders.regroup_arrivals()
	for c in state.characters:
		if Elimination.is_in_play(c):
			w.mark_visited(c.team, c.position)
	_next_route = BotRoutes.plan(w, state.characters, _next_route)
	if w.mode == RoundState.Mode.ATTACK_DEFEND:
		# Retakers matter only once the flag is off the bottom (BotFlag.wants_flag).
		if w.flag.progress > 0.0:
			BotFlag.pick_retakers(w)
		BotFlag.pick_raiser(w)
	var hold_fire := state.cheats.bots_hold_fire
	# Who the weapon torches light, for this interval's looks (a night field only, WL7).
	BotTorch.refresh(w)
	for b in w.bots:
		var cmd := commands[b.character.id]
		BotBrain.think(b, w, cmd, dt)
		BotTorch.step(b, w, cmd)
		if hold_fire:
			cmd.fire = false


## What the bot driving `character_id` is doing (a Bot.Mode), or -1 when no bot drives it: the Dev settings' Bot
## intentions show it.
func mode_of(character_id: int) -> int:
	for b in world.bots:
		if b.character.id == character_id:
			return b.mode
	return -1


## The name of the bot driving `character_id`, or "" (no bot drives it, or it has no name).
func name_of(character_id: int) -> String:
	for b in world.bots:
		if b.character.id == character_id:
			return b.bot_name
	return ""


## The "What got you" card's line about the bot driving `character_id` (its personality's, with its name in), or ""
## (no bot drives it, or it has no name or no line).
func card_note_of(character_id: int) -> String:
	for b in world.bots:
		if b.character.id == character_id:
			if b.bot_name == "" or b.style.card_note == "":
				return ""
			return b.style.card_note.format({"name": b.bot_name})
	return ""


## What the bots heard in the step just taken (or the match's start), a hit on the player kept for "What got you", the
## squad orders given in it handed out (an order ends once its giver is out, and for a bot that is out), and a fresh plan
## when a round has started (no order outlasts a round).
func observe(state: GameState) -> void:
	BotHearing.observe(state, world)
	var events := state.events
	for i in events.count:
		var e := events.items[i]
		if e.kind == GameEvent.Kind.CHARACTER_HIT and e.target == _player_id and _player_id >= 0:
			_record_hit(state, e.actor, e.value == 1)
		elif e.kind == GameEvent.Kind.ROUND_START and e.value == 1 and state.round_state.draws == 0 and _player_id >= 0:
			# A new match: no hit on the player yet.
			last_hit.time = -INF
		elif e.kind == GameEvent.Kind.SQUAD_ORDER:
			orders.give_order(state.character(e.actor), e.value as SquadOrder.Kind, e.value2 == 1)
		elif e.kind == GameEvent.Kind.SQUAD_ORDER_REFUSED:
			orders.refused(e.actor)
	orders.update()
	if state.events.count_of(GameEvent.Kind.ROUND_START) > 0:
		_new_round(state)


## A squad order `kind` from `giver` to its bot teammates in play (SquadOrderBook.give_order); returns the order in
## force afterwards.
func give_order(giver: Character, kind: SquadOrder.Kind, from_wheel: bool = false) -> SquadOrder.Kind:
	return orders.give_order(giver, kind, from_wheel)


## The squad order in force from the character `giver_id` (NONE: its bot teammates play the team plan).
func order_of(giver_id: int) -> SquadOrder.Kind:
	return orders.order_of(giver_id)


## While the bot teammates of `giver_id` hold a spot it looked at: true, with the middle of the held spots in
## held_middle (SquadOrderBook.hold_spot).
func hold_spot(giver_id: int) -> bool:
	return orders.hold_spot(giver_id)


## Writes the hit on the player by `shooter_id` (with a bounced BB when `bounced`) into last_hit, with what the shooting
## bot knew: whether it was holding the angle and how long it had the player in view (from its contact). A teammate's
## BB, a bounced one or a shooter no bot drives leaves both unknown.
func _record_hit(state: GameState, shooter_id: int, bounced: bool) -> void:
	var victim := state.character(_player_id)
	var shooter := state.character(shooter_id)
	if victim == null or shooter == null:
		return
	var known := false
	var held := false
	var seen_for := -1.0
	if shooter.team != victim.team and not bounced:
		for b in world.bots:
			if b.character != shooter:
				continue
			known = true
			var c: Bot.Contact = b.contacts[_player_id] if _player_id < b.contacts.size() else null
			if c != null:
				held = c.held
				if is_finite(c.first_seen_at) and is_finite(c.seen_at):
					# Still in view, or until the moment the bot lost sight (a BB already in flight).
					var end := c.seen_at if state.time - c.seen_at > world.cfg.contact_grace else state.time
					seen_for = maxf(0.0, end - c.first_seen_at)
			break
	last_hit.record(state.time, victim, shooter, bounced, known, held, seen_for, world.cfg.hit_moving_speed)


func _new_round(state: GameState) -> void:
	orders.clear()
	world.time = state.time
	_sync_round(state)
	world.clear_sectors()
	world.planner.plan(world)


## The round's mode, attacking team and flag, from the sim's round state (the flag is the round state's own, read only).
func _sync_round(state: GameState) -> void:
	var rs := state.round_state
	world.mode = rs.mode
	world.attackers = rs.attackers
	world.flag = rs.flag


## The field's walkable extent (its sloping ground, floors and ramps) and a height over all of it, for drawing hunt
## spots.
func _measure_field(map: MapData) -> void:
	var p := world.planner
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var top := -INF
	var t := map.terrain
	if t != null:
		lo = Vector2(t.min_x, t.min_z)
		hi = Vector2(t.max_x(), t.max_z())
		top = t.height_range().y
	for b in map.blocks:
		top = maxf(top, b.center.y + b.size.y * 0.5)
		if b.kind != &"floor" and b.rise == MapData.Rise.NONE:
			continue
		lo.x = minf(lo.x, b.center.x - b.size.x * 0.5)
		lo.y = minf(lo.y, b.center.z - b.size.z * 0.5)
		hi.x = maxf(hi.x, b.center.x + b.size.x * 0.5)
		hi.y = maxf(hi.y, b.center.z + b.size.z * 0.5)
	if lo.x > hi.x:
		lo = Vector2.ZERO
		hi = Vector2.ZERO
	p.bounds_lo = lo
	p.bounds_hi = hi
	p.top_y = top + world.tuning.body.height
