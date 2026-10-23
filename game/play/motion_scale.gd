class_name MotionScale
extends RefCounted
## How much of each movement the view and the HUD draw (Settings › Accessibility › Reduced motion; the browser game's
## REDUCED_MOTION): all of it, or with motion reduced data/accessibility.md's shares (AccessibilityTable.MOTION_IDS).
## The camera's recoil climb is not here: it always stays, because it shows where the next BB goes. Built on a settings
## change, never per frame.

## The replica's sway behind your turns, its kick per shot and its tilt through a reload (ReplicaView).
var sway: float = 1.0
var kick: float = 1.0
var reload_cant: float = 1.0
## The view's roll as you lean, and its dip and tip over a vault (FirstPersonView).
var lean_roll: float = 1.0
var vault_tip: float = 1.0
## The wind dust (WindDust), the HUD's pulsing (held at full when none) and the view's jolt when you're hit (step 23).
var dust: float = 1.0
var hud_pulse: float = 1.0
var hit_jolt: float = 1.0


## The shares to draw with: all of every movement, or with `reduced` `table`'s (the shipped table when not given).
static func of(reduced: bool, table: AccessibilityTable = null) -> MotionScale:
	var m := MotionScale.new()
	if not reduced:
		return m
	var t := table if table != null else AccessibilityTable.shared()
	m.sway = t.share(&"sway")
	m.kick = t.share(&"kick")
	m.reload_cant = t.share(&"reload_cant")
	m.lean_roll = t.share(&"lean_roll")
	m.vault_tip = t.share(&"vault_tip")
	m.dust = t.share(&"dust")
	m.hud_pulse = t.share(&"hud_pulse")
	m.hit_jolt = t.share(&"hit_jolt")
	return m
