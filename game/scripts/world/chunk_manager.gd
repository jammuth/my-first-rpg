class_name ChunkManager
extends Node3D

## Streams chunks around a target. Content is generated on WorkerThreadPool (pure data only) and
## turned into nodes on the main thread, a capped number per frame, to avoid hitches.

@export var target_path: NodePath
@export var load_radius := 2
## Larger than load_radius so driving back and forth over a chunk edge doesn't thrash.
@export var unload_radius := 3
@export var max_builds_per_frame := 1
@export var max_tasks_in_flight := 4

var world_seed: int
var _target: Node3D
var _chunks := {}
var _tasks := {}
var _ready_queue: Array[ChunkData] = []
var _finished: Array[ChunkData] = []
var _mutex := Mutex.new()
var _props := PropLibrary.new()
var _model_scenes := {}
var _prop_defs := {}
var _road_material: ShaderMaterial
var _plaza_material: StandardMaterial3D


func _ready() -> void:
	world_seed = GameState.world_seed
	_target = get_node(target_path)
	_road_material = ShaderMaterial.new()
	_road_material.shader = preload("res://shaders/road.gdshader")
	_plaza_material = StandardMaterial3D.new()
	_plaza_material.albedo_color = Color(0.56, 0.5, 0.44)
	_plaza_material.roughness = 0.95
	var center := _center_cell()
	# Build the immediate surroundings synchronously so the first frame isn't empty.
	for cell in ChunkMath.cells_in_radius(center, 1):
		_build(ChunkGenerator.generate(world_seed, cell))


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
		_build(_ready_queue.pop_front())


func loaded_chunk_count() -> int:
	return _chunks.size()


func _center_cell() -> Vector2i:
	return ChunkMath.world_to_cell(_target.global_position, ChunkGenerator.CHUNK_SIZE)


func _unload_far(center: Vector2i) -> void:
	for cell: Vector2i in _chunks.keys():
		if ChunkMath.chebyshev(cell, center) > unload_radius:
			_chunks[cell].queue_free()
			_chunks.erase(cell)


func _collect_finished(center: Vector2i) -> void:
	_mutex.lock()
	var finished := _finished
	_finished = []
	_mutex.unlock()
	for data in finished:
		# Tasks must be waited on to release their resources; they're already done, so this is instant.
		WorkerThreadPool.wait_for_task_completion(_tasks[data.cell])
		_tasks.erase(data.cell)
		if ChunkMath.chebyshev(data.cell, center) <= unload_radius:
			_ready_queue.append(data)
	_ready_queue = _ready_queue.filter(func(d: ChunkData) -> bool:
		return ChunkMath.chebyshev(d.cell, center) <= unload_radius)
	_ready_queue.sort_custom(func(a: ChunkData, b: ChunkData) -> bool:
		return (a.cell - center).length_squared() < (b.cell - center).length_squared())


func _submit_missing(center: Vector2i) -> void:
	var queued := {}
	for d in _ready_queue:
		queued[d.cell] = true
	for cell in ChunkMath.cells_in_radius(center, load_radius):
		if _tasks.size() >= max_tasks_in_flight:
			return
		if _chunks.has(cell) or _tasks.has(cell) or queued.has(cell):
			continue
		_tasks[cell] = WorkerThreadPool.add_task(_generate_task.bind(cell, world_seed), false, "chunk")


func _generate_task(cell: Vector2i, seed_value: int) -> void:
	var data := ChunkGenerator.generate(seed_value, cell)
	_mutex.lock()
	_finished.append(data)
	_mutex.unlock()


func _build(data: ChunkData) -> void:
	if _chunks.has(data.cell):
		return
	var chunk := Node3D.new()
	chunk.name = "Chunk_%d_%d" % [data.cell.x, data.cell.y]

	if not data.road_vertices.is_empty():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = data.road_vertices
		arrays[Mesh.ARRAY_TEX_UV] = data.road_uvs
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
		chunk.add_child(PoiSite.create(poi, _model_scene(poi.model_path), _plaza_material))

	add_child(chunk)
	_chunks[data.cell] = chunk


func _prop_def(biome: Biome, prop_id: String) -> Dictionary:
	var key := biome.id + "/" + prop_id
	if not _prop_defs.has(key):
		for def in biome.props:
			_prop_defs[biome.id + "/" + def.id] = def
	return _prop_defs[key]


func _model_scene(path: String) -> PackedScene:
	if not _model_scenes.has(path):
		_model_scenes[path] = load(path)
	return _model_scenes[path]
