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
