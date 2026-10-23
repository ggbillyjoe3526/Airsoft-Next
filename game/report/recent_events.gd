class_name RecentEvents
extends RefCounted
## The last game events (SV4), for a bug report: "what happened just before" that players can't describe. Everyone's
## shots and hits (a hit is the call: one BB, out), the player's reloads, draws, dry fires and squad orders, and the
## round's start and end; the rest (footsteps, impacts, the flag's rope) would bury them. A fixed PackedInt32Array ring,
## filled from each tick's events with no allocation once made; formatted only when a report is made (`lines`). A burst
## of one character's shots from one replica counts up one entry. The browser game's core/eventLog.ts.

## One entry's ints in the ring, in this order.
const TICK := 0
## The newest tick a counted-up entry (a burst) took in.
const LAST := 1
const KIND := 2
const ACTOR := 3
const TARGET := 4
const SLOT := 5
const VALUE := 6
const VALUE2 := 7
const COUNT := 8
const STRIDE := 9
## What an entry says for the kind, where the enum's own name would read badly.
const HIT_WORD := "HIT"
const PLAYER_WORD := "You"
const DRAW_WORD := "a draw"

var config: ReportConfig = null
var _ring := PackedInt32Array()
var _capacity: int = 0
## The slot the next entry takes, and how many are filled.
var _next: int = 0
var _filled: int = 0


func _init(report: ReportConfig = null) -> void:
	config = report if report != null else ReportConfig.new()
	_capacity = maxi(1, config.events)
	_ring.resize(_capacity * STRIDE)


## The tick's events (`tick` the one just stepped), for the player `player_id`.
func record(tick: int, events: SimEvents, player_id: int) -> void:
	for i in events.count:
		var e := events.items[i]
		match e.kind:
			GameEvent.Kind.SHOT:
				var at := _burst_of(e.actor, e.slot, tick)
				if at >= 0:
					_ring[at + COUNT] += 1
					_ring[at + LAST] = tick
				else:
					_take(e, tick)
			GameEvent.Kind.CHARACTER_HIT, GameEvent.Kind.RICOCHET_TICK, GameEvent.Kind.ROUND_START, \
					GameEvent.Kind.ROUND_OVER, GameEvent.Kind.MATCH_OVER:
				_take(e, tick)
			GameEvent.Kind.RELOAD_START, GameEvent.Kind.RELOAD_END, GameEvent.Kind.RELOAD_REFUSED, \
					GameEvent.Kind.DRAW, GameEvent.Kind.DRY_FIRE, GameEvent.Kind.TARGET_HIT, GameEvent.Kind.SQUAD_ORDER:
				if e.actor == player_id:
					_take(e, tick)


## How many entries are kept (up to the ring's size).
func size() -> int:
	return _filled


## Forgets every entry (the ring stays).
func clear() -> void:
	_next = 0
	_filled = 0


## Each entry as a report gives it, oldest first: "t11402 Beta 2 SHOT ×4 GBB Pistol". `state` names the characters
## and their replicas (null: by number only). Allocates; only when a report is made.
func lines(state: GameState, player_id: int) -> PackedStringArray:
	var out := PackedStringArray()
	for i in _filled:
		var at := ((_next - _filled + i + _capacity) % _capacity) * STRIDE
		out.append("t%d %s" % [_ring[at + TICK], _describe(at, state, player_id)])
	return out


## The ring's ints for the entry at `index` (0 the oldest): for tests.
func entry(index: int) -> PackedInt32Array:
	var at := ((_next - _filled + index + _capacity) % _capacity) * STRIDE
	return _ring.slice(at, at + STRIDE)


## The ring's offset of `actor`'s newest shot entry from `slot` that took a tick within burst_ticks of `tick`,
## looking back past other shots only (two players trading shots count up an entry each; a hit or a round ends it);
## -1 when there is none.
func _burst_of(actor: int, slot: int, tick: int) -> int:
	for back in mini(_filled, config.look_back):
		var at := ((_next - 1 - back + _capacity) % _capacity) * STRIDE
		if _ring[at + KIND] != GameEvent.Kind.SHOT:
			return -1
		if _ring[at + ACTOR] == actor:
			var same := _ring[at + SLOT] == slot and tick - _ring[at + LAST] <= config.burst_ticks
			return at if same else -1
	return -1


func _take(e: GameEvent, tick: int) -> void:
	var at := _next * STRIDE
	_ring[at + TICK] = tick
	_ring[at + LAST] = tick
	_ring[at + KIND] = e.kind
	_ring[at + ACTOR] = e.actor
	_ring[at + TARGET] = e.target
	_ring[at + SLOT] = e.slot
	_ring[at + VALUE] = e.value
	_ring[at + VALUE2] = e.value2
	_ring[at + COUNT] = 1
	_next = (_next + 1) % _capacity
	_filled = mini(_filled + 1, _capacity)


func _describe(at: int, state: GameState, player_id: int) -> String:
	var kind := _ring[at + KIND] as GameEvent.Kind
	var word: String = GameEvent.Kind.keys()[kind]
	var who := _who(_ring[at + ACTOR], state, player_id)
	match kind:
		GameEvent.Kind.SHOT:
			var count := _ring[at + COUNT]
			var times := " ×%d" % count if count > 1 else ""
			return "%s %s%s %s" % [who, word, times, _replica(at, state)]
		GameEvent.Kind.CHARACTER_HIT:
			return "%s %s %s" % [who, HIT_WORD, _who(_ring[at + TARGET], state, player_id)]
		GameEvent.Kind.RICOCHET_TICK:
			return "%s %s %s" % [who, word, _who(_ring[at + TARGET], state, player_id)]
		GameEvent.Kind.TARGET_HIT:
			return "%s %s %d" % [who, word, _ring[at + TARGET]]
		GameEvent.Kind.SQUAD_ORDER:
			return "%s %s %s" % [who, word, _enum_word(SquadOrder.Kind.keys(), _ring[at + VALUE])]
		GameEvent.Kind.ROUND_START:
			return "%s %d" % [word, _ring[at + VALUE]]
		GameEvent.Kind.ROUND_OVER:
			var reason := _enum_word(GameEvent.RoundEnd.keys(), _ring[at + VALUE2])
			return "%s %s (%s)" % [word, _team_won(_ring[at + VALUE]), reason]
		GameEvent.Kind.MATCH_OVER:
			return "%s %s" % [word, _team_won(_ring[at + VALUE])]
	return "%s %s %s" % [who, word, _replica(at, state)]


## "You" for the player, else the team and the character's number ("Beta 2"); "#4" for one not in the match.
func _who(id: int, state: GameState, player_id: int) -> String:
	if id == player_id:
		return PLAYER_WORD
	var c := state.character(id) if state != null and id >= 0 else null
	if c == null:
		return "#%d" % id
	return "%s %d" % [_team(c.team), id]


func _replica(at: int, state: GameState) -> String:
	var slot := _ring[at + SLOT]
	var actor := _ring[at + ACTOR]
	var c := state.character(actor) if state != null and actor >= 0 else null
	if c == null or c.armament == null or slot < 0 or slot >= c.armament.replicas.size():
		return "slot %d" % slot
	return c.armament.replicas[slot].display_name


func _team(team: int) -> String:
	return config.team_names[team] if team >= 0 and team < config.team_names.size() else "Team %d" % team


func _team_won(team: int) -> String:
	return _team(team) if team >= 0 else DRAW_WORD


static func _enum_word(keys: Array, value: int) -> String:
	return str(keys[value]) if value >= 0 and value < keys.size() else str(value)
