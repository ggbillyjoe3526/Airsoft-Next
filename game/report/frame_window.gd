class_name FrameWindow
extends RefCounted
## The frame times of the last seconds of play (SV4), for a bug report: turns "it stutters" into numbers to set against
## the budgets. A fixed PackedFloat32Array ring of frame times (s), frame_seconds × frame_rate_held long, so adding a
## frame allocates nothing; summed up only when a report is made (`summarise`, then `line`). Faster than
## frame_rate_held, the ring holds fewer seconds and the summary says how many. The browser game's core/frameWindow.ts.

const MS := 1000.0
## Single-precision frame times summed drift a little: a window full to within this (s) is full.
const SUM_SLACK := 0.0001

var config: ReportConfig = null
## The last summary (`summarise`): the seconds and frames it covers, the average and worst frame (ms), and the frames
## slower than hitch_ms.
var seconds: float = 0.0
var frames: int = 0
var average_ms: float = 0.0
var worst_ms: float = 0.0
var hitches: int = 0
var _times := PackedFloat32Array()
var _next: int = 0
var _filled: int = 0


func _init(report: ReportConfig = null) -> void:
	config = report if report != null else ReportConfig.new()
	_times.resize(maxi(1, ceili(config.frame_seconds * config.frame_rate_held)))


## A frame drawn in play, `frame_seconds` after the one before.
func add(frame_seconds: float) -> void:
	_times[_next] = frame_seconds
	_next = (_next + 1) % _times.size()
	_filled = mini(_filled + 1, _times.size())


## How many frame times the ring holds at most.
func capacity() -> int:
	return _times.size()


## Forgets every frame (the ring stays).
func clear() -> void:
	_next = 0
	_filled = 0


## Sums up the newest frames back to frame_seconds of play (or as many as are kept) into the fields above.
func summarise() -> void:
	seconds = 0.0
	frames = 0
	worst_ms = 0.0
	hitches = 0
	var size := _times.size()
	var hitch := config.hitch_ms / MS
	var worst := 0.0
	while frames < _filled and seconds < config.frame_seconds - SUM_SLACK:
		var t := _times[(_next - 1 - frames + size) % size]
		seconds += t
		frames += 1
		worst = maxf(worst, t)
		if t > hitch:
			hitches += 1
	worst_ms = worst * MS
	average_ms = seconds * MS / frames if frames > 0 else 0.0


## The summary as a report gives it: "last 10 s 141 fps average, worst 38 ms, 2 hitches"; "" with no frames yet.
func line() -> String:
	summarise()
	if frames == 0 or average_ms <= 0.0:
		return ""
	var hitch_word := "hitch" if hitches == 1 else "hitches"
	return "last %d s %d fps average, worst %d ms, %d %s" % [roundi(seconds), roundi(MS / average_ms),
			roundi(worst_ms), hitches, hitch_word]
