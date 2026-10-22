class_name HitFeed
extends RefCounted
## The hit feed's lines (the browser game's HIT_FEED): who fired, who was hit and called it, and when (simulation
## time), newest first. At most `max_lines`; a line lasts `line_time`, fading over its last `fade_time`. Plain data: the
## HUD draws it (HudFeed). The lines are made once and reused.

class Line:
	var shooter: int = -1
	var victim: int = -1
	var time: float = 0.0


var max_lines: int = 6
var line_time: float = 6.0
var fade_time: float = 1.0
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


## A hit: `shooter`'s BB hit `victim`, who called it, at simulation time `at`. The oldest line goes when full.
func add(shooter: int, victim: int, at: float) -> void:
	# Reuse the last slot, then shift it to the front.
	var line := _lines[max_lines - 1]
	for i in range(max_lines - 1, 0, -1):
		_lines[i] = _lines[i - 1]
	_lines[0] = line
	line.shooter = shooter
	line.victim = victim
	line.time = at
	_count = mini(_count + 1, max_lines)
	version += 1


## Drops the lines older than line_time at `now`.
func prune(now: float) -> void:
	while _count > 0 and now - _lines[_count - 1].time >= line_time:
		_count -= 1
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
	var left := line_time - (now - _lines[i].time)
	if fade_time <= 0.0 or left >= fade_time:
		return 1.0
	return clampf(left / fade_time, 0.0, 1.0)
