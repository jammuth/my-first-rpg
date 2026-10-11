class_name ChunkManager
extends Node3D

## Streams two layers around a target: terrain meshes (wide radius, LOD by ring) and chunk content
## (roads, props, POIs; narrower radius). All generation runs on WorkerThreadPool as pure data and
## is turned into nodes on the main thread, a capped number per frame, to avoid hitches.

const CONTENT := -1
const TERRAIN_TEXTURES := "res://assets/textures/terrain/"
const ROAD_TEXTURES := "res://assets/textures/road/"
const PROP_VIEW_DISTANCE := 250.0

@export var target_path: NodePath
@export var content_radius := 2
## Unload radii exceed load radii so driving back and forth over a chunk edge doesn't thrash.
@export var content_unload_radius := 3
@export var terrain_radius := 4
@export var terrain_unload_radius := 5
@export var max_builds_per_frame := 2
@export var max_tasks_in_flight := 6

var world_seed: int
## Main-thread sampler for gameplay height queries (truck, camera).
var terrain: TerrainSampler

var _target: Node3D
var _content := {}
## cell -> {node: MeshInstance3D, lod: int}
var _terrain := {}
## Vector3i(cell.x, cell.y, lod or CONTENT) -> task id
var _tasks := {}
var _ready_queue: Array = []
var _finished: Array = []
var _mutex := Mutex.new()
var _props := PropLibrary.new()
var _poi_pieces := PoiPieceLibrary.new()
var _prop_defs := {}
var _road_material: ShaderMaterial
var _terrain_material: ShaderMaterial


func _ready() -> void:
	world_seed = GameState.world_seed
	terrain = TerrainSampler.new(world_seed)
	_target = get_node(target_path)
	var biome := BiomeMap.biome_at_cell(world_seed, Vector2i.ZERO)
	_terrain_material = _ground_material(preload("res://shaders/terrain.gdshader"), biome)
	for map in ["cliff_color", "cliff_normal", "cliff_roughness"]:
		_terrain_material.set_shader_parameter(map, load(TERRAIN_TEXTURES + map + ".jpg"))
	_road_material = _ground_material(preload("res://shaders/road.gdshader"), biome)
	for map in ["asphalt_color", "asphalt_normal", "asphalt_roughness"]:
		_road_material.set_shader_parameter(map, load(ROAD_TEXTURES + map + ".jpg"))
	# Build the immediate surroundings synchronously so the first frame isn't empty.
	var center := _center_cell()
	for cell in ChunkMath.cells_in_radius(center, 1):
		_build_terrain(TerrainMesher.build(terrain, cell, 0))
		_build_content(ChunkGenerator.generate(world_seed, cell, terrain))


## Terrain and road share the desert sand surface, so both get the same sand inputs.
func _ground_material(shader: Shader, biome: Biome) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("color_a", biome.ground_color_a)
	mat.set_shader_parameter("color_b", biome.ground_color_b)
	for map in ["sand_color", "sand_normal", "sand_roughness"]:
		mat.set_shader_parameter(map, load(TERRAIN_TEXTURES + map + ".jpg"))
	return mat


func _exit_tree() -> void:
	for id in _tasks.values():
		WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()


func _process(_delta: float) -> void:
	var center := _center_cell()
	_unload_far(center)
	_collect_finished(center)
	_submit_missing(center)
	for i in mini(max_builds_per_frame, _ready_queue.size()):
		var item: Variant = _ready_queue.pop_front()
		if item is TerrainChunkData:
			_build_terrain(item)
		else:
			_build_content(item)


func loaded_chunk_count() -> int:
	return _content.size()


func loaded_terrain_count() -> int:
	return _terrain.size()


func _center_cell() -> Vector2i:
	return ChunkMath.world_to_cell(_target.global_position, ChunkGenerator.CHUNK_SIZE)


func _unload_far(center: Vector2i) -> void:
	for cell: Vector2i in _content.keys():
		if ChunkMath.chebyshev(cell, center) > content_unload_radius:
			_content[cell].queue_free()
			_content.erase(cell)
	for cell: Vector2i in _terrain.keys():
		if ChunkMath.chebyshev(cell, center) > terrain_unload_radius:
			_terrain[cell].node.queue_free()
			_terrain.erase(cell)


func _still_wanted(item: Variant, center: Vector2i) -> bool:
	var ring := ChunkMath.chebyshev(item.cell, center)
	if item is TerrainChunkData:
		if ring > terrain_unload_radius:
			return false
		# A stale LOD is still better than a hole while the right one is generated.
		return item.lod == TerrainMesher.lod_for_ring(ring) or not _terrain.has(item.cell)
	return ring <= content_unload_radius


func _collect_finished(center: Vector2i) -> void:
	_mutex.lock()
	var finished := _finished
	_finished = []
	_mutex.unlock()
	for item: Variant in finished:
		var key := _key_for(item)
		# Tasks must be waited on to release their resources; they're already done, so this is instant.
		WorkerThreadPool.wait_for_task_completion(_tasks[key])
		_tasks.erase(key)
		_ready_queue.append(item)
	_ready_queue = _ready_queue.filter(func(item: Variant) -> bool: return _still_wanted(item, center))
	_ready_queue.sort_custom(func(a: Variant, b: Variant) -> bool:
		return (a.cell - center).length_squared() < (b.cell - center).length_squared())


func _key_for(item: Variant) -> Vector3i:
	if item is TerrainChunkData:
		return Vector3i(item.cell.x, item.cell.y, item.lod)
	return Vector3i(item.cell.x, item.cell.y, CONTENT)


func _submit_missing(center: Vector2i) -> void:
	var queued := {}
	for item: Variant in _ready_queue:
		queued[_key_for(item)] = true
	for cell in ChunkMath.cells_in_radius(center, terrain_radius):
		if _tasks.size() >= max_tasks_in_flight:
			return
		var ring := ChunkMath.chebyshev(cell, center)
		var lod := TerrainMesher.lod_for_ring(ring)
		var tkey := Vector3i(cell.x, cell.y, lod)
		var has_lod: bool = _terrain.has(cell) and _terrain[cell].lod == lod
		if not has_lod and not _tasks.has(tkey) and not queued.has(tkey):
			_tasks[tkey] = WorkerThreadPool.add_task(_terrain_task.bind(cell, lod, world_seed), false, "terrain")
		if ring > content_radius or _tasks.size() >= max_tasks_in_flight:
			continue
		var ckey := Vector3i(cell.x, cell.y, CONTENT)
		if not _content.has(cell) and not _tasks.has(ckey) and not queued.has(ckey):
			_tasks[ckey] = WorkerThreadPool.add_task(_content_task.bind(cell, world_seed), false, "chunk")


func _terrain_task(cell: Vector2i, lod: int, seed_value: int) -> void:
	var data := TerrainMesher.build(TerrainSampler.new(seed_value), cell, lod)
	_mutex.lock()
	_finished.append(data)
	_mutex.unlock()


func _content_task(cell: Vector2i, seed_value: int) -> void:
	var data := ChunkGenerator.generate(seed_value, cell)
	_mutex.lock()
	_finished.append(data)
	_mutex.unlock()


func _build_terrain(data: TerrainChunkData) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data.vertices
	arrays[Mesh.ARRAY_NORMAL] = data.normals
	arrays[Mesh.ARRAY_INDEX] = data.indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _terrain_material)
	var node := MeshInstance3D.new()
	node.name = "Terrain_%d_%d" % [data.cell.x, data.cell.y]
	node.mesh = mesh
	if data.lod > 0:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	if _terrain.has(data.cell):
		_terrain[data.cell].node.queue_free()
	_terrain[data.cell] = {"node": node, "lod": data.lod}


func _build_content(data: ChunkData) -> void:
	if _content.has(data.cell):
		return
	var chunk := Node3D.new()
	chunk.name = "Chunk_%d_%d" % [data.cell.x, data.cell.y]

	if not data.road_vertices.is_empty():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = data.road_vertices
		arrays[Mesh.ARRAY_TEX_UV] = data.road_uvs
		arrays[Mesh.ARRAY_TEX_UV2] = data.road_uv2s
		arrays[Mesh.ARRAY_INDEX] = data.road_indices
		var normals := PackedVector3Array()
		normals.resize(data.road_vertices.size())
		normals.fill(Vector3.UP)
		arrays[Mesh.ARRAY_NORMAL] = normals
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, _road_material)
		var road := MeshInstance3D.new()
		road.mesh = mesh
		road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chunk.add_child(road)

	var biome := BiomeMap.biome_at_cell(world_seed, data.cell)
	for prop_id: String in data.props:
		var def := _prop_def(biome, prop_id)
		var entry := _props.get_entry(def.path)
		var transforms: Array = data.props[prop_id]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = entry.mesh
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i] * entry.transform)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		# Props are small next to the fogged-out view distance; skipping far ones saves triangles.
		mmi.visibility_range_end = def.get("view_distance", PROP_VIEW_DISTANCE)
		mmi.visibility_range_end_margin = 20.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		chunk.add_child(mmi)

	if not data.solids.is_empty():
		var body := StaticBody3D.new()
		for solid in data.solids:
			var shape := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = solid.radius
			cyl.height = 4.0
			shape.shape = cyl
			shape.position = solid.position + Vector3(0, 2, 0)
			body.add_child(shape)
		chunk.add_child(body)

	for poi in data.pois:
		chunk.add_child(PoiSite.create(poi, _poi_pieces))

	add_child(chunk)
	_content[data.cell] = chunk


func _prop_def(biome: Biome, prop_id: String) -> Dictionary:
	var key := biome.id + "/" + prop_id
	if not _prop_defs.has(key):
		for def in biome.props:
			_prop_defs[biome.id + "/" + def.id] = def
	return _prop_defs[key]
