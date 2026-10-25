class_name Callouts
extends RefCounted
## The bots' callouts (the browser game's ai/callouts.ts, CL1): after each tick, what the bots just did put into words
## for their team, as data/callouts.md says ("Contact, Dock!", "Two left!"). BotController.observe runs it after the
## bots have heard the tick. It reads the bots and the state and never writes either, and draws on a seeded stream of its
## own (Seeds.callout_seed), so callouts never change how anyone plays. What it says goes into `said` (CalloutLog) for
## the presentation; it shows nothing itself.
##
## Each tick, every event a bot calls is offered for its team: kept only outside its team gap, its speaker's gap and,
## for a sighting, the same enemy's gap, then rolled against its chance (× the personality's Talks). The team says one
## call at a time, at least Pace's team gap apart, the most urgent first (higher in When they call): the others wait in
## a short queue (CalloutConfig.queue, the least urgent dropped when it is full), each dropped after Pace's wait, or when
## a gap it waited through now stops it. Hit players never talk. Tagged (Extraction), the overtime flag, the answers
## to a ping and the magazine hand-off are read from the file but not raised yet: their systems raise them.

const TEAMS := 2
## The events any teammate may say (the one nearest to where it happened), not only the bot it happened to: its own
## gap doesn't hold one back.
const TEAM_EVENTS: Array[int] = [
	CalloutsFile.Event.DOWN, CalloutsFile.Event.LAST_ONE, CalloutsFile.Event.TAGGED, CalloutsFile.Event.RAISING,
	CalloutsFile.Event.FLAG, CalloutsFile.Event.OVERTIME, CalloutsFile.Event.PING_GOING,
	CalloutsFile.Event.PING_WATCHING,
]
## The answers to a player's ping and the asks and answers for a magazine: a personality's Talks (×) never makes them
## less likely.
const ANSWERS: Array[int] = [
	CalloutsFile.Event.PING_GOING, CalloutsFile.Event.PING_WATCHING, CalloutsFile.Event.NEED_MAG,
	CalloutsFile.Event.MAG_COMING,
]
## The events that say how many are left: a newer hit makes any still waiting out of date.
const COUNTS: Array[int] = [CalloutsFile.Event.DOWN, CalloutsFile.Event.LAST_ONE, CalloutsFile.Event.TAGGED]


## A call waiting for its team's gap: the event, the bot (index into the bots), what its line fills in, the enemy a
## sighting is of (character index, or -1) and the time it is dropped at (-INF: the place is free).
class Pending:
	extends RefCounted
	var event: int = 0
	var priority: int = 0
	var bot: int = -1
	var area: String = ""
	var count: int = 0
	var left: int = 0
	var enemy: int = -1
	var until: float = -INF


## Per team: when it last said anything and each event, when it last called each enemy (by character index), the last
## noise it called and where, and its queue.
class TeamTalk:
	extends RefCounted
	var said_at: float = -INF
	var event_at: PackedFloat64Array = PackedFloat64Array()
	var enemy_at: PackedFloat64Array = PackedFloat64Array()
	var heard_area: String = ""
	var heard_at: float = -INF
	var queue: Array[Pending] = []


## The calls said, for the presentation.
var said: CalloutLog = null
var _file: CalloutsFile = null
var _cfg: CalloutConfig = null
var _areas: Array[MapAreas.Area] = []
var _rng: RandomNumberGenerator = null
var _teams: Array[TeamTalk] = []
## Per bot (index into the bots): when it last spoke, its mode and whether it was at its post last tick, and whether it
## called its hold this round.
var _said_at: PackedFloat64Array = PackedFloat64Array()
var _last_mode: PackedInt32Array = PackedInt32Array()
var _was_at_post: PackedByteArray = PackedByteArray()
var _held_called: PackedByteArray = PackedByteArray()
## Per bot and character (bot × characters + character index): the start of the last sighting looked at.
var _first_seen: PackedFloat64Array = PackedFloat64Array()
var _characters: int = 0
var _now: float = 0.0


## A director playing `file` with `cfg`'s numbers on a map named by `areas` (MapData.areas), its stream from the match
## seed `seed_value`.
func _init(file: CalloutsFile, cfg: CalloutConfig, areas: Array[MapAreas.Area], seed_value: int) -> void:
	_file = file
	_cfg = cfg
	_areas = areas
	_rng = Seeds.stream(Seeds.callout_seed(seed_value))
	said = CalloutLog.new(cfg.log_size)
	for t in TEAMS:
		var talk := TeamTalk.new()
		talk.event_at.resize(CalloutsFile.Event.size())
		talk.event_at.fill(-INF)
		for k in maxi(1, cfg.queue):
			talk.queue.append(Pending.new())
		_teams.append(talk)


## After a simulation step and the bots' hearing of it (BotController.observe), while its events are still in the state.
func observe(state: GameState, w: BotWorld) -> void:
	_now = state.time
	var bots := w.bots
	if _said_at.size() != bots.size() or _characters != state.characters.size():
		_size(state, bots)
	var live := state.round_state.is_live()
	var events := state.events
	for n in events.count:
		var e := events.items[n]
		if e.kind == GameEvent.Kind.ROUND_START:
			_reset()
		elif live:
			_on_event(e, state, bots)
	if live:
		for i in bots.size():
			_watch(i, state, w)
	for t in TEAMS:
		_flush(t, state, bots, live)
	for i in bots.size():
		_last_mode[i] = bots[i].mode
		_was_at_post[i] = 1 if bots[i].at_post else 0


## The name of the area at `p` ("" outside every one, or on a map without names).
func area_of(p: Vector3) -> String:
	return MapAreas.area_at(_areas, p)


## Sizes the memory for these bots and characters (once; again only if either changes).
func _size(state: GameState, bots: Array[Bot]) -> void:
	var n := state.characters.size()
	_characters = n
	_said_at.resize(bots.size())
	_said_at.fill(-INF)
	_first_seen.resize(bots.size() * n)
	_first_seen.fill(NAN)
	_last_mode.resize(bots.size())
	_was_at_post.resize(bots.size())
	_held_called.resize(bots.size())
	_held_called.fill(0)
	for i in bots.size():
		_last_mode[i] = bots[i].mode
		_was_at_post[i] = 1 if bots[i].at_post else 0
	for talk in _teams:
		talk.enemy_at.resize(n)
		talk.enemy_at.fill(-INF)


## A new round: nothing waits, nothing was called.
func _reset() -> void:
	for talk in _teams:
		talk.said_at = -INF
		talk.event_at.fill(-INF)
		talk.enemy_at.fill(-INF)
		talk.heard_area = ""
		talk.heard_at = -INF
		for p in talk.queue:
			p.until = -INF
	_said_at.fill(-INF)
	_held_called.fill(0)


## What one of this tick's events gives to call: a hit, a reload, the flag going up.
func _on_event(e: GameEvent, state: GameState, bots: Array[Bot]) -> void:
	match e.kind:
		GameEvent.Kind.CHARACTER_HIT:
			_on_hit(e, state, bots)
		GameEvent.Kind.RELOAD_START:
			var i := _bot_index(bots, e.actor)
			if i < 0 or not Elimination.is_in_play(bots[i].character):
				return
			var b := bots[i]
			if _now - maxf(b.last_threat_at, b.last_seen_at()) <= _cfg.reload_threat:
				_offer(b.character.team, CalloutsFile.Event.RELOADING, i, bots, "", 0, 0, -1)
		GameEvent.Kind.FLAG_ROPE:
			var attackers := state.round_state.attackers
			if e.value != 1 or attackers < 0 or attackers >= TEAMS:
				return
			_offer_from_team(attackers, CalloutsFile.Event.RAISING, -1, e.position, bots, "", 0, 0)
			_offer_from_team(1 - attackers, CalloutsFile.Event.FLAG, -1, e.position, bots, "", 0, 0)


## A hit on the other team: Down with how many are left, or Last one (naming where when the team saw them lately),
## said by the shooter or the teammate nearest to it.
func _on_hit(e: GameEvent, state: GameState, bots: Array[Bot]) -> void:
	var victim := state.character(e.target)
	var shooter := state.character(e.actor)
	if victim == null or shooter == null or victim.team == shooter.team or shooter.team < 0 or shooter.team >= TEAMS:
		return
	# A newer hit makes a count still waiting out of date ("Two left" when one is).
	for p in _teams[shooter.team].queue:
		if COUNTS.has(p.event):
			p.until = -INF
	var chars := state.characters
	var left := 0
	var last := -1
	for k in chars.size():
		if chars[k].team == victim.team and Elimination.is_in_play(chars[k]):
			left += 1
			last = k
	if left == 0:
		return # the round is over
	var event := CalloutsFile.Event.LAST_ONE if left == 1 else CalloutsFile.Event.DOWN
	var area := ""
	if event == CalloutsFile.Event.LAST_ONE and _team_saw(shooter.team, chars[last], bots):
		area = area_of(chars[last].position)
	_offer_from_team(shooter.team, event, _bot_index(bots, shooter.id), shooter.position, bots, area, 0, left)


## What bot `i` is doing now that it calls: a fresh sighting, a noise, a search setting off, a hold settled.
func _watch(i: int, state: GameState, w: BotWorld) -> void:
	var bots := w.bots
	var b := bots[i]
	var me := b.character
	if not Elimination.is_in_play(me):
		return
	var t := me.team
	if t < 0 or t >= TEAMS:
		return
	var talk := _teams[t]
	var pace := _file.pace
	var chars := state.characters
	# Sightings: how many enemies it sees, and the first of them freshly seen that its team hasn't called lately. Sight
	# stamps last_threat_at with every contact it stamps, so a bot with no threat since in_sight sees no one.
	var seen := 0
	var fresh := -1
	var looks := _now - b.last_threat_at <= _cfg.in_sight
	for k in chars.size() if looks else 0:
		var c := chars[k]
		if c.team == t or not Elimination.is_in_play(c) or c.id < 0 or c.id >= b.contacts.size():
			continue
		var contact := b.contacts[c.id]
		if contact == null or _now - contact.seen_at > _cfg.in_sight:
			continue
		seen += 1
		var slot := i * _characters + k
		if contact.first_seen_at == _first_seen[slot]:
			continue
		_first_seen[slot] = contact.first_seen_at
		if fresh < 0 and _now - talk.enemy_at[k] >= pace.same_enemy_gap:
			fresh = k
	if fresh >= 0:
		var event := CalloutsFile.Event.CONTACTS if seen >= 2 else CalloutsFile.Event.CONTACT
		_offer(t, event, i, bots, area_of(chars[fresh].position), seen, 0, fresh)
	# A noise heard in this tick's hearing (stamped with the bots' time), while nobody on the team has anyone in sight.
	if b.heard_at == w.time and b.has_last_known and seen == 0 and not _team_sees(t, bots):
		var area := area_of(b.last_known)
		if area != talk.heard_area or _now - talk.heard_at >= pace.same_enemy_gap:
			_offer(t, CalloutsFile.Event.HEARD, i, bots, area, 0, 0, -1)
	# Setting off to where someone was.
	if b.mode == Bot.Mode.SEARCH and _last_mode[i] != Bot.Mode.SEARCH:
		var event := CalloutsFile.Event.CHECKING
		if BotPersonality.pushes_in(b):
			event = CalloutsFile.Event.PUSHING
		elif b.flanking:
			event = CalloutsFile.Event.FLANKING
		_offer(t, event, i, bots, area_of(b.last_known), 0, 0, -1)
	# Settled at the spot it holds: once a round, whether it says so or not.
	if b.at_post and _was_at_post[i] == 0 and _held_called[i] == 0:
		_held_called[i] = 1
		_offer(t, CalloutsFile.Event.HOLDING, i, bots, area_of(me.position), 0, 0, -1)


## Whether any bot on `team` has an enemy in sight now.
func _team_sees(team: int, bots: Array[Bot]) -> bool:
	for b in bots:
		if b.character.team == team and Elimination.is_in_play(b.character) and b.target_visible:
			return true
	return false


## Whether a bot on `team` saw `enemy` within CalloutConfig.last_one_seen.
func _team_saw(team: int, enemy: Character, bots: Array[Bot]) -> bool:
	for b in bots:
		if b.character.team != team or enemy.id < 0 or enemy.id >= b.contacts.size():
			continue
		var contact := b.contacts[enemy.id]
		if contact != null and _now - contact.seen_at <= _cfg.last_one_seen:
			return true
	return false


## A team event (a hit, the flag): said by bot `own` if it may speak, else by the team's bot nearest `at` that may (in
## play and outside its own gap).
func _offer_from_team(team: int, event: int, own: int, at: Vector3, bots: Array[Bot], area: String, count: int,
		left: int) -> void:
	var speaker := own if own >= 0 and _may_speak(own, bots) else -1
	if speaker < 0:
		var best := INF
		for i in bots.size():
			var c := bots[i].character
			if c.team != team or not _may_speak(i, bots):
				continue
			var d := Vector2(c.position.x - at.x, c.position.z - at.z).length()
			if d < best:
				best = d
				speaker = i
	if speaker >= 0:
		_offer(team, event, speaker, bots, area, count, left, -1)


## Bot `i` is in play and outside its own gap.
func _may_speak(i: int, bots: Array[Bot]) -> bool:
	return Elimination.is_in_play(bots[i].character) and _now - _said_at[i] >= _file.pace.bot_gap


## Offers bot `i`'s call of `event` to its team: kept if no gap stops it and its chance comes up, in a free place in
## the queue or in place of a less urgent call.
func _offer(team: int, event: int, i: int, bots: Array[Bot], area: String, count: int, left: int, enemy: int) -> void:
	var rule := _file.rules[event]
	var b := bots[i]
	var talk := _teams[team]
	if rule.chance <= 0.0 or not _allowed(talk, event, i, bots, area, enemy):
		return
	if _line_count(event, b.personality, area) == 0:
		return
	# The place it takes: a free one, else the least urgent call's if this one is more urgent.
	var slot: Pending = null
	for p in talk.queue:
		if p.until < _now:
			slot = p
		elif slot == null or (slot.until >= _now and p.priority > slot.priority):
			slot = p
	if slot == null or (slot.until >= _now and slot.priority <= rule.priority):
		return
	var talks: float = 1.0 if ANSWERS.has(event) else _file.talks.get(b.personality, 1.0)
	var chance := minf(1.0, rule.chance * talks)
	if chance < 1.0 and _rng.randf() >= chance:
		return
	slot.event = event
	slot.priority = rule.priority
	slot.bot = i
	slot.area = area
	slot.count = count
	slot.left = left
	slot.enemy = enemy
	slot.until = _now + _file.pace.max_wait


## Whether no gap stops `event` by bot `i` now: its team gap, the bot's own (but for a team event), the enemy's or the
## noise's.
func _allowed(talk: TeamTalk, event: int, i: int, bots: Array[Bot], area: String, enemy: int) -> bool:
	var pace := _file.pace
	if _now - talk.event_at[event] < _file.rules[event].team_gap:
		return false
	if TEAM_EVENTS.has(event):
		if not Elimination.is_in_play(bots[i].character):
			return false
	elif not _may_speak(i, bots):
		return false
	if enemy >= 0 and _now - talk.enemy_at[enemy] < pace.same_enemy_gap:
		return false
	return event != CalloutsFile.Event.HEARD or area != talk.heard_area or _now - talk.heard_at >= pace.same_enemy_gap


## Says team `t`'s most urgent waiting call once its team gap has passed. A call too old, or one a gap now stops (its
## caller hit, or a teammate called the same since), goes.
func _flush(t: int, state: GameState, bots: Array[Bot], live: bool) -> void:
	var talk := _teams[t]
	var ready := _now - talk.said_at >= _file.pace.team_gap
	var next: Pending = null
	for p in talk.queue:
		if p.until < _now:
			continue
		if not live or p.bot < 0 or p.bot >= bots.size() or not Elimination.is_in_play(bots[p.bot].character) \
				or (ready and not _allowed(talk, p.event, p.bot, bots, p.area, p.enemy)):
			p.until = -INF
			continue
		if next == null or p.priority < next.priority:
			next = p
	if not ready or next == null:
		return
	next.until = -INF
	var b := bots[next.bot]
	var text := _line(next.event, b.personality, next.area, next.count, next.left)
	if text == "":
		return
	talk.said_at = _now
	talk.event_at[next.event] = _now
	_said_at[next.bot] = _now
	if next.event == CalloutsFile.Event.HEARD:
		talk.heard_area = next.area
		talk.heard_at = _now
	# A sighting calls every enemy the speaker sees now, so a teammate doesn't call the same ones again.
	if next.event == CalloutsFile.Event.CONTACT or next.event == CalloutsFile.Event.CONTACTS:
		var chars := state.characters
		for k in chars.size():
			var c := chars[k]
			var contact: Bot.Contact = b.contacts[c.id] if c.id >= 0 and c.id < b.contacts.size() else null
			if k == next.enemy or (contact != null and c.team != t and _now - contact.seen_at <= _cfg.in_sight):
				talk.enemy_at[k] = _now
	said.add(b.character.id, t, next.event as CalloutsFile.Event, text, _now)


## How many of `event`'s lines a bot of `personality` can say, with `area` named or not ("" leaves out {area} lines).
func _line_count(event: int, personality: StringName, area: String) -> int:
	var n := 0
	for l: CalloutsFile.Line in _file.lines[event]:
		if _fits(l, personality, area):
			n += 1
	return n


## One of those lines at random, filled in ("" when there is none).
func _line(event: int, personality: StringName, area: String, count: int, left: int) -> String:
	var n := _line_count(event, personality, area)
	if n == 0:
		return ""
	var k := _rng.randi_range(0, n - 1)
	for l: CalloutsFile.Line in _file.lines[event]:
		if not _fits(l, personality, area):
			continue
		if k == 0:
			return l.filled(area, count, left)
		k -= 1
	return ""


## Whether a bot of `personality` can say line `l` with `area` named or not: its own or Any's, and {area} only with one.
static func _fits(l: CalloutsFile.Line, personality: StringName, area: String) -> bool:
	return (l.who == &"" or l.who == personality) and (area != "" or not l.needs_area)


## The index among the bots of the bot playing character `id`, or -1.
static func _bot_index(bots: Array[Bot], id: int) -> int:
	for i in bots.size():
		if bots[i].character.id == id:
			return i
	return -1
