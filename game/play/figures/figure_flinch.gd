class_name FigureFlinch
extends RefCounted
## A figure's hit flinch (step 23, FI5; the browser game's CHARACTERS.flinch): the upper body jolts the way the BB flew,
## FigureConfig.flinch_lean radians, in over flinch_rise seconds, then eased back over flinch_time. The tilt is a vector
## in the figure's frame (x to its right, -z ahead, flat): its way is where the top of the upper body goes, its length
## the angle. A second hit before the first has eased back starts from the tilt drawn now, so two hits never stack past
## flinch_lean. Pure and allocation-free: FigureView feeds it the hit and the frames' time, and draws `tilt()` through
## FigureBend about the hip pivot. Presentation only: no hit volume or sight line moves.

var _config: FigureConfig = null
## The tilt the rise starts from and the one it reaches (rad, figure frame), and the time since the hit (s); -1: none.
var _from: Vector3 = Vector3.ZERO
var _to: Vector3 = Vector3.ZERO
var _age: float = -1.0


func _init(config: FigureConfig) -> void:
	_config = config


## A BB flying along `way` (the figure's frame) hit it: the jolt starts, from the tilt drawn now, the lean scaled by
## the flat share of the way (a steep BB jolts it less). A BB with no flat way (straight down) leaves it as it is.
func hit(way: Vector3) -> void:
	var flat := Vector3(way.x, 0.0, way.z)
	if flat.length_squared() < 1e-8:
		return
	_from = tilt()
	_to = flat / way.length() * _config.flinch_lean
	_age = 0.0


## No flinch from now on (a new round or match: the figure stands at its spawn).
func reset() -> void:
	_age = -1.0
	_from = Vector3.ZERO
	_to = Vector3.ZERO


## `delta` seconds on (a hidden or far figure's frames count all the same).
func advance(delta: float) -> void:
	if _age < 0.0:
		return
	_age += maxf(delta, 0.0)
	if _age >= _config.flinch_rise + _config.flinch_time:
		_age = -1.0


## The tilt drawn now (rad, figure frame): zero when no flinch runs.
func tilt() -> Vector3:
	if _age < 0.0:
		return Vector3.ZERO
	if _age < _config.flinch_rise:
		return _from.lerp(_to, smoothstep(0.0, _config.flinch_rise, _age))
	return _to * (1.0 - smoothstep(0.0, _config.flinch_time, _age - _config.flinch_rise))


## True while a flinch is drawn.
func running() -> bool:
	return _age >= 0.0


## The turn that tips the upright +Y by `tilt_now` (rad, its way flat): about the flat axis square to it.
static func turn(tilt_now: Vector3) -> Basis:
	var angle := tilt_now.length()
	if angle <= 0.0:
		return Basis.IDENTITY
	return Basis(Vector3.UP.cross(tilt_now / angle), angle)

