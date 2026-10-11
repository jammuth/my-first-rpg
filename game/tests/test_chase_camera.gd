extends TestCase


func test_pitch_is_clamped() -> void:
	var lo := deg_to_rad(-60.0)
	var hi := deg_to_rad(25.0)
	assert_near(ChaseCamera.apply_look(Vector2.ZERO, Vector2(0, -5.0), lo, hi).y, lo)
	assert_near(ChaseCamera.apply_look(Vector2.ZERO, Vector2(0, 5.0), lo, hi).y, hi)


func test_yaw_wraps() -> void:
	assert_near(ChaseCamera.apply_look(Vector2(3.0, 0), Vector2(0.5, 0), -1.0, 1.0).x, 3.5 - TAU)
