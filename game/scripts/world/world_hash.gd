class_name WorldHash
extends RefCounted

const MASK := 0xFFFFFFFF


# GDScript ints are signed 64-bit, so a full 32x32 multiply could overflow; split b into 16-bit halves.
static func mul32(a: int, b: int) -> int:
	a &= MASK
	b &= MASK
	var lo := a * (b & 0xFFFF)
	var hi := ((a * (b >> 16)) & 0xFFFF) << 16
	return (lo + hi) & MASK


static func mix(h: int) -> int:
	h &= MASK
	h ^= h >> 16
	h = mul32(h, 0x7feb352d)
	h ^= h >> 15
	h = mul32(h, 0x846ca68b)
	h ^= h >> 16
	return h


static func hash3(world_seed: int, x: int, y: int, salt: int = 0) -> int:
	var h := mix(world_seed ^ 0x9e3779b9)
	h = mix(h ^ (x & MASK))
	h = mix(h ^ mul32(y, 0x85ebca6b))
	h = mix(h ^ mul32(salt, 0xc2b2ae35))
	return h


static func rng_for(world_seed: int, x: int, y: int, salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash3(world_seed, x, y, salt)
	return rng
