class_name DesertEnvironment
extends RefCounted

## Sky, haze and lighting shared by every outdoor scene (overworld and POIs on foot), plus the
## graphics-preset settings that go with them.


static func apply_graphics(env: Environment, camera: Camera3D, sun: DirectionalLight3D, viewport: Viewport) -> void:
	var view: float = GraphicsSettings.get_value("view_distance")
	env.fog_depth_end = view
	env.fog_depth_begin = view * 0.4
	camera.far = view + 300.0
	sun.directional_shadow_max_distance = GraphicsSettings.get_value("shadow_distance")
	RenderingServer.directional_shadow_atlas_set_size(GraphicsSettings.get_value("shadow_atlas"), true)
	var render_scale: float = GraphicsSettings.get_value("render_scale")
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if render_scale < 1.0 else Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = render_scale


static func make() -> Environment:
	var haze := Color(0.93, 0.80, 0.52)
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.42, 0.58, 0.78)
	sky_mat.sky_horizon_color = Color(0.95, 0.84, 0.60)
	sky_mat.sky_curve = 0.12
	sky_mat.ground_horizon_color = haze
	sky_mat.ground_bottom_color = Color(0.70, 0.56, 0.36)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	# Ambient/reflections only change with time of day, so a slow update keeps the GPU cost negligible.
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = haze
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.35
	env.fog_density = 1.0
	env.fog_depth_curve = 1.6
	# Depth fog distances come from the graphics preset (_apply_graphics).
	# Keeps the upper sky visible when the camera orbits low instead of fogging it out completely.
	env.fog_sky_affect = 0.3
	env.fog_height = -12.0
	env.fog_height_density = 0.02
	return env
