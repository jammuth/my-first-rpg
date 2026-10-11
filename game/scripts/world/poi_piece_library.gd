class_name PoiPieceLibrary
extends RefCounted

## Main-thread cache of POI piece scenes, their bounds, and weathered versions of their materials.

const WEATHERED := preload("res://shaders/weathered.gdshader")

var _info := {}
var _materials := {}


## {scene: PackedScene, aabb: AABB (unscaled, in the scene's own space)}
func get_info(key: String) -> Dictionary:
	if not _info.has(key):
		var scene: PackedScene = load(PoiCatalog.piece(key).path)
		var root: Node3D = scene.instantiate()
		_info[key] = {"scene": scene, "aabb": scene_aabb(root)}
		root.free()
	return _info[key]


static func scene_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var xform := Transform3D.IDENTITY
		var n: Node = mi
		while n != root:
			xform = (n as Node3D).transform * xform
			n = n.get_parent()
		var box := xform * mi.mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result


## Replaces each surface's material with a shared weathered equivalent (same colour/texture).
func apply_weathering(mi: MeshInstance3D) -> void:
	for s in mi.mesh.get_surface_count():
		var source := mi.get_active_material(s)
		var key := source.get_rid() if source != null else RID()
		if not _materials.has(key):
			_materials[key] = weathered_material(source)
		mi.set_surface_override_material(s, _materials[key])


static func weathered_material(source: Material) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WEATHERED
	if source is BaseMaterial3D:
		mat.set_shader_parameter("albedo", source.albedo_color)
		if source.albedo_texture != null:
			mat.set_shader_parameter("albedo_texture", source.albedo_texture)
			mat.set_shader_parameter("use_texture", true)
	return mat
