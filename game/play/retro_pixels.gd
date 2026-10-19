class_name RetroPixels
extends CanvasLayer
## The Dev settings' Retro pixels (the browser game's render/retroFilter.ts): the 3D view in chunky pixels and a small
## dithered palette, drawn over the view and under the HUD. Changes only what you see. Built only while it is on.

## Screen pixels per retro pixel, and shades of each of red, green and blue (the browser's defaults).
const PIXEL_SIZE := 4.0
const SHADES := 6.0
const SHADER := preload("res://game/play/retro_pixels.gdshader")


func _ready() -> void:
	name = "RetroPixels"
	# Under the HUD's layer (the default 1), over the 3D view.
	layer = 0
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"pixel_size", PIXEL_SIZE)
	mat.set_shader_parameter(&"shades", SHADES)
	rect.material = mat
	add_child(rect)
