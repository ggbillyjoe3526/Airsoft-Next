class_name Sensitivity
## Sensitivity as other shooters and mouse software count it (the browser game's input/sensitivity.ts): the centimetres
## of mouse travel for one full turn at a mouse DPI, and back. Pure maths over ControlsConfig.radians_per_count.

const CM_PER_INCH := 2.54
const FULL_TURN := TAU
## The hip sensitivity's range and the slider's step (fine, so a low value moves in small jumps).
const MIN := 0.2
const MAX := 4.0
const STEP := 0.01
## The aimed multiplier's range.
const AIM_MIN := 0.2
const AIM_MAX := 2.0
const AIM_STEP := 0.05
## The mouse DPI a typed cm/360 is worked out at: its range and default.
const DPI_MIN := 100
const DPI_MAX := 32000
const DPI_DEFAULT := 800


## Centimetres of mouse travel for one full turn at `sensitivity`, with a mouse of `dpi` counts per inch.
static func cm_per_360(radians_per_count: float, sensitivity: float, dpi: float) -> float:
	var counts := FULL_TURN / (radians_per_count * sensitivity)
	return counts / dpi * CM_PER_INCH


## The sensitivity that turns a full circle over `cm` of mouse travel with a mouse of `dpi`; the inverse of cm_per_360.
static func for_cm(radians_per_count: float, cm: float, dpi: float) -> float:
	var counts := cm / CM_PER_INCH * dpi
	return FULL_TURN / (radians_per_count * counts)


## The sensitivity a typed cm/360 sets: for_cm kept to the slider's range, exactly (not rounded to its step, which would
## show another cm/360 than the one typed). NAN for a figure that is not positive.
static func from_typed_cm(radians_per_count: float, cm: float, dpi: float) -> float:
	if cm <= 0.0 or dpi <= 0.0:
		return NAN
	return clampf(for_cm(radians_per_count, cm, dpi), MIN, MAX)
