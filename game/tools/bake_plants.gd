extends SceneTree

## Bakes dead-branch scans (Poly Haven) and cacti (Quaternius) from art_source/ into lightweight meshes
## for MultiMesh props. Two phases because materials need the generated textures imported first;
## tools/bake_plants.sh runs: textures -> import -> meshes.

const BakeRocks := preload("res://tools/bake_rocks.gd")
const OUT_DIR := "res://assets/models/plants/"
const TEX_DIR := OUT_DIR + "textures/"
# Slightly sun-bleached so the scanned greens sit with the desert palette.
const TINT := Color(1.0, 0.95, 0.86)

## Scanned plants. Surface 0 is the stems/wood; `ratio` is the fraction of triangles kept.
const SCANS := [
	{"id": "dry_branches", "src": "polyhaven_dry_branches_medium_01/dry_branches_medium_01.gltf",
		"nodes": {"a": "dry_branches_medium_01_a"}, "ratio": 0.1},
]
const CACTI := {"barrel": "Cactus_1", "saguaro": "Cactus_2", "saguaro_thin": "Cactus_3", "pear": "Cactus_4"}


func _initialize() -> void:
	var phase := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ""
	var ok := false
	match phase:
		"textures":
			ok = _bake_textures()
		"meshes":
			ok = _bake_meshes()
		_:
			push_error("usage: -s res://tools/bake_plants.gd -- textures|meshes")
	quit(0 if ok else 1)


static func art_source() -> String:
	return ProjectSettings.globalize_path("res://") + "../art_source/"


func _bake_textures() -> bool:
	for scan: Dictionary in SCANS:
		var folder: String = art_source() + scan.src.get_base_dir() + "/textures/"
		var name: String = scan.src.get_file().get_basename()
		for map in ["diff", "nor_gl", "arm"]:
			DirAccess.copy_absolute(folder + name + "_%s_1k.jpg" % map,
				ProjectSettings.globalize_path(TEX_DIR + scan.id + "_%s.jpg" % map))
		print("textures: ", scan.id)
	return true


func _bake_meshes() -> bool:
	var ok := true
	for scan: Dictionary in SCANS:
		var state := _load(art_source() + scan.src)
		if state == null:
			return false
		var material := _scan_material(scan.id)
		for letter: String in scan.nodes:
			var mesh := bake_node(state, scan.nodes[letter], scan.ratio)
			if mesh == null:
				ok = false
				continue
			for s in mesh.get_surface_count():
				mesh.surface_set_material(s, material)
			ok = _save(mesh, "%s_%s" % [scan.id, letter]) and ok
	for id: String in CACTI:
		var state := _load(art_source() + "quaternius_ultimate_nature/%s.fbx" % CACTI[id])
		if state == null:
			return false
		var mesh := bake_node(state, CACTI[id], 1.0)
		if mesh == null:
			ok = false
			continue
		for s in mesh.get_surface_count():
			mesh.surface_set_material(s, _cactus_material(s))
		ok = _save(mesh, "cactus_" + id) and ok
	return ok


func _save(mesh: ArrayMesh, name: String) -> bool:
	var path := OUT_DIR + name + ".res"
	var err := ResourceSaver.save(mesh, path)
	print("%s: %d tris in %d surfaces, size %s (err %d)" % [name, mesh.get_faces().size() / 3,
		mesh.get_surface_count(), mesh.get_aabb().size, err])
	return err == OK


static func _load(path: String) -> GLTFState:
	var fbx := path.ends_with(".fbx")
	var doc: GLTFDocument = FBXDocument.new() if fbx else GLTFDocument.new()
	var state: GLTFState = FBXState.new() if fbx else GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		push_error("cannot load " + path)
		return null
	return state


## Bakes one node's mesh: applies its rotation/scale (sources differ in up-axis and units) but not
## its position (scan variants are laid out side by side), centres it on X/Z, and decimates every
## surface to `ratio` of its triangles. Surfaces (and their materials) are kept separate.
static func bake_node(state: GLTFState, node_name: String, ratio: float) -> ArrayMesh:
	var node: GLTFNode = null
	for n: GLTFNode in state.nodes:
		if n.original_name == node_name and n.mesh >= 0:
			node = n
	if node == null:
		push_error("node not found: " + node_name)
		return null
	var basis := Basis(node.rotation).scaled(node.scale)
	var im: ImporterMesh = state.meshes[node.mesh].mesh
	im.generate_lods(25.0, 60.0, [])
	var parts: Array = []
	for s in im.get_surface_count():
		var arrays := im.get_surface_arrays(s)
		parts.append({"arrays": _transformed(arrays, basis), "indices": _lod_indices(im, s, arrays, ratio)})
	var centre := _centre_xz(parts)
	var mesh := ArrayMesh.new()
	for part: Dictionary in parts:
		var merged := _merge([part], centre)
		var part_mesh := BakeRocks.build_compact(merged.arrays, merged.indices)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, part_mesh.surface_get_arrays(0))
	return mesh


static func _lod_indices(im: ImporterMesh, surface: int, arrays: Array, ratio: float) -> PackedInt32Array:
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var target := int(indices.size() * ratio)
	for lod in im.get_surface_lod_count(surface):
		var lod_indices := im.get_surface_lod_indices(surface, lod)
		if lod_indices.size() < target:
			break
		indices = lod_indices
	return indices


static func _transformed(arrays: Array, basis: Basis) -> Array:
	var out := arrays.duplicate()
	var v: PackedVector3Array = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).duplicate()
	var n: PackedVector3Array = (arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate()
	var normal_basis := basis.inverse().transposed()
	for i in v.size():
		v[i] = basis * v[i]
		n[i] = (normal_basis * n[i]).normalized()
	out[Mesh.ARRAY_VERTEX] = v
	out[Mesh.ARRAY_NORMAL] = n
	if out[Mesh.ARRAY_TEX_UV] == null:
		var uv := PackedVector2Array()
		uv.resize(v.size())
		out[Mesh.ARRAY_TEX_UV] = uv
	return out


static func _centre_xz(parts: Array) -> Vector3:
	var box := AABB()
	var first := true
	for part: Dictionary in parts:
		var v: PackedVector3Array = part.arrays[Mesh.ARRAY_VERTEX]
		for i in part.indices:
			box = AABB(v[i], Vector3.ZERO) if first else box.expand(v[i])
			first = false
	var c := box.get_center()
	return Vector3(c.x, 0.0, c.z)


static func _merge(group: Array, centre: Vector3) -> Dictionary:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	for part: Dictionary in group:
		var base := v.size()
		var pv: PackedVector3Array = part.arrays[Mesh.ARRAY_VERTEX]
		for p in pv:
			v.append(p - centre)
		n.append_array(part.arrays[Mesh.ARRAY_NORMAL])
		uv.append_array(part.arrays[Mesh.ARRAY_TEX_UV])
		for i: int in part.indices:
			idx.append(base + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_TEX_UV] = uv
	return {"arrays": arrays, "indices": idx}


func _scan_material(id: String) -> ORMMaterial3D:
	var mat := ORMMaterial3D.new()
	mat.albedo_texture = load(TEX_DIR + id + "_diff.jpg")
	mat.albedo_color = TINT
	mat.normal_enabled = true
	mat.normal_texture = load(TEX_DIR + id + "_nor_gl.jpg")
	mat.orm_texture = load(TEX_DIR + id + "_arm.jpg")
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


func _cactus_material(surface: int) -> Material:
	if surface > 0:
		# Spines/flowers: keep the source's flat colour.
		var spines := StandardMaterial3D.new()
		spines.albedo_color = Color(0.82, 0.70, 0.50)
		spines.roughness = 0.8
		return spines
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/cactus.gdshader")
	return mat
