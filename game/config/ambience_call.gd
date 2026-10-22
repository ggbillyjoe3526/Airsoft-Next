class_name AmbienceCall
extends Resource
## A call now and then round the listener (the browser game's AmbientCallSpec): a variant of the cue (assets/audio/
## cues/<cue>_<n>.wav) at level (linear gain) with its pitch spread (± share), gap_min to gap_max (s) after the one
## before, distance_min to distance_max (m) away at a random bearing and height (m) up, timed from its own rng_seed. A kind
## of call keeps its seed on every field it is heard on.

@export var cue: StringName = &""
@export var level: float = 0.0
@export var pitch: float = 0.0
@export var gap_min: float = 0.0
@export var gap_max: float = 0.0
@export var distance_min: float = 0.0
@export var distance_max: float = 0.0
@export var height: float = 0.0
@export var rng_seed: int = 0
