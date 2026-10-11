extends TestCase

func _step(speed: float, throttle: float, delta := 0.1) -> float:
	return TruckMotion.step_speed(speed, throttle, delta, 16.0, 8.0, 20.0, 40.0)


func test_accelerates_to_max() -> void:
	var s := 0.0
	for i in 20:
		s = _step(s, 1.0)
	assert_near(s, 16.0)
	assert_near(_step(0.0, 1.0), 2.0, 0.0001, "uses acceleration from rest")


func test_reverse_capped() -> void:
	var s := 0.0
	for i in 20:
		s = _step(s, -1.0)
	assert_near(s, -8.0)


func test_coasting_and_reversing_use_braking() -> void:
	assert_near(_step(10.0, 0.0), 6.0, 0.0001, "release throttle")
	assert_near(_step(10.0, -1.0), 6.0, 0.0001, "reverse while moving forward brakes")
	assert_near(_step(-5.0, 1.0), -1.0, 0.0001, "forward while reversing brakes")


func test_partial_stick_gives_partial_speed() -> void:
	var s := 0.0
	for i in 20:
		s = _step(s, 0.5)
	assert_near(s, 8.0)


func test_tilt_flat_ground_is_level() -> void:
	assert_eq(TruckMotion.tilt_from_heights(2.0, 2.0, 2.0, 2.0, 5.0, 3.0), Vector2.ZERO)


func test_tilt_signs() -> void:
	var uphill := TruckMotion.tilt_from_heights(1.0, 0.0, 0.5, 0.5, 5.0, 3.0)
	assert_true(uphill.x > 0.0, "nose up when front is higher")
	assert_near(uphill.y, 0.0)
	var right_high := TruckMotion.tilt_from_heights(0.0, 0.0, 0.0, 3.0, 5.0, 3.0)
	assert_near(right_high.y, PI / 4.0, 0.0001)
	# Positive pitch about +X must raise the -Z (forward) end, matching Godot's convention.
	var nose := Basis.from_euler(Vector3(uphill.x, 0, 0)) * Vector3.FORWARD
	assert_true(nose.y > 0.0)
	var right_side := Basis.from_euler(Vector3(0, 0, right_high.y)) * Vector3.RIGHT
	assert_true(right_side.y > 0.0)
