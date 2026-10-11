class_name ChunkData
extends RefCounted

var cell: Vector2i
## Clipped to this chunk; each is [a, b] in x/z.
var road_segments: Array[PackedVector2Array] = []
## Full, unclipped endpoints of the road each segment belongs to (parallel to road_segments).
var road_ends: Array[PackedVector2Array] = []
var road_vertices := PackedVector3Array()
var road_uvs := PackedVector2Array()
## x = distance to the nearer end of the whole road.
var road_uv2s := PackedVector2Array()
var road_indices := PackedInt32Array()
## prop id -> Array[Transform3D]
var props: Dictionary = {}
## Each: {position: Vector3, radius: float}
var solids: Array[Dictionary] = []
var pois: Array[PoiData] = []
