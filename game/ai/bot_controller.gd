class_name BotController
extends RefCounted
## Drives every character but the player (the browser game's ai/bot.ts updateBots): before each simulation step it
## plans at most one route (the nav search is the costly part, so bots queue for it), then writes each bot's
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
## What came of the last squad order given (one record, reused), and where the spots held for a giver are (hold_spot).
var order_outcome: SquadOrders.Outcome = SquadOrders.Outcome.new()
var held_middle: Vector3 = Vector3.ZERO
## Per giver (by character id), the squad order in force (one source for the presentation and for giving it again), and
## whether a Hold here in force was given looking at nothing, so each holds where it stood.
var _given: PackedInt32Array = PackedInt32Array()
var _own_spot: PackedByteArray = PackedByteArray()
## The teammates an order goes to, gathered afresh for each order given.
var _order_team: Array[Bot] = []


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
	_given.resize(state.characters.size())
	_own_spot.resize(state.characters.size())


## Writes each bot's command for this tick into `commands` (indexed by character id). With the Dev settings' Bots hold
## fire on (`state.cheats`), no bot pulls its trigger.
func think(state: GameState, commands: Array[PlayerCommand], dt: float) -> void:
	var w := world
	w.time = state.time
	w.live = state.round_state.is_live()
	w.round_clock = state.round_state.clock
	_sync_round(state)
	for c in state.characters:
		if Elimination.is_in_play(c):
			w.mark_visited(c.team, c.position)
	_plan_one_route(state)
	if w.mode == RoundState.Mode.ATTACK_DEFEND:
		# Retakers matter only once the flag is off the bottom (BotFlag.wants_flag).
		if w.flag.progress > 0.0:
			BotFlag.pick_retakers(w)
		BotFlag.pick_raiser(w)
	var hold_fire := state.cheats.bots_hold_fire
	for b in w.bots:
		var cmd := commands[b.character.id]
		BotBrain.think(b, w, cmd, dt)
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
			give_order(state.character(e.actor), e.value as SquadOrder.Kind, e.value2 == 1)
		elif e.kind == GameEvent.Kind.SQUAD_ORDER_REFUSED:
			order_outcome.record(e.actor, order_of(e.actor), SquadOrders.Notice.NOT_NOW)
	_update_orders()
	if state.events.count_of(GameEvent.Kind.ROUND_START) > 0:
		_new_round(state)


## A squad order `kind` from `giver` to its bot teammates in play (the browser game's BotController.giveOrder, M22),
## written into order_outcome. The order in force given again cancels it, except Hold here aimed somewhere else (at
## least hold_move from the held spot, or at nothing while they hold a spot looked at), which moves it; picked again on
## the order wheel (`from_wheel`) it stays instead. Team plan ends it. Returns the order in force afterwards (NONE also
## when no teammate is in play to take it).
func give_order(giver: Character, kind: SquadOrder.Kind, from_wheel: bool = false) -> SquadOrder.Kind:
	if giver == null or giver.id < 0 or giver.id >= _given.size() or kind == SquadOrder.Kind.NONE:
		return SquadOrder.Kind.NONE
	var before := order_of(giver.id)
	if kind == SquadOrder.Kind.TEAM_PLAN:
		_drop_order(giver)
		order_outcome.record(giver.id, SquadOrder.Kind.NONE,
				SquadOrders.Notice.CANCELLED if before != SquadOrder.Kind.NONE else SquadOrders.Notice.ON_PLAN)
		return SquadOrder.Kind.NONE
	var now := _hand_out(giver, kind, not from_wheel)
	var notice := SquadOrders.Notice.NONE
	if now == SquadOrder.Kind.NONE:
		notice = SquadOrders.Notice.CANCELLED if before != SquadOrder.Kind.NONE else SquadOrders.Notice.NOBODY
	order_outcome.record(giver.id, now, notice)
	return now


## The squad order in force from the character `giver_id` (NONE: its bot teammates play the team plan).
func order_of(giver_id: int) -> SquadOrder.Kind:
	if giver_id < 0 or giver_id >= _given.size():
		return SquadOrder.Kind.NONE
	return _given[giver_id] as SquadOrder.Kind


## While the bot teammates of `giver_id` hold a spot it looked at: true, with the middle of the held spots in
## held_middle. False for a hold where each stood (they may be far apart: no one spot to mark), and with no hold.
func hold_spot(giver_id: int) -> bool:
	if order_of(giver_id) != SquadOrder.Kind.HOLD or _own_spot[giver_id] == 1:
		return false
	var giver := _character(giver_id)
	if giver == null:
		return false
	held_middle = SquadOrders.held_centre(world.bots, giver)
	return SquadOrders.is_spot(held_middle)


## Hands `kind` out to `giver`'s bot teammates in play; `toggle`: the order in force given again cancels it (see
## give_order). Returns the order in force afterwards.
func _hand_out(giver: Character, kind: SquadOrder.Kind, toggle: bool) -> SquadOrder.Kind:
	var w := world
	var team := _order_team
	team.clear()
	for b in w.bots:
		if b.character != giver and b.character.team == giver.team and Elimination.is_in_play(b.character):
			team.append(b)
	if not Elimination.is_in_play(giver) or team.is_empty():
		_drop_order(giver)
		return SquadOrder.Kind.NONE
	var point := SquadOrders.hold_point(giver, w) if kind == SquadOrder.Kind.HOLD else SquadOrders.NO_SPOT
	var looked := SquadOrders.is_spot(point)
	if order_of(giver.id) == kind:
		var same := true
		if kind == SquadOrder.Kind.HOLD:
			var own := _own_spot[giver.id] == 1
			if looked:
				same = not own and hold_spot(giver.id) \
						and Vector2(point.x - held_middle.x, point.z - held_middle.z).length() < w.cfg.squad.hold_move
			else:
				same = own
		if same:
			if not toggle:
				return kind
			_drop_order(giver)
			return SquadOrder.Kind.NONE
	if kind == SquadOrder.Kind.HOLD:
		_sort_across_view(team, giver)
	for b in w.bots:
		if b.order_giver == giver and not team.has(b):
			SquadOrders.end(b, w)
	for slot in team.size():
		SquadOrders.start(team[slot], giver, kind, slot)
	if kind == SquadOrder.Kind.HOLD:
		SquadOrders.place_hold(team, giver, point, w)
	_given[giver.id] = kind
	_own_spot[giver.id] = 1 if kind == SquadOrder.Kind.HOLD and not looked else 0
	return kind


## Left to right across `giver`'s view, so nobody crosses another's path to their spot (an insertion sort: a squad is a
## handful, and it allocates nothing).
static func _sort_across_view(team: Array[Bot], giver: Character) -> void:
	var right := Vector2(cos(giver.yaw), -sin(giver.yaw))
	for i in range(1, team.size()):
		var b := team[i]
		var key := Vector2(b.character.position.x, b.character.position.z).dot(right)
		var j := i - 1
		while j >= 0 and Vector2(team[j].character.position.x, team[j].character.position.z).dot(right) > key:
			team[j + 1] = team[j]
			j -= 1
		team[j + 1] = b


## Everyone given `giver`'s order goes back to the team plan.
func _drop_order(giver: Character) -> void:
	for b in world.bots:
		if b.order_giver == giver:
			SquadOrders.end(b, world)
	_given[giver.id] = SquadOrder.Kind.NONE
	_own_spot[giver.id] = 0


## After each step: an order ends for a bot that is out, and for everyone given it once its giver is out (hit, or the
## round over) or nobody carries it any more.
func _update_orders() -> void:
	for b in world.bots:
		if b.order != SquadOrder.Kind.NONE and not Elimination.is_in_play(b.character):
			SquadOrders.end(b, world)
	for id in _given.size():
		if _given[id] == SquadOrder.Kind.NONE:
			continue
		var giver := _character(id)
		if giver == null or not Elimination.is_in_play(giver):
			if giver != null:
				_drop_order(giver)
			_given[id] = SquadOrder.Kind.NONE
			_own_spot[id] = 0
			continue
		var carried := false
		for b in world.bots:
			if b.order_giver == giver:
				carried = true
				break
		if not carried:
			_given[id] = SquadOrder.Kind.NONE
			_own_spot[id] = 0


## The character `id` of the field (a giver of orders), or null.
func _character(id: int) -> Character:
	for c in world.characters:
		if c.id == id:
			return c
	return null


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
	# No order outlasts a round (each bot's reset forgets its own).
	_given.fill(SquadOrder.Kind.NONE)
	_own_spot.fill(0)
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


## Plans the route of the next bot that wants one (round-robin), unless a walk-off route is waiting: the walk-off shares
## the tick's one search.
func _plan_one_route(state: GameState) -> void:
	var w := world
	for c in state.characters:
		if c.walk_off_route_pending:
			return
	var n := w.bots.size()
	for i in n:
		var b := w.bots[(_next_route + i) % n]
		if b.route_state != Bot.RouteState.WANTED or w.time < b.route_retry_at \
				or not Elimination.is_in_play(b.character):
			continue
		_next_route = (_next_route + i + 1) % n
		var from := b.character.position
		if w.nav.find_route(from, b.route_goal, b.route, w.time >= b.vaults_off_until):
			b.route_state = Bot.RouteState.OK
			b.route_from = from
			b.route_leg = 0
			b.stuck_for = 0.0
		else:
			b.route.clear()
			b.route_state = Bot.RouteState.FAILED
			b.route_retry_at = w.time + w.cfg.route_retry_delay
		return


## The field's walkable extent (its floors and ramps) and a height over all of it, for drawing hunt spots.
func _measure_field(map: MapData) -> void:
	var p := world.planner
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var top := -INF
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
