class_name HitFeed
extends RefCounted
## The hit feed's lines (the browser game's HIT_FEED): who fired, who was hit and called it, and when (simulation time),
## newest first. At most `max_lines`; a line lasts `line_time`, fading over its last `fade_time`, unless it is kept (the
## line you were hit in stays up until the round ends: `release_kept`), or all lines stay when `stay` (the HUD tab's
## Keep: only the newest `max_lines` go on, for the whole match). Your team's callouts share it (CO2): a call line is
## the speaker and the words, with a hit line's time and fade, counted among the lines, but never kept, so on Keep the
## hits stay and the calls still go: a full Keep feed loses its oldest call first, and a call finds no room in one full
## of hits (a call never pushes a hit out). Plain data: the HUD draws it (HudFeed). The lines are made once and reused.

class Line:
	## The shooter, or a call's speaker.
	var shooter: int = -1
	var victim: int = -1
	var time: float = 0.0
	var keep: bool = false
	## A callout (`words` its line as said) rather than a hit.
	var call: bool = false
	var words: String = ""


var max_lines: int = 6
var line_time: float = 6.0
var fade_time: float = 1.0
## Every line stays (never ages out or fades) until it is pushed off or the feed is cleared.
var stay: bool = false
## Bumped whenever the lines change (one added or one gone), so the HUD rebuilds rows only then.
var version: int = 0

var _lines: Array[Line] = []
var _count: int = 0


func setup(lines: int, show_for: float, fade_for: float) -> void:
	max_lines = maxi(1, lines)
	line_time = show_for
	fade_time = clampf(fade_for, 0.0, show_for)
	_lines.clear()
	for i in max_lines:
		_lines.append(Line.new())
	_count = 0
	version += 1


## A hit: `shooter`'s BB hit `victim`, who called it, at simulation time `at`; `kept` lines stay up until
## release_kept. When full the oldest line not kept goes.
func add(shooter: int, victim: int, at: float, kept: bool = false) -> void:
	var line := _front()
	line.shooter = shooter
	line.victim = victim
	line.time = at
	line.keep = kept
	line.call = false
	line.words = ""


## A teammate's callout: `speaker` said `words` at simulation time `at`. It ages and fades as a hit line, even on Keep;
## on Keep with the feed full of hits it is left out, as a call never pushes a hit out.
func add_call(speaker: int, words: String, at: float) -> void:
	if stay and _count == max_lines and _oldest_call() < 0:
		return
	var line := _front()
	line.shooter = speaker
	line.victim = -1
	line.time = at
	line.keep = false
	line.call = true
	line.words = words


## The index of the oldest call line, or -1 when no line is a call.
func _oldest_call() -> int:
	var i := _count - 1
	while i >= 0 and not _lines[i].call:
		i -= 1
	return i


## Drops every call line (a new round, or Settings › HUD › Callouts switched off); the hits keep their order.
func drop_calls() -> void:
	var left := 0
	for i in _count:
		var line := _lines[i]
		if not line.call:
			_lines[i] = _lines[left]
			_lines[left] = line
			left += 1
	if left != _count:
		_count = left
		version += 1


## The line to fill as the newest, moved to the front: a free slot, or when full the oldest line not kept (on Keep the
## oldest call, if there is one, before any hit).
func _front() -> Line:
	var slot := max_lines - 1
	if _count == max_lines:
		while slot > 0 and _lines[slot].keep:
			slot -= 1
		if stay:
			var oldest_call := _oldest_call()
			if oldest_call >= 0:
				slot = oldest_call
	else:
		slot = _count
	var line := _lines[slot]
	for i in range(slot, 0, -1):
		_lines[i] = _lines[i - 1]
	_lines[0] = line
	_count = mini(_count + 1, max_lines)
	version += 1
	return line


## Drops the lines older than line_time at `now`, but not the kept ones (nor, on Keep, the hits); the rest keep their
## order.
func prune(now: float) -> void:
	var left := 0
	for i in _count:
		var line := _lines[i]
		if line.keep or (stay and not line.call) or now - line.time < line_time:
			_lines[i] = _lines[left]
			_lines[left] = line
			left += 1
	if left != _count:
		_count = left
		version += 1


## Lets the kept lines go (the round ended): they age out as any other.
func release_kept() -> void:
	for i in _count:
		if _lines[i].keep:
			_lines[i].keep = false
			version += 1


func clear() -> void:
	if _count > 0:
		_count = 0
		version += 1


func count() -> int:
	return _count


## The `i`th line, 0 the newest.
func line(i: int) -> Line:
	return _lines[i]


## How opaque the `i`th line is at `now`: 1 until its last fade_time, then down to 0.
func alpha(i: int, now: float) -> float:
	if _lines[i].keep or (stay and not _lines[i].call):
		return 1.0
	var left := line_time - (now - _lines[i].time)
	if fade_time <= 0.0 or left >= fade_time:
		return 1.0
	return clampf(left / fade_time, 0.0, 1.0)
