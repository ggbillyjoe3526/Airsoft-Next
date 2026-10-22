class_name BotController
extends RefCounted
## Drives every character but the player (the browser game's ai/bot.ts updateBots): before each simulation step it
## plans at most one route (the nav search is the costly part, so bots queue for it), then writes each bot's
## PlayerCommand; after the step it lets the bots hear what happened and gives each new round a fresh plan. Bots are
## just another controller: they act only through their commands (ARCHITECTURE contract 2). Pure: no nodes.

var world: BotWorld = BotWorld.new()
## Round-robin start for the route queue, so no bot waits behind another twice.
var _next_route: int = 0


## Bots for every character in `state` but `player_id` (-1: everyone), on `map` with its nav grid and level rays, each
## team at its level in `team_levels` (team: a MatchOptions.BOT_LEVELS id; a team not in it plays Normal), each with its
## name and personality in `identities` (by character id, BotRoster.draw; a bot not in it has neither). Their first
## plan comes with the match's first ROUND_START (observe).
func _init(state: GameState, player_id: int, map: MapData, nav: NavGrid, query: WorldQuery, tuning: SimTuning,
		config: BotConfig, team_levels: Dictionary[int, StringName] = {},
		identities: Dictionary[int, BotRoster.Identity] = {}) -> void:
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


## What the bots heard in the step just taken (or the match's start), and a fresh plan when a round has started.
func observe(state: GameState) -> void:
	BotHearing.observe(state, world)
	if state.events.count_of(GameEvent.Kind.ROUND_START) > 0:
		_new_round(state)


func _new_round(state: GameState) -> void:
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
