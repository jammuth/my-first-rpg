class_name Drone
extends Node3D

## The exploration drone: a placeholder quadcopter built from primitives that hovers beside the
## explorer's shoulder. The scanning itself lives in DroneScanner.

const ROTOR_SPEED := 40.0
const BODY_COLOR := Color(0.62, 0.6, 0.52)
const EYE_COLOR := Color(0.35, 0.95, 1.0)

var explorer: Explorer

var _time := 0.0
var _rotors: Array[Node3D] = []


func _ready() -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = BODY_COLOR
	metal.metallic = 0.6
	metal.roughness = 0.45
	var body := CylinderMesh.new()
	body.top_radius = 0.22
	body.bottom_radius = 0.26
	body.height = 0.12
	_add(body, metal, Vector3.ZERO)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = EYE_COLOR
	eye_mat.emission_enabled = true
	eye_mat.emission = EYE_COLOR
	eye_mat.emission_energy_multiplier = 3.0
	var eye := SphereMesh.new()
	eye.radius = 0.07
	eye.height = 0.14
	# Models face +Z, like the explorer.
	_add(eye, eye_mat, Vector3(0, -0.02, 0.24))
	var arm := BoxMesh.new()
	arm.size = Vector3(0.75, 0.03, 0.05)
	for yaw in [PI * 0.25, -PI * 0.25]:
		_add(arm, metal, Vector3.ZERO).rotation.y = yaw
	var blade := CylinderMesh.new()
	blade.top_radius = 0.13
	blade.bottom_radius = 0.13
	blade.height = 0.01
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.1, 0.1, 0.1, 0.55)
	blade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for corner: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var spot := corner * 0.265
		_rotors.append(_add(blade, blade_mat, Vector3(spot.x, 0.05, spot.y)))
	if explorer != null:
		global_position = DroneMotion.hover_point(explorer.global_position, explorer.facing(), 0.0)


func _process(delta: float) -> void:
	if explorer == null:
		return
	_time += delta
	var target := DroneMotion.hover_point(explorer.global_position, explorer.facing(), _time)
	global_position = DroneMotion.step(global_position, target, delta)
	var f := explorer.facing()
	rotation.y = lerp_angle(rotation.y, atan2(f.x, f.y), 1.0 - exp(-5.0 * delta))
	for r in _rotors:
		r.rotation.y += ROTOR_SPEED * delta


func _add(mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi
