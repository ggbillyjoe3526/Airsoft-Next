class_name RangePilot
extends RefCounted
## The smoke test's pilot in practice (PlaySession.autopilot on the range): you stand where you start and shoot the
## nearest still steel plate (by its marked distance; never the START plate), aimed at its middle, a fresh trigger pull
## every PULL_EVERY ticks. Close up a BB on its hop-up flies flat enough to ring it. No mouse or keys.

## Ticks from one trigger pull to the next (a semi-automatic fires on the press).
const PULL_EVERY := 12

var _ticks: int = 0


## `you`'s command this tick (shaped as `body`) towards a plate among `targets`; no plate, it stands still.
func fill(cmd: PlayerCommand, you: Character, targets: Array[RangeTarget], body: BodyConfig) -> void:
	cmd.reset(you.yaw, you.pitch)
	var plate := nearest_plate(targets)
	if plate == null:
		return
	var eye := you.eye(body)
	cmd.yaw = BotAim.look_yaw(eye, plate.position)
	cmd.pitch = BotAim.look_pitch(eye, plate.position)
	cmd.fire = _ticks % PULL_EVERY == PULL_EVERY - 1
	_ticks += 1


## The still plate with the shortest marked distance, or null.
static func nearest_plate(targets: Array[RangeTarget]) -> RangeTarget:
	var best: RangeTarget = null
	for t in targets:
		if t.kind != RangeTarget.Kind.STEEL or t.motion != RangeTarget.Motion.STILL or t.start or t.hidden:
			continue
		if best == null or t.distance < best.distance:
			best = t
	return best
