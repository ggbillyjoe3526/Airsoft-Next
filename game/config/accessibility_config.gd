class_name AccessibilityConfig
extends Resource
## Settings › Accessibility's numbers that aren't the player's to pick (the browser game's accessibility.ts SOUND_CUES
## and SOUND_CUE_SIZE, matchInfo.ts HUD_SIZE): the sound cue ring round the crosshair (AC4) and the ranges of the
## sound cue size and HUD size sliders, which the settings check a saved value against. The team colours and Reduced
## motion's shares are data/accessibility.md's (AccessibilityTable).

## The sliders' ranges, steps and defaults: the sound cues' size scales the markers, not the ring (1 = as built); the
## HUD size scales the whole HUD but the crosshair, on top of the window's own growth (1 = as drawn at 1080p).
const CUE_SIZE_RANGE := Vector2(0.6, 2.0)
const CUE_SIZE_STEP := 0.1
const CUE_SIZE_DEFAULT := 1.0
const HUD_SIZE_RANGE := Vector2(0.8, 1.5)
const HUD_SIZE_STEP := 0.05
const HUD_SIZE_DEFAULT := 1.0
## The sound cues' colour by default: red among HudPrefs.COLOURS (the browser game's Dev 6 playtest, 2026-10-16).
const CUE_COLOUR_DEFAULT := 5

@export_group("Sound cues")
## Seconds a cue stays up; it fades out over the last `cue_fade` of them.
@export var cue_life: float = 1.4
@export var cue_fade: float = 0.6
## A cue's opacity at the edge of its sound's reach (1 right beside you).
@export var cue_far_opacity: float = 0.35
## Markers kept, pooled: one per player and kind, so a new sound from the same player and kind moves its marker.
@export var cue_markers: int = 10
## The ring's distance from the screen's centre (px at 1080p): outside the crosshair and the hit marker.
@export var cue_ring_radius: float = 150.0
