class_name NameGenerator
extends RefCounted

const PREFIXES := ["Rust", "Dust", "Ash", "Iron", "Salt", "Bone", "Scorch", "Cinder", "Dry", "Red",
	"Copper", "Glass", "Grit", "Sun", "Hollow", "Static", "Wither", "Tin"]
const SUFFIXES := ["vale", "ridge", "creek", "wick", "haven", "hollow", "gate", "field", "rock",
	"mouth", "stead", "well", "spire", "reach", "flats", "cross"]


static func make(rng: RandomNumberGenerator) -> String:
	return PREFIXES[rng.randi() % PREFIXES.size()] + SUFFIXES[rng.randi() % SUFFIXES.size()]
