class_name HudAnnounce
extends Label
## Screen reader messages in play: a Label in the accessibility tree that is never drawn (shown, at opacity 0, so the
## renderer skips it), a live region whose text a screen reader reads as it changes. Announcer gathers the tick's lines;
## each message it lets out becomes the text, polite or (your hit, the match's result) assertive. The text is cleared
## when a message starts gathering, so a message the same as the last still reads as a change. With Screen reader
## messages off the region is LIVE_OFF and gets no text. Godot runs AccessKit only while a screen reader does
## (project.godot's accessibility_support 0), so otherwise this costs a string on the few events it reads.

var _announcer: Announcer = null


## Messages for `you` with `teams`' names, half time after round `half_time_after` (0 for none).
func setup(teams: TeamConfig, you: Character, half_time_after: int) -> void:
	name = "HudAnnounce"
	_announcer = Announcer.new(teams, you, half_time_after)
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	set_on(true)


## The names by character id, as the hit feed shows them.
func set_names(names: PackedStringArray) -> void:
	_announcer.set_names(names)


## Settings.read_out: on, a polite live region; off, LIVE_OFF with no text and nothing gathered.
func set_on(on: bool) -> void:
	_announcer.set_on(on)
	accessibility_live = AccessibilityServer.LIVE_POLITE if on else AccessibilityServer.LIVE_OFF
	if not on:
		text = ""


## The tick's events in `state`.
func on_tick(state: GameState) -> void:
	var was := _announcer.gathering()
	_announcer.on_tick(state)
	if not was and _announcer.gathering():
		text = ""


## Moves the join window on `delta` seconds; a message let out becomes the text, at its priority.
func advance(delta: float) -> void:
	if not _announcer.advance(delta):
		return
	var urgent := _announcer.assertive()
	accessibility_live = AccessibilityServer.LIVE_ASSERTIVE if urgent else AccessibilityServer.LIVE_POLITE
	text = _announcer.message()


func announcer() -> Announcer:
	return _announcer
