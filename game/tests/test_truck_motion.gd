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
