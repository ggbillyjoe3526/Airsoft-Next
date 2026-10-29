class_name FoleyTracker
extends RefCounted
## Kit rustle from the body's movements (the browser game's audio/foley.ts, M92): read from each character's crouch and
## lean and their values a tick before, once per movement: a crouch, a stand or a lean away from upright starting, not
## every tick it goes on. Leaning back to upright is quiet; a lean starting within `lean_gap` (s) of that character's
## last lean rustle is quiet too (a lean against a wall restarts at each turn); anyone out of play is still. Presentation only: no event, so
## bots never hear a rustle (the sound pass plan's question 7). Putting the replica away is the HOLSTER event's sound.

## What started this tick, as flags in `moves`.
enum Move { NONE = 0, CROUCH = 1, STAND = 2, LEAN = 4 }

## Less change a tick than this (crouch 0..1, lean -1..1) counts as holding still.
const MOTION_EPSILON := 1e-4

## The least time (s) between one character's lean rustles (SoundConfig.foley_lean_gap).
var lean_gap: float = 0.0
## By place in the characters given: the Move flags that started this tick.
var moves: PackedInt32Array = PackedInt32Array()
## By place: which way the crouch and the lean's distance from upright went last tick (-1, 0 or 1).
var _crouch: PackedInt32Array = PackedInt32Array()
var _lean: PackedInt32Array = PackedInt32Array()
## By place: when (s) that character's last lean rustle started.
var _lean_at: PackedFloat64Array = PackedFloat64Array()


## Works out `moves` for `characters` at `now` (s), once a tick. The records are made when the cast's size changes
## (once a match).
func update(characters: Array[Character], now: float = 0.0) -> void:
	var n := characters.size()
	if n != moves.size():
		moves.resize(n)
		moves.fill(0)
		_crouch.resize(n)
		_crouch.fill(0)
		_lean.resize(n)
		_lean.fill(0)
		_lean_at.resize(n)
		_lean_at.fill(-INF)
	for i in n:
		var c := characters[i]
		var in_play := Elimination.is_in_play(c)
		var crouch := motion(c.crouch_amount, c.prev_crouch_amount) if in_play else 0
		var lean := motion(absf(c.lean), absf(c.prev_lean)) if in_play else 0
		var move: int = Move.NONE
		if crouch != 0 and crouch != _crouch[i]:
			move |= Move.CROUCH if crouch > 0 else Move.STAND
		# The lean growing in either direction is the start of a peek.
		if lean > 0 and _lean[i] <= 0 and now - _lean_at[i] >= lean_gap:
			move |= Move.LEAN
			_lean_at[i] = now
		moves[i] = move
		_crouch[i] = crouch
		_lean[i] = lean


## Which way a value went this tick: -1, 0 or 1.
static func motion(now: float, prev: float) -> int:
	var d := now - prev
	if d > MOTION_EPSILON:
		return 1
	if d < -MOTION_EPSILON:
		return -1
	return 0
