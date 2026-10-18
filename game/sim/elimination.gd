class_name Elimination
## Hit calling, enforced by the game (the browser game's sim/elimination.ts). STUB: the hit-calling part of SC1 fills
## this in; eliminate() already marks the victim so BB tests can run.


## Only characters in play can shoot or be hit.
static func is_in_play(c: Character) -> bool:
	return c.status == Character.Status.ALIVE


## Eliminates `victim` (a no-op if it is already out of play): it starts calling its hit.
static func eliminate(victim: Character, shooter_id: int, _characters: Array[Character], _ends: Array[MapEnd]) -> void:
	if not is_in_play(victim):
		return
	victim.status = Character.Status.CALLING
	victim.status_time = 0.0
	victim.hit_by = shooter_id
	victim.sprinting = false
