class_name AmbienceBed
extends Resource
## A loop under a field's sound (the browser game's AmbienceBed): assets/audio/loops/<loop>.wav at gain (the browser's
## level; the loop is stored at its peak, so it plays at gain times the peak in loops/peaks.json), as one unpanned copy
## for now. width (the browser's pan of two copies half a loop apart) and copy_offset (how much further on a tonal
## loop's second copy starts) are kept for a panned pair later and unused today (KNOWN_ISSUES).

@export var loop: StringName = &""
@export var gain: float = 0.0
@export var width: float = 0.0
@export var copy_offset: float = 0.0
