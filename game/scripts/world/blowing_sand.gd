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
	var wind := DustPuffs.wind()
	var strength := wind.length()
	wind = wind.normalized()

	amount = maxi(1, int(puff_count * GraphicsSettings.get_value("particles")))
	lifetime = 5.0
	preprocess = 5.0
	local_coords = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(-area_size, area_size * 2.0)

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = area_size * 0.5
	pm.direction = Vector3(wind.x, 0.05, wind.z)
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
	pm.color_ramp = DustPuffs.fade_ramp()
	process_material = pm

	draw_pass_1 = DustPuffs.puff_mesh(puff_size, color)


func _process(_delta: float) -> void:
	global_position = _target.global_position + Vector3(0, area_size.y * 0.5, 0)


## World-space particles can't be moved with the world, so start fresh after an origin shift.
func on_origin_shifted(_shift: Vector3) -> void:
	global_position = _target.global_position + Vector3(0, area_size.y * 0.5, 0)
	restart()
