class_name TerrainChunkData
extends RefCounted

var cell: Vector2i
var lod: int
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var indices := PackedInt32Array()
