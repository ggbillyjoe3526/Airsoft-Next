class_name AmbientCalls
extends RefCounted
## A field's calls (the browser game's audio/ambience.ts AmbientCalls, M86): each kind of call (AmbienceCall: a bird, a
## dog, a horn) now and then on its own seeded gaps, somewhere round the listener at a random bearing and its distance,
## at its height. Timed on the simulation's clock, each kind from its own generator seeded from its rng_seed and the
## match's (presentation only, never the match's stream): the same seeds give the same calls, and each rematch new ones.
## Generators are made once; `begin` reseeds them.

## Keeps each rematch's calls apart (an arbitrary prime, as Seeds' per-match offsets).
const PER_MATCH := 1597334677

var calls: Array[AmbienceCall] = []
## Where the last call that came due sounds (written by `due` only then).
var at: Vector3 = Vector3.ZERO
var _rng: Array[RandomNumberGenerator] = []
var _next: PackedFloat64Array = PackedFloat64Array()


func _init(kinds: Array[AmbienceCall]) -> void:
	calls = kinds
	_next.resize(kinds.size())
	for i in kinds.size():
		_rng.append(RandomNumberGenerator.new())
	begin(0, 1, 0.0)


## The seed call `kind` is timed from in match `match_number` (1 for the first) of a state seeded with `match_seed`:
## the browser's call seed XOR the match's, moved on for each rematch.
static func seed_for(kind: AmbienceCall, match_seed: int, match_number: int) -> int:
	return Seeds.derive(match_seed ^ kind.rng_seed, 1, ((match_number - 1) * PER_MATCH) & Seeds.MASK_32)


## Starts the calls' timing afresh at `now` (s) for match `match_number` of a state seeded with `match_seed`.
func begin(match_seed: int, match_number: int, now: float) -> void:
	for i in calls.size():
		_rng[i].seed = seed_for(calls[i], match_seed, match_number)
		_next[i] = now + _gap(i)


## The number of kinds of call.
func size() -> int:
	return calls.size()


## Whether call `i` sounds at `now` (s); `at` is then where, round `listener` (the ears it is heard by).
func due(i: int, now: float, listener: Vector3) -> bool:
	if now < _next[i]:
		return false
	var kind := calls[i]
	var rng := _rng[i]
	_next[i] = now + _gap(i)
	var d := lerpf(kind.distance_min, kind.distance_max, rng.randf())
	var bearing := rng.randf() * TAU
	at = Vector3(listener.x + cos(bearing) * d, kind.height, listener.z + sin(bearing) * d)
	return true


## When call `i` next sounds (s, on the clock `begin` and `due` were given).
func next_at(i: int) -> float:
	return _next[i]


func _gap(i: int) -> float:
	return lerpf(calls[i].gap_min, calls[i].gap_max, _rng[i].randf())
