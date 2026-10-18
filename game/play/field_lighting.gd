class_name FieldLighting
## The field's light and sky from a LightingConfig (docs/ART.md › Light): a WorldEnvironment with the procedural sky
## (which also gives polymer and steel their sheen) and one DirectionalLight3D sun with soft, short shadows.


## A node holding the environment and the sun.
static func build(cfg: LightingConfig) -> Node3D:
	var root := Node3D.new()
	root.name = "Lighting"
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = cfg.sky_top
	sky_mat.sky_horizon_color = cfg.sky_horizon
	sky_mat.ground_horizon_color = cfg.ground_horizon
	sky_mat.ground_bottom_color = cfg.ground_bottom
	var sky := Sky.new()
	sky.sky_material = sky_mat
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
	var world := WorldEnvironment.new()
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
	return root
