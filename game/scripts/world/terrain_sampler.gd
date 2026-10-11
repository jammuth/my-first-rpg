class_name TerrainSampler
extends RefCounted

## Deterministic terrain height. Each instance owns its noise and cache, so every worker thread
## builds its own sampler instead of sharing one.

const SALT := 0x7E44A
## Fully flat this far beyond the road edge, then blends back to natural terrain.
const ROAD_FLAT_EXTRA := 3.0
const ROAD_BLEND := 28.0
const POI_BLEND := 30.0
## Must exceed every influence's reach (largest plaza + POI_BLEND, road half width + flat + blend)
## so samples on either side of a chunk seam see the same roads and POIs.
const INFLUENCE_MARGIN := 64.0
const MAX_CACHED_CELLS := 256

var world_seed: int
var _swell := FastNoiseLite.new()
var _dunes := FastNoiseLite.new()
var _ridges := FastNoiseLite.new()
var _biome: Biome
var _influences := {}


func _init(seed_value: int) -> void:
	world_seed = seed_value
	_biome = BiomeMap.biome_at_cell(seed_value, Vector2i.ZERO)
	var base := WorldHash.hash3(seed_value, 0, 0, SALT) & 0x7FFFFFFF
	_setup(_swell, base, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, FastNoiseLite.FRACTAL_FBM, 2, _biome.terrain_swell.y)
	_setup(_dunes, base + 1, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, FastNoiseLite.FRACTAL_FBM, 3, _biome.terrain_dunes.y)
	_setup(_ridges, base + 2, FastNoiseLite.TYPE_SIMPLEX, FastNoiseLite.FRACTAL_RIDGED, 2, _biome.terrain_ridges.y)


static func _setup(n: FastNoiseLite, seed_value: int, type: int, fractal: int, octaves: int,
		wavelength: float) -> void:
	n.seed = seed_value
	n.noise_type = type
	n.fractal_type = fractal
	n.fractal_octaves = octaves
	n.frequency = 1.0 / wavelength


## Natural terrain before roads and plazas are carved in.
func base_height(x: float, z: float) -> float:
	return (_swell.get_noise_2d(x, z) * _biome.terrain_swell.x
		+ _dunes.get_noise_2d(x, z) * _biome.terrain_dunes.x
		+ _ridges.get_noise_2d(x, z) * _biome.terrain_ridges.x)


func height_at(x: float, z: float) -> float:
	var cell := Vector2i(floori(x / ChunkGenerator.CHUNK_SIZE), floori(z / ChunkGenerator.CHUNK_SIZE))
	return apply_influences(base_height(x, z), Vector2(x, z), influences_for_cell(cell))


func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	var dx := height_at(x - e, z) - height_at(x + e, z)
	var dz := height_at(x, z - e) - height_at(x, z + e)
	return Vector3(dx, 2.0 * e, dz).normalized()


func poi_height(poi: PoiData) -> float:
	return base_height(poi.position.x, poi.position.z)


## Roads and POIs that can affect heights inside the chunk `cell`.
## {roads: [{a, b, ha, hb, ra, rb}], pois: [{poi, h}]}
func influences_for_cell(cell: Vector2i) -> Dictionary:
	if _influences.has(cell):
		return _influences[cell]
	if _influences.size() >= MAX_CACHED_CELLS:
		_influences.clear()
	var rect := ChunkMath.cell_rect(cell, ChunkGenerator.CHUNK_SIZE).grow(INFLUENCE_MARGIN)
	var pois: Array[Dictionary] = []
	for poi in PoiGenerator.pois_in_rect(world_seed, rect):
		pois.append({"poi": poi, "h": poi_height(poi)})
	var roads: Array[Dictionary] = []
	for seg in RoadNetwork.roads_touching_rect(world_seed, rect):
		var pa := PoiGenerator.poi_for_cell(world_seed, PoiGenerator.world_to_cell(Vector3(seg[0].x, 0, seg[0].y)))
		var pb := PoiGenerator.poi_for_cell(world_seed, PoiGenerator.world_to_cell(Vector3(seg[1].x, 0, seg[1].y)))
		roads.append({"a": seg[0], "b": seg[1], "ha": poi_height(pa), "hb": poi_height(pb),
			"ra": pa.plaza_radius, "rb": pb.plaza_radius})
	var result := {"roads": roads, "pois": pois}
	_influences[cell] = result
	return result


## Road surface height at the point on the road nearest `p`. Held at the end heights across each
## plaza so plazas stay perfectly flat, with a constant grade in between.
static func road_height(road: Dictionary, p: Vector2) -> float:
	var a: Vector2 = road.a
	var b: Vector2 = road.b
	var length := a.distance_to(b)
	var along := clampf((p - a).dot((b - a) / length), 0.0, length)
	var span := maxf(length - road.ra - road.rb, 0.001)
	var t := clampf((along - road.ra) / span, 0.0, 1.0)
	return lerpf(road.ha, road.hb, t)


## Blends natural height toward road and plaza heights. Targets are weight-averaged rather than
## picking the strongest so overlapping influences never create a step.
static func apply_influences(h: float, p: Vector2, inf: Dictionary) -> float:
	var w_sum := 0.0
	var t_sum := 0.0
	var w_max := 0.0
	for e in inf.pois:
		var poi: PoiData = e.poi
		var d := p.distance_to(poi.position_2d())
		var w := 1.0 - smoothstep(poi.plaza_radius, poi.plaza_radius + POI_BLEND, d)
		if w > 0.0:
			# Plazas dominate roads that end on them, keeping the plaza exactly level.
			var weight := w * 8.0
			w_sum += weight
			t_sum += weight * e.h
			w_max = maxf(w_max, w)
	var flat := RoadNetwork.WIDTH * 0.5 + ROAD_FLAT_EXTRA
	for road in inf.roads:
		var d := Geometry2DUtil.distance_to_segment(p, road.a, road.b)
		var w := 1.0 - smoothstep(flat, flat + ROAD_BLEND, d)
		if w > 0.0:
			w_sum += w
			t_sum += w * road_height(road, p)
			w_max = maxf(w_max, w)
	if w_sum <= 0.0:
		return h
	return lerpf(h, t_sum / w_sum, w_max)
