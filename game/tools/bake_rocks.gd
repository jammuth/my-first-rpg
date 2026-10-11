extends SceneTree

## Bakes the Poly Haven boulder scans in art_source/ into lightweight meshes for MultiMesh props.
## Re-run after changing TARGET_TRIS:
##   godot --headless --path game -s res://tools/bake_rocks.gd

const SOURCES := ["02", "04", "05"]
const TARGET_TRIS := 1500
const OUT_DIR := "res://assets/models/rocks/"
# Pull the photographed colour slightly toward the cliff palette so rocks and mesas read as one set.
const TINT := Color(1.0, 0.93, 0.84)


func _initialize() -> void:
	var failed := false
	for n: String in SOURCES:
		var src := ProjectSettings.globalize_path("res://") + \
			"../art_source/polyhaven_namaqualand_boulder_%s/namaqualand_boulder_%s.gltf" % [n, n]
		var mesh := bake(src, TARGET_TRIS)
		if mesh == null:
			failed = true
			continue
		mesh.surface_set_material(0, _material(n))
		var out := OUT_DIR + "boulder_%s.res" % n
		var err := ResourceSaver.save(mesh, out)
		print("%s: %d tris, aabb %s -> %s (err %d)" % [n, mesh.get_faces().size() / 3, mesh.get_aabb(), out, err])
		failed = failed or err != OK
	quit(1 if failed else 0)


static func bake(gltf_path: String, target_tris: int) -> ArrayMesh:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(gltf_path, state) != OK or state.meshes.is_empty():
		push_error("cannot load " + gltf_path)
		return null
	var im: ImporterMesh = state.meshes[0].mesh
	im.generate_lods(25.0, 60.0, [])
	var arrays := im.get_surface_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for lod in im.get_surface_lod_count(0):
		var lod_indices := im.get_surface_lod_indices(0, lod)
		if lod_indices.size() / 3 < target_tris:
			break
		indices = lod_indices
	return build_compact(arrays, indices)


## Keeps only the vertices referenced by `indices` (LOD index lists still point into the full
## vertex buffer) and generates tangents for normal mapping.
static func build_compact(arrays: Array, indices: PackedInt32Array) -> ArrayMesh:
	var src_v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var src_n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var src_uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var remap := {}
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for old in indices:
		if not remap.has(old):
			remap[old] = remap.size()
			st.set_normal(src_n[old])
			st.set_uv(src_uv[old])
			st.add_vertex(src_v[old])
	for old in indices:
		st.add_index(remap[old])
	st.generate_tangents()
	return st.commit()


func _material(n: String) -> ORMMaterial3D:
	var mat := ORMMaterial3D.new()
	var tex := OUT_DIR + "textures/boulder_%s_" % n
	mat.albedo_texture = load(tex + "diff.jpg")
	mat.albedo_color = TINT
	mat.normal_enabled = true
	mat.normal_texture = load(tex + "nor_gl.jpg")
	mat.orm_texture = load(tex + "arm.jpg")
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat
