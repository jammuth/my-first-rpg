extends TestCase


func test_same_inputs_same_hash() -> void:
	assert_eq(WorldHash.hash3(42, 3, -7, 1), WorldHash.hash3(42, 3, -7, 1))


func test_different_inputs_differ() -> void:
	var base := WorldHash.hash3(42, 3, -7, 1)
	assert_ne(WorldHash.hash3(43, 3, -7, 1), base, "seed")
	assert_ne(WorldHash.hash3(42, 4, -7, 1), base, "x")
	assert_ne(WorldHash.hash3(42, 3, -6, 1), base, "y")
	assert_ne(WorldHash.hash3(42, 3, -7, 2), base, "salt")
	assert_ne(WorldHash.hash3(42, 3, 7, 1), WorldHash.hash3(42, 7, 3, 1), "swapped coords")


func test_hash_stays_in_32_bits() -> void:
	for i in 200:
		var h := WorldHash.hash3(i * 7919, -i * 31, i * 1000003, i)
		assert_true(h >= 0 and h <= WorldHash.MASK, "out of range: %d" % h)


func test_mul32_matches_wrapping_multiply() -> void:
	assert_eq(WorldHash.mul32(0xFFFFFFFF, 0xFFFFFFFF), 1)
	assert_eq(WorldHash.mul32(0x10000, 0x10000), 0)
	assert_eq(WorldHash.mul32(123456, 789), (123456 * 789) & WorldHash.MASK)


func test_known_value_is_stable() -> void:
	# Pinned so an accidental change to the hash (which would reshuffle every world) fails loudly.
	assert_eq(WorldHash.hash3(1337, 10, -20, 5), PINNED)


const PINNED := 1480394135
