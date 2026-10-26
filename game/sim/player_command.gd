class_name PlayerCommand
extends RefCounted
## The one input every character acts through (docs/ARCHITECTURE.md › Contracts 2): the player's controller and each
## bot fill one per tick, and nothing else moves a character. View angles are absolute.

## -1..1, forward positive, relative to yaw.
var forward: float = 0.0
## -1..1, right positive, relative to yaw.
var right: float = 0.0
## Absolute view yaw (rad): 0 looks down -Z, positive turns left (counter-clockwise seen from above).
var yaw: float = 0.0
## Absolute view pitch (rad), positive looks up.
var pitch: float = 0.0
var sprint: bool = false
## Walk held: slow and quiet. Wins over sprint.
var walk: bool = false
var crouch: bool = false
var jump: bool = false
## Aim down sights (held).
var aim: bool = false
## Trigger held. Semi fires on the press only.
var fire: bool = false
var reload: bool = false
## Loadout slot to switch to, or -1 for none.
var switch_to: int = -1
## Step the selector of the replica in hand to its next mode (one-shot).
var cycle_fire_mode: bool = false
## Lean held: -1 full left .. 1 full right, 0 upright (Lean).
var lean: float = 0.0
## Notches to turn the hop-up dial of the replica in hand this tick (one-shot): positive for more lift. Bots leave it 0.
var hop_up_steps: int = 0
## Put the replica in hand away (one-shot; the holster): nothing to fire or aim, a faster run that never passes the
## sprint. A slot, a fresh trigger pull, an aim press or a reload draws it again, slower than a switch.
var holster: bool = false
## A squad order to this character's bot teammates (one-shot; SquadOrder), and whether it was picked on the order wheel
## (picked again there, the order in force stays; its key again cancels it).
var squad_order: SquadOrder.Kind = SquadOrder.Kind.NONE
var order_from_wheel: bool = false
## Switch the weapon torch on the replica in hand on or off (one-shot; Torch). Nothing without a light in hand.
var toggle_torch: bool = false
## Ping where the view looks, for this character's bot teammates (one-shot; PN1): the simulation turns it into a PING
## event and the bots' controller into a ping (Pings).
var ping: bool = false


## Back to no input, looking along (yaw, pitch).
func reset(view_yaw: float = 0.0, view_pitch: float = 0.0) -> void:
	forward = 0.0
	right = 0.0
	yaw = view_yaw
	pitch = view_pitch
	sprint = false
	walk = false
	crouch = false
	jump = false
	aim = false
	fire = false
	reload = false
	switch_to = -1
	cycle_fire_mode = false
	lean = 0.0
	hop_up_steps = 0
	holster = false
	squad_order = SquadOrder.Kind.NONE
	order_from_wheel = false
	toggle_torch = false
	ping = false


func copy_from(other: PlayerCommand) -> void:
	forward = other.forward
	right = other.right
	yaw = other.yaw
	pitch = other.pitch
	sprint = other.sprint
	walk = other.walk
	crouch = other.crouch
	jump = other.jump
	aim = other.aim
	fire = other.fire
	reload = other.reload
	switch_to = other.switch_to
	cycle_fire_mode = other.cycle_fire_mode
	lean = other.lean
	hop_up_steps = other.hop_up_steps
	holster = other.holster
	squad_order = other.squad_order
	order_from_wheel = other.order_from_wheel
	toggle_torch = other.toggle_torch
	ping = other.ping
