extends TestCase


func test_no_dust_when_slow() -> void:
	assert_eq(DustTrail.emission_ratio(0.0, 18.0, 1.5), 0.0)
	assert_eq(DustTrail.emission_ratio(1.4, 18.0, 1.5), 0.0)


func test_dust_grows_with_speed() -> void:
	var slow := DustTrail.emission_ratio(3.0, 18.0, 1.5)
	var fast := DustTrail.emission_ratio(15.0, 18.0, 1.5)
	assert_true(slow > 0.0 and fast > slow)
	assert_near(DustTrail.emission_ratio(18.0, 18.0, 1.5), 1.0)
	assert_near(DustTrail.emission_ratio(30.0, 18.0, 1.5), 1.0, 0.0001, "clamped")


func test_is_paved_on_roads_and_pads_only() -> void:
	var roads := [{"a": Vector2(0, 0), "b": Vector2(100, 0)}]
	var pads := [{"centre": Vector2(200, 200), "radius": 16.0}]
	assert_true(RoadNetwork.is_paved(Vector2(50, 4), roads, pads), "on the road")
	assert_false(RoadNetwork.is_paved(Vector2(50, 6), roads, pads), "beside the road")
	assert_true(RoadNetwork.is_paved(Vector2(210, 200), roads, pads), "on a pad")
	assert_false(RoadNetwork.is_paved(Vector2(220, 200), roads, pads), "past the pad")
