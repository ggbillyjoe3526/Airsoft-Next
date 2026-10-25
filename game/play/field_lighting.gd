class_name FieldLighting
extends Node3D
## The field's light and sky from a LightingConfig (docs/ART.md › Light): a WorldEnvironment with its sky (which also
## gives polymer and steel their sheen) and one DirectionalLight3D, the sun or the moon, with soft, short shadows. By
## day the sky is Godot's procedural one; a night preset draws its own (NIGHT_SKY: the sky's gradient, stars and the
## moon's disc with its halo where the moon is, on every quality preset) and adds its haze. The graphics settings then
## switch the sun's shadows, their range and ambient occlusion in place (GraphicsApply.apply_field).

## The night sky. Stars sit on a grid of directions (`star_grid` cells round), one in `star_share` of the cells lit,
## each a soft dot up to `star_size` radians across; the moon is LIGHT0's direction. The radiance pass (the fill and
## the sheen) takes the gradient alone.
const NIGHT_SKY := """
shader_type sky;

uniform vec3 top : source_color;
uniform vec3 horizon : source_color;
uniform vec3 below : source_color;
uniform float star_grid = 160.0;
uniform float star_share = 0.01;
uniform float star_size = 0.004;
uniform float star_brightness = 0.9;
uniform vec3 moon_colour : source_color;
uniform float moon_size = 0.05;
uniform float halo = 4.5;
uniform float halo_alpha = 0.22;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = EYEDIR;
	vec3 col = d.y >= 0.0 ? mix(horizon, top, sqrt(d.y)) : mix(horizon, below, clamp(-d.y * 4.0, 0.0, 1.0));
	if (!AT_CUBEMAP_PASS) {
		if (d.y > 0.0) {
			vec3 cell = floor(d * star_grid);
			if (hash(cell) < star_share) {
				vec3 jitter = vec3(hash(cell + 1.7), hash(cell + 3.1), hash(cell + 5.3)) * 0.7 + 0.15;
				vec3 star = normalize((cell + jitter) / star_grid);
				float size = star_size * (0.4 + 0.6 * hash(cell + 7.9));
				col += vec3(star_brightness) * smoothstep(size, 0.0, distance(star, d)) * smoothstep(0.0, 0.15, d.y);
			}
		}
		if (LIGHT0_ENABLED) {
			float a = acos(clamp(dot(d, LIGHT0_DIRECTION), -1.0, 1.0));
			float r = moon_size * 0.5;
			col = mix(col, moon_colour, smoothstep(r, r * 0.85, a));
			float glow = 1.0 - smoothstep(r, r * halo, a);
			col += moon_colour * halo_alpha * glow * glow;
		}
	}
	COLOR = col;
}
"""
## The night sky's star grid: cells round each face of the cube of directions.
const STAR_GRID := 160.0

var sun: DirectionalLight3D = null
var environment: Environment = null
var _ssao: bool = false


## A node holding the environment and the sun.
static func build(cfg: LightingConfig) -> FieldLighting:
	var root := FieldLighting.new()
	root.name = "Lighting"
	root._ssao = cfg.ssao
	var sky := Sky.new()
	sky.sky_material = night_sky_material(cfg) if cfg.night_sky() else day_sky_material(cfg)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = cfg.ambient_colour
	env.ambient_light_energy = cfg.ambient_energy
	env.ambient_light_sky_contribution = cfg.sky_contribution
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = cfg.exposure
	env.ssao_enabled = cfg.ssao
	env.ssao_radius = cfg.ssao_radius
	env.ssao_intensity = cfg.ssao_intensity
	if cfg.fog:
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = cfg.fog_colour
		env.fog_density = 1.0
		env.fog_depth_begin = cfg.fog_from
		env.fog_depth_end = cfg.fog_to
		env.fog_sky_affect = cfg.fog_sky
	root.environment = env
	var world := WorldEnvironment.new()
	world.name = "Environment"
	world.environment = env
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-cfg.sun_elevation, cfg.sun_heading, 0.0)
	sun.light_color = cfg.sun_colour
	sun.light_energy = cfg.sun_energy
	sun.shadow_enabled = true
	sun.shadow_blur = cfg.shadow_blur
	sun.directional_shadow_max_distance = cfg.shadow_distance
	root.add_child(sun)
	root.sun = sun
	return root


## The day's procedural sky in `cfg`'s colours.
static func day_sky_material(cfg: LightingConfig) -> ProceduralSkyMaterial:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = cfg.sky_top
	sky_mat.sky_horizon_color = cfg.sky_horizon
	sky_mat.ground_horizon_color = cfg.ground_horizon
	sky_mat.ground_bottom_color = cfg.ground_bottom
	return sky_mat


## The night sky (NIGHT_SKY) in `cfg`'s colours, its stars spread over the upper sky's cells (about 2π grid² of them).
static func night_sky_material(cfg: LightingConfig) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = NIGHT_SKY
	mat.set_shader_parameter(&"top", cfg.sky_top)
	mat.set_shader_parameter(&"horizon", cfg.sky_horizon)
	mat.set_shader_parameter(&"below", cfg.ground_bottom)
	mat.set_shader_parameter(&"star_grid", STAR_GRID)
	mat.set_shader_parameter(&"star_share", clampf(cfg.stars / (TAU * STAR_GRID * STAR_GRID), 0.0, 1.0))
	mat.set_shader_parameter(&"star_size", cfg.star_size)
	mat.set_shader_parameter(&"star_brightness", cfg.star_brightness)
	mat.set_shader_parameter(&"moon_colour", cfg.moon_colour)
	mat.set_shader_parameter(&"moon_size", cfg.moon_size)
	mat.set_shader_parameter(&"halo", cfg.moon_halo)
	mat.set_shader_parameter(&"halo_alpha", cfg.moon_halo_alpha)
	return mat


## True if the config draws ambient occlusion at all; the graphics settings turn it off, never on against it.
func ssao_allowed() -> bool:
	return _ssao
