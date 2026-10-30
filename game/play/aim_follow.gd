class_name AimFollow
extends RefCounted
## The sight's raise as drawn (FB6). The simulation's Character.aim_raise moves once a tick, so at a slowed game speed
## (the Dev settings' pacer) it held still for frames and then jumped, and sped up it moved one tick's worth on one
## frame and two on the next. Drawn, it follows the simulation's at the simulation's own raise speed (Aiming.raise_time)
## over the simulation time each frame stands for (the real frame time times the pacer's rate): an even change every
## frame at any game speed, never further behind than a frame's worth. It snaps to the simulation's when the view moves
## to someone else or they are out. Pure: no nodes.

## The raise to draw (0 at the hip, 1 fully up).
var raise: float = 0.0
## Whose raise it follows (-1: nobody yet).
var _id: int = -1


## The raise to draw for `c` this frame, `sim_delta` seconds of simulation time since the last.
func update(c: Character, cfg: MovementConfig, sim_delta: float) -> float:
	if c.id != _id or not Elimination.is_in_play(c):
		_id = c.id
		raise = c.aim_raise
	else:
		raise = move_toward(raise, c.aim_raise, maxf(sim_delta, 0.0) / Aiming.raise_time(c, cfg))
	return raise
