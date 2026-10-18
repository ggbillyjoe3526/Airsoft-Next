class_name GameEvent
extends RefCounted
## One thing that happened during a tick, for sound, HUD and effects (docs/ARCHITECTURE.md › Contracts 3). The
## simulation never reads events back. Events are pooled (SimEvents): read them during the tick's presentation, never
## keep one.

enum Kind {
	SHOT, ## actor fired a BB from slot at position, along direction.
	DRY_FIRE, ## actor pulled the trigger on an empty magazine (slot).
	RELOAD_START, ## actor started swapping magazines (slot).
	RELOAD_END, ## actor's fresh magazine is in (slot).
	RELOAD_REFUSED, ## actor pressed reload with no spare fuller than the loaded magazine (slot).
	DRAW, ## actor started bringing up the replica in slot.
	FIRE_MODE, ## actor's selector on slot moved to value (ReplicaConfig.FireMode).
	BB_IMPACT, ## actor's BB stopped at position: on the level (target -1, value2 the RayHit.Surface) or a body not knocked out.
	BB_LOST, ## actor's BB fell out of the level or flew past its lifetime at position.
	CHARACTER_HIT, ## actor's BB hit target at position, flying along direction: target is out and calls the hit.
	FOOTSTEP, ## actor's footstep (value: Footstep) on surface (value2: RayHit.Surface).
	ROUND_START, ## round number value is live.
	ROUND_OVER, ## value won the round (-1: a draw), for reason.
	MATCH_OVER, ## value won the match.
}

enum Footstep { RUN, SPRINT, LAND }
enum RoundEnd { ELIMINATED, TIME }

var kind: Kind = Kind.SHOT
## Who did it: the shooter, the BB's owner, the stepper. -1 for none (round events).
var actor: int = -1
## Who it happened to: the character hit, the body a BB stopped on. -1 for none.
var target: int = -1
## The loadout slot of the replica involved, or -1.
var slot: int = -1
## The event's number: a fire mode, a winner, a round, a footstep kind.
var value: int = 0
## A second number: a footstep's or an impact's surface, a round's end reason.
var value2: int = 0
var position: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO


func reset(new_kind: Kind) -> void:
	kind = new_kind
	actor = -1
	target = -1
	slot = -1
	value = 0
	value2 = 0
	position = Vector3.ZERO
	direction = Vector3.ZERO
