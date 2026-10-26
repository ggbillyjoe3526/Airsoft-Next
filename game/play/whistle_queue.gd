class_name WhistleQueue
extends RefCounted
## The referee's blasts waiting their turn (the browser game's whistle.ts and its round, match and Time cases), in a
## fixed queue sized at setup for the longest pattern: a round starts on two short blasts, Elimination's overtime flag
## goes up on three quick short ones, a round ends on one long, the match ends on three more long after it (SoundConfig's
## whistle pattern). A round's end drops any overtime blasts still waiting (a round won the tick after the flag goes
## up), so its long blast and the match's are never cut by them. A new round's whistle cuts whatever is left,
## as the referee's next call. Plain: SimAudio plays what `pop_due` hands it on its one whistle voice.

enum Blast { NONE = -1, SHORT, LONG }

var _cfg: SoundConfig = null
## Start times (s) and blasts, oldest first; `_count` of them are waiting.
var _at: PackedFloat64Array = PackedFloat64Array()
var _blast: PackedInt32Array = PackedInt32Array()
var _count: int = 0


func _init(cfg: SoundConfig) -> void:
	_cfg = cfg
	# The longest pattern (a round's start, or the overtime's blasts with a round's and the match's end), and the
	# range's Time on top.
	var room := maxi(cfg.round_start_blasts, cfg.overtime_blasts + 1 + cfg.match_over_blasts) + 1
	_at.resize(room)
	_blast.resize(room)


## How many blasts are waiting.
func waiting() -> int:
	return _count


## A round starts at `now` (s): whatever was still waiting is cut, and the short blasts queued.
func round_start(now: float) -> void:
	_count = 0
	for i in _cfg.round_start_blasts:
		_add(now + _cfg.round_start_blast(i), Blast.SHORT)


## Elimination's overtime flag goes up at `now` (s): the quick short blasts.
func overtime(now: float) -> void:
	for i in _cfg.overtime_blasts:
		_add(now + _cfg.overtime_blast(i), Blast.SHORT)


## A round ends at `now` (s), or the range's Time is up: one long blast; short blasts still waiting are dropped.
func round_over(now: float) -> void:
	_drop_short()
	_add(now, Blast.LONG)


## The match ends with the round that ended at `now` (s): the long blasts after the round's (short ones dropped).
func match_over(now: float) -> void:
	_drop_short()
	for i in _cfg.match_over_blasts:
		_add(now + _cfg.match_over_blast(i), Blast.LONG)


## Forgets every blast waiting.
func clear() -> void:
	_count = 0


## The first blast due at `now` (s), taken off the queue, or NONE.
func pop_due(now: float) -> Blast:
	if _count == 0 or _at[0] > now:
		return Blast.NONE
	var blast := _blast[0] as Blast
	for i in range(1, _count):
		_at[i - 1] = _at[i]
		_blast[i - 1] = _blast[i]
	_count -= 1
	return blast


## Takes every short blast still waiting off the queue, keeping the rest in order.
func _drop_short() -> void:
	var k := 0
	for i in _count:
		if _blast[i] != Blast.SHORT:
			_at[k] = _at[i]
			_blast[k] = _blast[i]
			k += 1
	_count = k


## Queues `blast` at `at` (s) in time order; with no room left it is dropped.
func _add(at: float, blast: Blast) -> void:
	if _count >= _at.size():
		return
	var k := _count
	while k > 0 and _at[k - 1] > at:
		_at[k] = _at[k - 1]
		_blast[k] = _blast[k - 1]
		k -= 1
	_at[k] = at
	_blast[k] = blast
	_count += 1
