class_name BlowingSand
extends GPUParticles3D

## Sparse dust puffs carried by the global wind, kept in a box around the target. Particles live in
## world space so they keep drifting naturally while the emitter follows the truck.

@export var target_path: NodePath
@export var area_size := Vector3(140, 6, 140)
@export var puff_count := 260
@export var puff_size := 1.6
@export var color := Color(0.95, 0.83, 0.58, 0.22)

var _target: Node3D


func _ready() -> void:
	add_to_group("origin_shift_listeners")
	_target = get_node(target_path)
	var wind: Vector2 = ProjectSettings.get_setting("shader_globals/wind_direction").value
	var strength: float = ProjectSettings.get_setting("shader_globals/wind_strength").value
	wind = wind.normalized()

	amount = puff_count
	lifetime = 5.0
	preprocess = 5.0
	local_coords = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(-area_size, area_size * 2.0)

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = area_size * 0.5
	pm.direction = Vector3(wind.x, 0.05, wind.y)
	pm.spread = 12.0
	pm.initial_velocity_min = 7.0 * strength
	pm.initial_velocity_max = 13.0 * strength
	pm.gravity = Vector3(0, -0.2, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 6.0
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.15
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.25, Color(1, 1, 1, 1))
	fade.add_point(0.75, Color(1, 1, 1, 1))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	process_material = pm

	var puff := Gradient.new()
	puff.set_color(0, Color(1, 1, 1, 1))
	puff.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = puff
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * puff_size
	quad.material = mat
	draw_pass_1 = quad


func _process(_delta: float) -> void:
	global_position = _target.global_position + Vector3(0, area_size.y * 0.5, 0)


## World-space particles can't be moved with the world, so start fresh after an origin shift.
func on_origin_shifted(_shift: Vector3) -> void:
	global_position = _target.global_position + Vector3(0, area_size.y * 0.5, 0)
	restart()
