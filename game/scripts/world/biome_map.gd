class_name BiomeMap
extends RefCounted

## Single shared instance: biomes are read-only after construction, so worker threads can share it.
static var _desert: Biome = DesertBiome.new()


static func biome_at_cell(_world_seed: int, _cell: Vector2i) -> Biome:
	return _desert
