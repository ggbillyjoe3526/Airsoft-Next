shader_type canvas_item;
// Retro pixels: the screen in blocks of pixel_size, each block's colour cut to `shades` levels a channel with a 4x4
// ordered dither on the block grid (the browser game's render/retroFilter.ts).

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float pixel_size = 4.0;
uniform float shades = 6.0;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 block = SCREEN_PIXEL_SIZE * pixel_size;
	vec2 cell = floor(SCREEN_UV / block);
	vec3 c = textureLod(screen, (cell + 0.5) * block, 0.0).rgb;
	ivec2 b = ivec2(mod(cell, 4.0));
	float dither = (BAYER[b.y * 4 + b.x] + 0.5) / 16.0;
	float top = shades - 1.0;
	COLOR = vec4(clamp(floor(c * top + dither) / top, 0.0, 1.0), 1.0);
}
