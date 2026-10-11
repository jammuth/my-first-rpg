extends TestCase


func test_heading_of_cardinals() -> void:
	assert_near(CompassMath.heading_of(Vector2(0, -1)), 0.0)
	assert_near(CompassMath.heading_of(Vector2(1, 0)), PI / 2)
	assert_near(CompassMath.heading_of(Vector2(-1, 0)), -PI / 2)
	assert_near(absf(CompassMath.heading_of(Vector2(0, 1))), PI)


func test_heading_for_yaw_matches_forward_vector() -> void:
	for yaw in [0.0, 0.5, -1.2, 2.9]:
		var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
		assert_near(CompassMath.heading_for_yaw(yaw), CompassMath.heading_of(Vector2(forward.x, forward.z)), 0.0001)


func test_relative_bearing() -> void:
	var facing_north := 0.0
	assert_near(CompassMath.relative_bearing(facing_north, Vector2.ZERO, Vector2(0, -10)), 0.0)
	assert_near(CompassMath.relative_bearing(facing_north, Vector2.ZERO, Vector2(10, 0)), PI / 2, 0.0001, "east is right")
	assert_near(CompassMath.relative_bearing(PI / 2, Vector2.ZERO, Vector2(0, -10)), -PI / 2, 0.0001, "north is left when facing east")
	assert_near(CompassMath.relative_bearing(3.0, Vector2.ZERO, Vector2(0, 10)), PI - 3.0, 0.0001, "wraps")


func test_bearing_to_x() -> void:
	assert_near(CompassMath.bearing_to_x(0.0, PI / 2, 600.0), 300.0)
	assert_near(CompassMath.bearing_to_x(PI / 4, PI / 2, 600.0), 450.0)
	assert_near(CompassMath.bearing_to_x(-PI, PI / 2, 600.0), 0.0, 0.0001, "clamped left")
	assert_near(CompassMath.bearing_to_x(PI, PI / 2, 600.0), 600.0, 0.0001, "clamped right")


func test_label_rows_separate_overlaps() -> void:
	var rows := CompassMath.label_rows([100.0, 140.0, 400.0] as Array[float], [120.0, 120.0, 120.0] as Array[float])
	assert_eq(rows, [0, 1, 0] as Array[int])


func test_label_rows_all_on_one_row_when_apart() -> void:
	var rows := CompassMath.label_rows([500.0, 100.0, 300.0] as Array[float], [80.0, 80.0, 80.0] as Array[float])
	assert_eq(rows, [0, 0, 0] as Array[int])


func test_label_rows_three_way_overlap() -> void:
	var rows := CompassMath.label_rows([300.0, 310.0, 320.0] as Array[float], [100.0, 100.0, 100.0] as Array[float])
	assert_eq(rows, [0, 1, 2] as Array[int])
