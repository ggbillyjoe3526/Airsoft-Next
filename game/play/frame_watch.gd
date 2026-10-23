class_name FrameWatch
extends RefCounted
## The automatic step-down's watch (the browser game's FrameTimeWatch; DisplayConfig's numbers): fed each drawn frame's
## time while it `counts`, it cuts play into windows of `step_window` seconds, calls a window slow when more than
## `step_slow_share` of its frames ran over `slow_ms`, and asks for one preset down (`feed` returns true, `due` holds
## it) after `step_windows` slow windows in a row. It asks once a match (`new_match` lets it ask again). A frame that
## doesn't count (paused, unfocused, between rounds, a player's own pick) starts the count over. Plain numbers only:
## feeding it allocates nothing.

var config: DisplayConfig = null
## The window being counted: its seconds, frames and slow frames; and the slow windows in a row before it.
var _seconds: float = 0.0
var _frames: int = 0
var _slow: int = 0
var _slow_windows: int = 0
## A step asked for, waiting for the round's end (take); asked once this match.
var _due: bool = false
var _asked: bool = false


func _init(display: DisplayConfig = null) -> void:
	config = display if display != null else DisplayConfig.new()


## Whether a frame counts: the graphics are the automatic pick (`automatic`), with a preset below it (`preset`, Low never
## steps), the window focused, the game unpaused, a round in play (`in_play`), and not on the simpler renderer, which
## has nothing cheaper to step to and whose frames say nothing about the normal one.
static func counts(automatic: bool, preset: StringName, focused: bool, paused: bool, in_play: bool,
		rendering_method: String) -> bool:
	return automatic and preset_below(preset) != &"" and focused and not paused and in_play \
			and rendering_method != GraphicsPick.COMPATIBILITY


## The preset one below `preset` (GraphicsTable.PRESETS), or &"" for Low and for a name that isn't a preset.
static func preset_below(preset: StringName) -> StringName:
	var at := GraphicsTable.PRESETS.find(preset)
	return GraphicsTable.PRESETS[at - 1] if at > 0 else &""


## A slow frame's time (ms) under the frame-rate limit `limit` (Settings.UNLIMITED for none): `step_slow_ms`, or
## `step_limit_slack` of the limit's frame when that is longer.
func slow_ms(limit: int) -> float:
	if limit <= Settings.UNLIMITED:
		return config.step_slow_ms
	return maxf(config.step_slow_ms, config.step_limit_slack * 1000.0 / limit)


## One drawn frame of `frame_seconds` under the frame-rate limit `limit`; `counting` is `counts`' answer for it, and
## `pretend_slow` (the Dev settings' Pretend slow frames) counts it slow whatever its time. True on the frame the watch
## asks for a step (once a match); a frame that doesn't count starts the count over.
func feed(frame_seconds: float, limit: int, counting: bool, pretend_slow: bool = false) -> bool:
	if not counting:
		reset()
		return false
	if _asked:
		return false
	_seconds += frame_seconds
	_frames += 1
	if pretend_slow or frame_seconds * 1000.0 > slow_ms(limit):
		_slow += 1
	if _seconds < config.step_window:
		return false
	var slow_window := float(_slow) / _frames > config.step_slow_share
	_slow_windows = _slow_windows + 1 if slow_window else 0
	_seconds = 0.0
	_frames = 0
	_slow = 0
	if _slow_windows < config.step_windows:
		return false
	_slow_windows = 0
	_due = true
	_asked = true
	return true


## Starts the count over (the window and the slow windows in a row); a step already asked for stays due.
func reset() -> void:
	_seconds = 0.0
	_frames = 0
	_slow = 0
	_slow_windows = 0


## A player's own pick: the count starts over and a step waiting is dropped (one not applied leaves the match free to
## ask again; one applied doesn't).
func drop() -> void:
	reset()
	if _due:
		_due = false
		_asked = false


## A new match: it may ask again.
func new_match() -> void:
	reset()
	_due = false
	_asked = false


## Whether a step waits for the round's end.
func due() -> bool:
	return _due


## The round's end: true (once) when a step was due.
func take() -> bool:
	var was := _due
	_due = false
	return was


## The slow windows in a row so far (tests).
func slow_windows() -> int:
	return _slow_windows
