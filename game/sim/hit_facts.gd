class_name HitFacts
extends RefCounted
## What the "What got you" card says about a hit on the player, kept at hit time as plain data (the browser game's
## sim/hitFacts.ts). One record is reused for every hit, so nothing is allocated per hit; BotController fills it, since
## only the bots know whether the shooter was holding an angle and how long it had the player in view, and the HUD reads
## it once the hit comes in.

## Simulation time of the hit (-INF: none yet).
var time: float = -INF
var victim_id: int = -1
var shooter_id: int = -1
## Along the floor from the shooter to the victim, unit length (the way the BB came).
var from_shooter: Vector2 = Vector2.ZERO
## Metres between the two along the floor.
var distance: float = 0.0
## The victim was moving (at least the moving speed along the floor) as the BB hit.
var moving: bool = false
## The shooter was on the victim's team (friendly fire).
var friendly: bool = false
## The BB had bounced first (only when ricochets count).
var ricochet: bool = false
## Whether `held` is known: a bot's BB hit an enemy without a bounce.
var held_known: bool = false
## The shooting bot was holding an angle (standing at a post, its view already there) when it first saw the victim.
var held: bool = false
## Seconds the victim had been in the shooter's view, unbroken, at the hit; -1 when not known.
var in_view: float = -1.0


## Writes the hit of `victim` by `shooter` at `at_time`, by a bounced BB when `bounced`. `is_held_known`, `was_held`
## and `seen_for` (-1: unknown) are what the shooter's bot knew; the victim counts as moving from `moving_speed` m/s
## along the floor.
func record(at_time: float, victim: Character, shooter: Character, bounced: bool, is_held_known: bool,
		was_held: bool, seen_for: float, moving_speed: float) -> void:
	var d := Vector2(victim.position.x - shooter.position.x, victim.position.z - shooter.position.z)
	time = at_time
	victim_id = victim.id
	shooter_id = shooter.id
	distance = d.length()
	from_shooter = d / distance if distance > 0.0 else Vector2.ZERO
	moving = Vector2(victim.velocity.x, victim.velocity.z).length() >= moving_speed
	friendly = victim.team == shooter.team
	ricochet = bounced
	held_known = is_held_known
	held = was_held and is_held_known
	in_view = seen_for
