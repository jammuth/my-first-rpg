class_name DustTrail
extends GPUParticles3D

## Dust kicked up behind the truck's rear wheels: more with speed, much less on asphalt.

@export var max_puffs := 140
@export var puff_size := 2.2
@export var color := Color(0.88, 0.75, 0.52, 0.45)
## Below this speed (m/s) nothing is kicked up.
@export var min_speed := 1.5
@export var paved_factor := 0.2
## Seconds between surface (road/off-road) checks; cheap but not free.
@export var surface_check_interval := 0.25

var _truck: Truck
var _surface_factor := 1.0
var _surface_timer := 0.0


func _ready() -> void:
	add_to_group("origin_shift_listeners")
	_truck = get_parent() as Truck
	amount = max_puffs
	lifetime = 2.6
	local_coords = false
	emitting = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(Vector3(-40, -5, -40), Vector3(80, 20, 80))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.6, 0.2, 0.4)
	# Local +Z is behind the truck (it drives toward -Z); kick dust back and up.
	pm.direction = Vector3(0.0, 0.45, 1.0)
	pm.spread = 30.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.0
	# A light push downwind plus slight sinking, applied in world space.
	pm.gravity = DustPuffs.wind() * 0.9 + Vector3(0, -0.25, 0)
	pm.damping_min = 0.8
	pm.damping_max = 1.6
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(1.0, 1.0))
	var grow_tex := CurveTexture.new()
	grow_tex.curve = grow
	pm.scale_curve = grow_tex
	pm.color_ramp = DustPuffs.fade_ramp(0.1, 0.45)
	process_material = pm
	draw_pass_1 = DustPuffs.puff_mesh(puff_size, color)


func _process(delta: float) -> void:
	if _truck == null or _truck.terrain == null:
		return
	_surface_timer -= delta
	if _surface_timer <= 0.0:
		_surface_timer = surface_check_interval
		_surface_factor = paved_factor if _on_pavement() else 1.0
	var ratio := emission_ratio(absf(_truck.speed), _truck.max_speed, min_speed) * _surface_factor
	emitting = ratio > 0.0
	amount_ratio = clampf(ratio, 0.0, 1.0)


## Fraction of max_puffs to emit at `speed`: 0 below min_speed, rising to 1 at top speed.
static func emission_ratio(speed: float, top_speed: float, min_speed: float) -> float:
	if speed < min_speed:
		return 0.0
	return clampf((speed - min_speed) / maxf(top_speed - min_speed, 0.001), 0.0, 1.0) * 0.85 + 0.15


func _on_pavement() -> bool:
	var w := global_position + GameState.origin
	var p := Vector2(w.x, w.z)
	var cell := ChunkMath.world_to_cell(w, ChunkGenerator.CHUNK_SIZE)
	var inf := _truck.terrain.influences_for_cell(cell)
	var pads := []
	for e: Dictionary in inf.pois:
		var poi: PoiData = e.poi
		if not RoadNetwork.directions_at(_truck.terrain.world_seed, poi.cell).is_empty():
			pads.append({"centre": poi.position_2d(), "radius": ChunkGenerator.poi_junction_radius(_truck.terrain.world_seed, poi.cell)})
	return RoadNetwork.is_paved(p, inf.roads, pads)


## World-space particles can't follow an origin shift; drop the old trail.
func on_origin_shifted(_shift: Vector3) -> void:
	restart()
