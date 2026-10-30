extends SceneTree
## Renders the smoke and flash bombs' sounds (SF1) to assets/audio/cues/, 16-bit mono 44.1 kHz like the other cues,
## each variant from its own seeded noise and a slightly moved pitch:
## - grenade_pin_<n>: the pin's ring coming out, a short bright metal tink with a scrape under it;
## - grenade_bounce_<n>: a hollow plastic knock, a canister striking the ground;
## - smoke_pop_<n>: the smoke's cap popping, then its hiss fading away over a few seconds;
## - flash_bang_<n>: the flash's crack, a sharp noise burst with a low thump under it, quickly gone (a toy's bang, no
##   echoing blast).
## No display needed:
##   godot --headless --path . -s res://tools/render_grenades.gd
## then `godot --headless --path . --import` and commit the files with their .import files. An argument after `--`
## names another output folder.

const RATE := 44100
const OUT_DIR := "res://assets/audio/cues/"
const WHISTLE := preload("res://tools/render_whistle.gd")
## Variants of each cue, and the seed each cue's noise starts from (variant n adds n).
const VARIANTS := 3
const SEED := 4417
## Each variant's pitch moves this share up from the last.
const PITCH_STEP := 0.04
## Every cue is scaled so its loudest sample is this (full scale 1).
const PEAK := 0.9

## The pin: two metal partials (Hz) ringing out over PIN_RING s, with a scrape of noise over the first PIN_SCRAPE s.
const PIN_PARTIALS := Vector2(3150.0, 5120.0)
const PIN_RING := 0.06
const PIN_SCRAPE := 0.035
const PIN_LENGTH := 0.18
const PIN_SCRAPE_LEVEL := 0.35
## The knock: a hollow body's two modes (Hz) dying over KNOCK_DECAY s, with a click of noise over the first KNOCK_CLICK s.
const KNOCK_MODES := Vector2(720.0, 1310.0)
const KNOCK_DECAY := 0.035
const KNOCK_CLICK := 0.006
const KNOCK_LENGTH := 0.15
## The pop: a burst of noise over POP_TIME s, then hiss (noise brightened by HISS_BRIGHT) at HISS_LEVEL, its level
## wavering at HISS_WAVER Hz by HISS_WAVER_DEPTH, faded out over the last HISS_FADE of SMOKE_LENGTH s.
const POP_TIME := 0.05
const HISS_LEVEL := 0.28
const HISS_BRIGHT := 0.85
const HISS_WAVER := 3.0
const HISS_WAVER_DEPTH := 0.25
const HISS_ATTACK := 0.15
const HISS_FADE := 2.2
const SMOKE_LENGTH := 3.5
## The bang: noise dying over BANG_DECAY s and darkening (its one-pole low-pass from BANG_BRIGHT down to BANG_DARK), a
## THUMP_HZ thump dying over THUMP_DECAY s at THUMP_LEVEL, all softly clipped.
const BANG_DECAY := 0.09
const BANG_BRIGHT := 0.95
const BANG_DARK := 0.25
const THUMP_HZ := 62.0
const THUMP_DECAY := 0.12
const THUMP_LEVEL := 0.8
const BANG_LENGTH := 0.9
const BANG_DRIVE := 2.5


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := OUT_DIR if args.is_empty() else args[0].trim_suffix("/") + "/"
	var failed := false
	for v in VARIANTS:
		var pitch := 1.0 + PITCH_STEP * v
		var rng := RandomNumberGenerator.new()
		rng.seed = SEED + v
		failed = not _write(out, "grenade_pin", v, pin(rng, pitch)) or failed
		failed = not _write(out, "grenade_bounce", v, knock(rng, pitch)) or failed
		failed = not _write(out, "smoke_pop", v, smoke(rng, pitch)) or failed
		failed = not _write(out, "flash_bang", v, bang(rng, pitch)) or failed
	quit(1 if failed else 0)


func _write(out: String, stem: String, variant: int, mono: PackedFloat32Array) -> bool:
	var path := "%s%s_%d.wav" % [out, stem, variant + 1]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("render_grenades: %s could not be written (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_buffer(WHISTLE.wav(normalised(mono)))
	file.close()
	print("[render_grenades] %s" % path)
	return true


## The pin coming out.
static func pin(rng: RandomNumberGenerator, pitch: float) -> PackedFloat32Array:
	var out := _blank(PIN_LENGTH)
	for i in out.size():
		var t := float(i) / RATE
		var ring := exp(-t / PIN_RING)
		var tone := sin(TAU * PIN_PARTIALS.x * pitch * t) + 0.6 * sin(TAU * PIN_PARTIALS.y * pitch * t)
		var scrape := rng.randf_range(-1.0, 1.0) * PIN_SCRAPE_LEVEL * maxf(0.0, 1.0 - t / PIN_SCRAPE)
		out[i] = tone * ring + scrape
	return out


## A canister's knock on the ground.
static func knock(rng: RandomNumberGenerator, pitch: float) -> PackedFloat32Array:
	var out := _blank(KNOCK_LENGTH)
	for i in out.size():
		var t := float(i) / RATE
		var body := (sin(TAU * KNOCK_MODES.x * pitch * t) + 0.5 * sin(TAU * KNOCK_MODES.y * pitch * t)) * exp(-t / KNOCK_DECAY)
		var click := rng.randf_range(-1.0, 1.0) * maxf(0.0, 1.0 - t / KNOCK_CLICK)
		out[i] = body + click
	return out


## The smoke's pop and hiss.
static func smoke(rng: RandomNumberGenerator, pitch: float) -> PackedFloat32Array:
	var out := _blank(SMOKE_LENGTH)
	var low := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		# A one-pole low-pass taken away from the noise leaves its bright part: the hiss.
		low += (noise - low) * (1.0 - HISS_BRIGHT)
		var bright := noise - low
		var pop := noise * maxf(0.0, 1.0 - t / POP_TIME)
		var waver := 1.0 + HISS_WAVER_DEPTH * sin(TAU * HISS_WAVER * pitch * t)
		var level := HISS_LEVEL * minf(1.0, t / HISS_ATTACK) * minf(1.0, (SMOKE_LENGTH - t) / HISS_FADE) * waver
		out[i] = pop + bright * level
	return out


## The flash's bang.
static func bang(rng: RandomNumberGenerator, pitch: float) -> PackedFloat32Array:
	var out := _blank(BANG_LENGTH)
	var low := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var decay := exp(-t / BANG_DECAY)
		var bright := lerpf(BANG_DARK, BANG_BRIGHT, decay)
		low += (rng.randf_range(-1.0, 1.0) - low) * bright
		var thump := sin(TAU * THUMP_HZ * pitch * t) * exp(-t / THUMP_DECAY) * THUMP_LEVEL
		out[i] = tanh((low * decay + thump) * BANG_DRIVE)
	return out


## `mono` scaled so its loudest sample is PEAK.
static func normalised(mono: PackedFloat32Array) -> PackedFloat32Array:
	var most := 0.0
	for x in mono:
		most = maxf(most, absf(x))
	if most <= 0.0:
		return mono
	var out := PackedFloat32Array(mono)
	for i in out.size():
		out[i] *= PEAK / most
	return out


static func _blank(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(roundi(seconds * RATE))
	return out
