class_name AimFollow
extends RefCounted
## The sight's raise as drawn (FB6). The simulation's Character.aim_raise moves once a tick, so at a slowed game speed
## (the Dev settings' pacer) it held still for frames and then jumped, and sped up it moved one tick's worth on one
## frame and two on the next. Drawn, it follows the simulation's at the simulation's own raise speed (Aiming.raise_time)
## over the simulation time each frame stands for (the real frame time times the pacer's rate): an even change every
## frame at any game speed, never further behind than a frame's worth. It snaps to the simulation's when the view moves
## to someone else, when they are out, when the raise moved further than this frame's ticks can explain (a new round's
## respawn puts it back to the hip at once) and when the raise takes no time. Pure: no nodes.

## The leeway, in ticks' worth of raise, on top of this frame's ticks and step before a gap counts as a jump.
const JUMP_SLACK_TICKS := 1.0

## The raise to draw (0 at the hip, 1 fully up).
var raise: float = 0.0
## Whose raise it follows (-1: nobody yet).
var _id: int = -1


## The raise to draw for `c` this frame, `sim_delta` seconds of simulation time since the last.
func update(c: Character, cfg: MovementConfig, sim_delta: float) -> float:
	var time := Aiming.raise_time(c, cfg)
	var dt := maxf(sim_delta, 0.0)
	var step := dt / time if time > 0.0 else 0.0
	# The most the simulation's ticks this frame can have moved it, the step, and a tick's slack: past that it jumped.
	var tick_share := PlaySession.TICK / time if time > 0.0 else 0.0
	var reach := step + (ceilf(dt / PlaySession.TICK) + JUMP_SLACK_TICKS) * tick_share
	if c.id != _id or not Elimination.is_in_play(c) or time <= 0.0 or absf(c.aim_raise - raise) > reach:
		_id = c.id
		raise = c.aim_raise
	else:
		raise = move_toward(raise, c.aim_raise, step)
	return raise
