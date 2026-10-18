class_name SoundConfig
extends Resource
## How the rendered sounds (assets/audio/) play: each kind's level (linear gain, the browser game's config/audio.ts
## levels) and pitch spread, how far sounds carry and the ambience bed. Read by SimAudio. The buses are
## default_bus_layout.tres: Effects (replicas, impacts, hits), Footsteps, Ambience and Interface under Master.

const CUE_DIR := "res://assets/audio/cues/"
const LOOP_DIR := "res://assets/audio/loops/"
const PEAKS_PATH := "res://assets/audio/loops/peaks.json"
## Variants each cue has on disk (`<cue>_1.wav` ...).
@export var variants: int = 5
## Levels and pitch spreads (± share) by kind. A shot plays with its power part (motor whir, gas pop) on top.
@export var shot_gain: float = 1.4
@export var shot_pitch: float = 0.03
@export var mechanism_gain: float = 0.8
@export var mechanism_pitch: float = 0.04
@export var step_gain: float = 0.54
@export var own_step_gain: float = 0.25
@export var step_pitch: float = 0.06
## A vault's hands and kit on the obstacle: louder than a step, as it carries further.
@export var vault_gain: float = 0.7
@export var own_vault_gain: float = 0.4
@export var vault_pitch: float = 0.06
@export var impact_gain: float = 0.9
@export var impact_pitch: float = 0.1
@export var body_hit_gain: float = 1.0
@export var hit_tick_gain: float = 1.0
@export var hit_marker_gain: float = 0.55
@export var beep_gain: float = 1.9
## Others' sounds are at full level within unit_size (m) and fall away out to max_distance (m).
@export var unit_size: float = 4.0
@export var max_distance: float = 80.0
## Positional voices for the field's sounds, and plain ones for your own, each reused oldest first.
@export var field_voices: int = 24
@export var own_voices: int = 8
## The map's ambience bed at the browser game's gain, times the loop's stored peak (assets/audio/README.md).
@export var ambience: StringName = &"yard"
@export var ambience_gain: float = 0.035
