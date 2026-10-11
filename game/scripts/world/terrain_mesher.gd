class_name TerrainMesher
extends RefCounted

## Pure terrain chunk mesh generation (runs on worker threads).

## Vertex spacing per LOD level, indexed by ring distance via lod_for_ring.
const LOD_STEPS: Array[float] = [2.0, 4.0, 8.0]
## Deep enough to cover the worst height mismatch between neighbouring LODs.
const SKIRT_DEPTH := 30.0


static func lod_for_ring(ring: int) -> int:
	if ring <= 1:
		return 0
	if ring == 2:
		return 1
	return 2


static func build(sampler: TerrainSampler, cell: Vector2i, lod: int) -> TerrainChunkData:
	var step: float = LOD_STEPS[lod]
	var n := int(ChunkGenerator.CHUNK_SIZE / step)
	var origin := ChunkMath.cell_origin(cell, ChunkGenerator.CHUNK_SIZE)
	# One extra sample on every side so edge normals use real neighbours and match across seams.
	var g := n + 3
	var heights := PackedFloat32Array()
	heights.resize(g * g)
	for gz in g:
		for gx in g:
			heights[gz * g + gx] = sampler.height_at(origin.x + (gx - 1) * step, origin.z + (gz - 1) * step)

	var data := TerrainChunkData.new()
	data.cell = cell
	data.lod = lod
	var side := n + 1
	data.vertices.resize(side * side)
	data.normals.resize(side * side)
	for z in side:
		for x in side:
			var gi := (z + 1) * g + (x + 1)
			var i := z * side + x
			data.vertices[i] = Vector3(origin.x + x * step, heights[gi], origin.z + z * step)
			data.normals[i] = Vector3(heights[gi - 1] - heights[gi + 1], 2.0 * step,
				heights[gi - g] - heights[gi + g]).normalized()
	for z in n:
		for x in n:
			var i := z * side + x
			data.indices.append_array(PackedInt32Array([i, i + 1, i + side, i + 1, i + side + 1, i + side]))
	_add_skirts(data, side)
	return data


static func _add_skirts(data: TerrainChunkData, side: int) -> void:
	var edges: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
	for k in side:
		edges[0].append(k)
		edges[1].append((side - 1) * side + k)
		edges[2].append(k * side)
		edges[3].append(k * side + side - 1)
	for edge in edges:
		var base := data.vertices.size()
		for i in edge:
			data.vertices.append(data.vertices[i] - Vector3(0, SKIRT_DEPTH, 0))
			data.normals.append(data.normals[i])
		for k in edge.size() - 1:
			data.indices.append_array(PackedInt32Array([
				edge[k], edge[k + 1], base + k, edge[k + 1], base + k + 1, base + k]))
