class_name GameState
extends RefCounted
## The whole simulation's state as plain data (the browser game's sim/state.ts). Presentation reads it and the tick's
## events; it never writes them.

var tick: int = 0
## Seconds of simulated time.
var time: float = 0.0
## The seed the match was started with: the same seed and the same commands replay the same match.
var match_seed: int = 0
var characters: Array[Character] = []
var bbs: BBPool = null
## What happened during the last tick (shots, hits, rounds). Cleared at the start of every tick.
var events: SimEvents = SimEvents.new()
## The match's own random stream: shot spread and anything else random in the rules.
var rng: RandomNumberGenerator = null
var round_state: RoundState = null


func _init(seed_value: int = 0, tuning: SimTuning = null) -> void:
	var t := tuning if tuning != null else SimTuning.new()
	match_seed = seed_value & Seeds.MASK_32
	rng = Seeds.stream(match_seed)
	bbs = BBPool.new(t.ballistics.max_bbs)
	round_state = RoundState.new()


## The character with `character_id`, or null.
func character(character_id: int) -> Character:
	for c in characters:
		if c.id == character_id:
			return c
	return null
