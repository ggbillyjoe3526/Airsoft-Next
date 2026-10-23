class_name FigurePose
extends RefCounted
## What a figure's legs do (step 23, FI2; the browser game's sim/figureLegs.ts rules): `read` turns a Character between
## its last two ticks into the lower body's targets, and `settle` moves the blends towards them at the browser's settle
## times (an exponential step: about two thirds of the way in each settle time). Pure: no node, nothing allocated per
## call; one per figure, reused every frame. FigureBody plays it.

## The step in the figure's own frame (m/s; x to its right, y ahead): zero below the walking speed (still).
var gait: Vector2 = Vector2.ZERO
## Crouched (0..1), the walk cycle (rad, never wrapped) and the lean (-1..1), between the ticks.
var crouch: float = 0.0
var cycle: float = 0.0
var lean: float = 0.0
## A crouched step going backwards: the crouched walk plays in reverse.
var backward: bool = false
## Each layer's target (0 or 1) and where in its clip it is: in the air (Jump, s), vaulting (Vault, share 0..1),
## calling the hit (HitCall, s), walking off (WalkOff, its pace scaled to walk_off_speed).
var jump: float = 0.0
var jump_time: float = 0.0
var vault: float = 0.0
var vault_share: float = 0.0
var call: float = 0.0
var call_time: float = 0.0
var walk_off: float = 0.0
var walk_off_speed: float = 0.0
## The blends as eased: the step's speed (m/s) and way (unit, the figure's frame), and each layer's weight.
var speed: float = 0.0
var way: Vector2 = Vector2(0.0, 1.0)
var jump_weight: float = 0.0
var vault_weight: float = 0.0
var call_weight: float = 0.0
var walk_off_weight: float = 0.0
## The speed below which the legs stand (HitConfig.walking_speed, as the hit volume's legs).
var still_speed: float = 0.0
var _config: FigureConfig = null


func _init(config: FigureConfig) -> void:
	_config = config


## The figures' tuning this reads.
func config() -> FigureConfig:
	return _config


## The targets for `c` at `fraction` of the way from its last tick to this one, by `hits`' rules.
func read(c: Character, fraction: float, hits: HitConfig) -> void:
	var yaw := lerp_angle(c.prev_yaw, c.yaw, fraction)
	var sin_yaw := sin(yaw)
	var cos_yaw := cos(yaw)
	var ahead := -c.velocity.x * sin_yaw - c.velocity.z * cos_yaw
	var right := c.velocity.x * cos_yaw - c.velocity.z * sin_yaw
	var moving := Vector2(c.velocity.x, c.velocity.z).length()
	still_speed = hits.walking_speed
	gait = Vector2(right, ahead) if moving > still_speed else Vector2.ZERO
	crouch = lerpf(c.prev_crouch_amount, c.crouch_amount, fraction)
	cycle = lerpf(c.prev_walk_cycle, c.walk_cycle, fraction)
	lean = lerpf(c.prev_lean, c.lean, fraction)
	backward = crouch > _config.back_crouched and ahead < -_config.back_share * moving
	var alive := c.status == Character.Status.ALIVE
	var vaulting := alive and c.vault.active
	jump = 1.0 if alive and not c.grounded and not vaulting else 0.0
	jump_time = minf(_config.jump_to, _config.jump_from + maxf(c.air_time, 0.0))
	vault = 1.0 if vaulting else 0.0
	vault_share = vault_progress(c.vault, _config.vault_top) if vaulting else 0.0
	call = 1.0 if c.status == Character.Status.CALLING else 0.0
	call_time = c.status_time if call > 0.0 else 0.0
	var off := c.status == Character.Status.WALKING_OFF or c.status == Character.Status.LEAVING
	walk_off = 1.0 if off else 0.0
	walk_off_speed = hits.walk_off_speed


## Moves the eased blends `delta` seconds towards the targets.
func settle(delta: float) -> void:
	var target_speed := gait.length()
	speed = lerpf(speed, target_speed, settle_share(delta, _config.settle_move))
	if target_speed > 0.0:
		var turned := way.lerp(gait / target_speed, settle_share(delta, _config.settle_direction))
		if turned.length_squared() > 0.0:
			way = turned.normalized()
	var mode := settle_share(delta, _config.settle_mode)
	call_weight = lerpf(call_weight, call, mode)
	walk_off_weight = lerpf(walk_off_weight, walk_off, mode)
	jump_weight = lerpf(jump_weight, jump, settle_share(delta, _config.settle_jump))
	vault_weight = lerpf(vault_weight, vault, settle_share(delta, _config.settle_vault))


## The blends set to the targets at once: a figure's first frame, or its first after its legs were left still (hidden).
func snap() -> void:
	speed = gait.length()
	if speed > 0.0:
		way = gait / speed
	jump_weight = jump
	vault_weight = vault
	call_weight = call
	walk_off_weight = walk_off


## The eased step (m/s, the figure's frame): where the gait blend stands.
func gait_position() -> Vector2:
	return way * speed


## Whether the legs step: the walk cycle sets the stepping clips' place (below it they run free, so Idle breathes).
func stepping() -> bool:
	return speed > still_speed


## The share of the way to the target `delta` seconds of easing covers with settle time `settle` (s).
static func settle_share(delta: float, settle: float) -> float:
	return 1.0 - exp(-delta / settle) if settle > 0.0 else 1.0


## Where in the Vault clip (0..1) vault `v` is: its first `top` over the rise onto the top, the rest across it to the
## hand-over to the fall, so the hop keeps to the body's path whatever the obstacle (the browser's vaultClipShare).
static func vault_progress(v: VaultState, top: float) -> float:
	if v.time < v.rise_end:
		return clampf(top * v.time / v.rise_end, 0.0, 1.0) if v.rise_end > 0.0 else top
	var span := v.end - v.rise_end
	return clampf(top + (1.0 - top) * (v.time - v.rise_end) / span, 0.0, 1.0) if span > 0.0 else 1.0
