extends TestCase


func test_offset_pitch_and_distance() -> void:
	var off := FollowCamera.offset_for(0.0, deg_to_rad(50.0), 40.0)
	assert_near(off.length(), 40.0, 0.001)
	assert_near(rad_to_deg(atan2(off.y, Vector2(off.x, off.z).length())), 50.0, 0.001, "looks down at 50°")


func test_offset_sits_behind_heading() -> void:
	for yaw in [0.0, 1.0, -2.5]:
		var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
		var off := FollowCamera.offset_for(yaw, deg_to_rad(50.0), 40.0)
		assert_true(Vector2(off.x, off.z).dot(Vector2(forward.x, forward.z)) < 0.0, "camera must be behind truck")
		assert_near(Vector2(off.x, off.z).normalized().dot(-Vector2(forward.x, forward.z)), 1.0, 0.0001)


func test_orbit_drag_clamps_total_pitch() -> void:
	var base := deg_to_rad(45.0)
	var lo := deg_to_rad(12.0)
	var hi := deg_to_rad(80.0)
	var up := FollowCamera.orbit_drag(Vector2.ZERO, Vector2(0, 5.0), base, lo, hi)
	assert_near(base + up.y, hi, 0.0001, "clamped at max pitch")
	var down := FollowCamera.orbit_drag(Vector2.ZERO, Vector2(0, -5.0), base, lo, hi)
	assert_near(base + down.y, lo, 0.0001, "clamped at min pitch")


func test_orbit_drag_wraps_yaw() -> void:
	var o := FollowCamera.orbit_drag(Vector2(3.0, 0), Vector2(0.5, 0), 0.8, 0.1, 1.4)
	assert_near(o.x, 3.5 - TAU, 0.0001)


func test_orbit_return_converges_to_default() -> void:
	var o := Vector2(2.0, -0.4)
	for i in 300:
		o = FollowCamera.orbit_return(o, 4.0, 1.0 / 60.0)
	assert_near(o.x, 0.0, 0.001)
	assert_near(o.y, 0.0, 0.001)


func test_orbit_return_never_overshoots() -> void:
	var o := Vector2(-2.5, 0.6)
	for i in 120:
		var next := FollowCamera.orbit_return(o, 4.0, 1.0 / 30.0)
		assert_true(absf(next.x) <= absf(o.x) and signf(next.x) != -signf(o.x), "yaw overshot")
		assert_true(absf(next.y) <= absf(o.y) and signf(next.y) != -signf(o.y), "pitch overshot")
		o = next
