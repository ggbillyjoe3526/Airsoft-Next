class_name ShaderPrewarm
extends Node3D
## Draws each material the field shows only later (a figure fading out, a BB, a puff, an optic's glass, the "HIT!" sign) as a speck just
## in front of the camera for the first few frames, so their shaders compile while the player is still clicking in,
## not on the first shot or the first walk-off. It frees itself when done.

## How long the specks are drawn (frames) and where (m in front of the eye, and their size).
const FRAMES := 3
const DISTANCE := 1.0
const SPECK := 0.001

var _left: int = FRAMES


## Hangs the specks under `camera`: one quad per material and `sign`, a Label3D set up like the real ones.
func setup(camera: Camera3D, materials: Array[Material], sign: Label3D) -> void:
	name = "ShaderPrewarm"
	position = Vector3(0.0, 0.0, -DISTANCE)
	scale = Vector3.ONE * SPECK
	var quad := QuadMesh.new()
	for m in materials:
		var speck := MeshInstance3D.new()
		speck.mesh = quad
		speck.material_override = m
		speck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(speck)
	sign.visible = true
	add_child(sign)
	camera.add_child(self)


func _process(_delta: float) -> void:
	_left -= 1
	if _left <= 0:
		queue_free()
