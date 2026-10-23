class_name AmbienceBed
extends Resource
## A loop under a field's sound (the browser game's AmbienceBed): assets/audio/loops/<loop>.wav at gain (the browser's
## level; the loop is stored at its peak, so it plays at gain times the peak in loops/peaks.json), as two copies half a
## loop apart panned width left and right. A tonal loop's second copy starts copy_offset (s) further on, where its
## tones add as unrelated sounds do (the neon's hum).

@export var loop: StringName = &""
@export var gain: float = 0.0
@export var width: float = 0.0
@export var copy_offset: float = 0.0
