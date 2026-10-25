// A site-dressed map's day sky (DD1, docs/ART.md › Light: "a single warm sun high in a blue sky with soft cumulus"):
// the gradient, soft cumulus from the dress's tiling noise texture, lit on the sun's side, and the sun with its glow.
// The radiance pass (the fill and the sheen) takes it all, so it is drawn once while the sun stands still.
shader_type sky;

uniform vec3 top : source_color = vec3(0.2, 0.42, 0.78);
uniform vec3 horizon : source_color = vec3(0.72, 0.82, 0.92);
uniform vec3 below : source_color = vec3(0.55, 0.52, 0.46);
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.98, 0.95);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.68, 0.78);
uniform float cover = 0.45;
uniform float softness = 0.22;
uniform float cloud_scale = 0.55;
uniform float sun_size = 0.03;
uniform float sun_glow = 0.35;
uniform sampler2D fbm_tex : filter_linear_mipmap, repeat_enable;

float fbm(vec2 p) {
	return texture(fbm_tex, p * 0.125).r;
}

void sky() {
	vec3 d = EYEDIR;
	vec3 col = d.y >= 0.0 ? mix(horizon, top, pow(clamp(d.y, 0.0, 1.0), 0.55))
			: mix(horizon, below, clamp(-d.y * 5.0, 0.0, 1.0));
	vec3 sun_dir = LIGHT0_ENABLED ? LIGHT0_DIRECTION : vec3(0.0, 1.0, 0.0);
	float to_sun = dot(d, sun_dir);
	if (d.y > 0.0) {
		vec2 p = d.xz / (d.y + 0.08) * cloud_scale;
		float shape = fbm(p + vec2(3.1, 1.7)) + (fbm(p * 3.0 + 9.0) - 0.5) * 0.25;
		float c = smoothstep(1.0 - cover, 1.0 - cover + softness, shape);
		vec2 toward = normalize(sun_dir.xz + vec2(0.0001)) * 0.12;
		float lit = clamp((shape - fbm(p + vec2(3.1, 1.7) + toward)) * 4.0 + 0.55, 0.0, 1.0);
		c *= smoothstep(0.0, 0.18, d.y);
		col = mix(col, mix(cloud_shade, cloud_lit, lit), c * 0.95);
	}
	if (LIGHT0_ENABLED) {
		col += LIGHT0_COLOR * sun_glow * pow(max(to_sun, 0.0), 24.0);
		col = mix(col, vec3(1.0, 0.98, 0.9) * 3.0, smoothstep(cos(sun_size), cos(sun_size * 0.7), to_sun));
	}
	COLOR = col;
}
