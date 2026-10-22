class_name PlayerInput
extends Node
## The player's controller (the browser game's input/playerInput.ts): the mouse turns the view as events arrive, every
## rendered frame, and once a tick `fill` writes the keys and buttons into the player's PlayerCommand, the one input the
## simulation takes (docs/ARCHITECTURE.md › Contracts 2). Presses between two ticks are latched, so a tap shorter than a
## tick (a semi click, a jump, a reload) is never dropped. It reads nothing while the mouse isn't captured, so a menu
## click never fires a shot.

## The actions in project.godot's input map.
const FORWARD := &"move_forward"
const BACK := &"move_back"
const LEFT := &"move_left"
const RIGHT := &"move_right"
const WALK := &"walk"
const SPRINT := &"sprint"
const CROUCH := &"crouch"
const JUMP := &"jump"
const LEAN_LEFT := &"lean_left"
const LEAN_RIGHT := &"lean_right"
const FIRE := &"fire"
const AIM := &"aim"
const RELOAD := &"reload"
const FIRE_MODE := &"fire_mode"
const SLOTS: Array[StringName] = [&"slot_1", &"slot_2"]
const NEXT_SLOT := &"slot_next"
const PREVIOUS_SLOT := &"slot_previous"
const HOP_UP_LESS := &"hop_up_less"
const HOP_UP_MORE := &"hop_up_more"
const HOLSTER := &"holster"

## The view, absolute (rad): yaw 0 looks down -Z and turns left positive; pitch up positive.
var view_yaw: float = 0.0
var view_pitch: float = 0.0
## Mouse turns are read only while true (the play scene captures the mouse and sets it).
var active: bool = false
## The sight's zoom right now (1: none), which slows the mouse while aiming.
var zoom: float = 1.0

var _controls: ControlsConfig = null
var _max_pitch: float = 1.55
var _fire_latch: bool = false
var _jump_latch: bool = false
var _reload_latch: bool = false
var _mode_latch: bool = false
var _holster_latch: bool = false
var _slot_latch: int = -1
## Hop-up notches pressed since the last tick (more lift positive).
var _hop_steps: int = 0
var _slot_steps: int = 0
var _crouched: bool = false
## Aiming, while aim toggles (ControlsConfig.aim_toggle).
var _aimed: bool = false
## Fire is ignored until it is let go (hold_fire).
var _fire_held_back: bool = false


func setup(controls: ControlsConfig, max_pitch: float) -> void:
	_controls = controls
	_max_pitch = max_pitch


## Looks along (yaw, pitch), standing, as at a spawn.
func face(yaw: float, pitch: float = 0.0) -> void:
	_crouched = false
	_aimed = false
	view_yaw = yaw
	view_pitch = pitch


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		var turn := _controls.radians_per_count * _controls.sensitivity
		if _aiming():
			turn *= _controls.aim_sensitivity
		if _controls.scale_with_zoom:
			turn /= maxf(zoom, 1.0)
		view_yaw = wrapf(view_yaw - motion.screen_relative.x * turn, -PI, PI)
		var dy := motion.screen_relative.y * turn * (-1.0 if _controls.invert_y else 1.0)
		view_pitch = clampf(view_pitch - dy, -_max_pitch, _max_pitch)
		return
	if event.is_echo() or not event.is_pressed():
		return
	if event.is_action(FIRE):
		_fire_latch = true
	elif event.is_action(AIM) and _controls.aim_toggle:
		_aimed = not _aimed
	elif event.is_action(JUMP):
		if _controls.crouch_toggle and _crouched:
			_crouched = false
		else:
			_jump_latch = true
	elif event.is_action(CROUCH) and _controls.crouch_toggle:
		_crouched = not _crouched
	elif event.is_action(SPRINT):
		_crouched = false
	elif event.is_action(RELOAD):
		_reload_latch = true
	elif event.is_action(FIRE_MODE):
		_mode_latch = true
	elif event.is_action(HOLSTER):
		_holster_latch = true
		_slot_latch = -1
		_slot_steps = 0
	elif event.is_action(HOP_UP_LESS):
		_hop_steps -= 1
	elif event.is_action(HOP_UP_MORE):
		_hop_steps += 1
	elif event.is_action(NEXT_SLOT):
		_slot_steps += 1
		_slot_latch = -1
		_holster_latch = false
	elif event.is_action(PREVIOUS_SLOT):
		_slot_steps -= 1
		_slot_latch = -1
		_holster_latch = false
	else:
		for i in SLOTS.size():
			if event.is_action(SLOTS[i]):
				_slot_latch = i
				_slot_steps = 0
				_holster_latch = false


## Whether the sight is up, held or toggled, as the aimed sensitivity reads it.
func _aiming() -> bool:
	return _aimed if _controls.aim_toggle else Input.is_action_pressed(AIM)


## This tick's command: held keys as they are now, presses since the last tick, the view as the mouse left it.
## `held_slot` is the replica in hand, which the mouse wheel steps from.
func fill(cmd: PlayerCommand, held_slot: int = 0) -> void:
	if not active:
		cmd.reset(view_yaw, view_pitch)
		_clear_latches()
		return
	cmd.forward = Input.get_action_strength(FORWARD) - Input.get_action_strength(BACK)
	cmd.right = Input.get_action_strength(RIGHT) - Input.get_action_strength(LEFT)
	cmd.yaw = view_yaw
	cmd.pitch = view_pitch
	cmd.walk = Input.is_action_pressed(WALK)
	cmd.sprint = Input.is_action_pressed(SPRINT)
	cmd.crouch = _crouched if _controls.crouch_toggle else Input.is_action_pressed(CROUCH)
	cmd.aim = _aiming()
	# Lean is held, whatever crouch and aim do (owner, 2026-10-03).
	cmd.lean = Input.get_action_strength(LEAN_RIGHT) - Input.get_action_strength(LEAN_LEFT)
	if _fire_held_back and not Input.is_action_pressed(FIRE):
		_fire_held_back = false
	cmd.fire = not _fire_held_back and (Input.is_action_pressed(FIRE) or _fire_latch)
	cmd.jump = _jump_latch # a press, not a hold: holding Space doesn't hop on every landing
	cmd.reload = _reload_latch
	cmd.cycle_fire_mode = _mode_latch
	cmd.switch_to = _slot_latch
	cmd.hop_up_steps = _hop_steps
	cmd.holster = _holster_latch
	if _slot_steps != 0:
		cmd.switch_to = posmod(held_slot + _slot_steps, SLOTS.size())
	_clear_latches()


## Ignores the fire button until it is let go: a click that moved the round on is not the next round's first shot.
func hold_fire() -> void:
	_fire_held_back = true
	_fire_latch = false


## Lets go of everything (focus lost, the menu opened), so no key stays held.
func release() -> void:
	active = false
	_clear_latches()


func _clear_latches() -> void:
	_fire_latch = false
	_jump_latch = false
	_reload_latch = false
	_mode_latch = false
	_holster_latch = false
	_slot_latch = -1
	_slot_steps = 0
	_hop_steps = 0
