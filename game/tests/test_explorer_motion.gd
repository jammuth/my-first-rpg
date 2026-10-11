extends TestCase


func test_forward_follows_camera_yaw() -> void:
	var forward := Vector2(0, -1)
	assert_true(ExplorerMotion.move_direction(forward, 0.0).is_equal_approx(Vector3(0, 0, -1)))
	assert_true(ExplorerMotion.move_direction(forward, PI * 0.5).is_equal_approx(Vector3(-1, 0, 0)))
	assert_true(ExplorerMotion.move_direction(Vector2(1, 0), 0.0).is_equal_approx(Vector3(1, 0, 0)), "right strafes +X")


func test_diagonals_are_normalised_but_analog_is_kept() -> void:
	assert_near(ExplorerMotion.move_direction(Vector2(1, -1), 0.3).length(), 1.0)
	assert_near(ExplorerMotion.move_direction(Vector2(0, -0.4), 1.0).length(), 0.4)


func test_target_speed() -> void:
	assert_near(ExplorerMotion.target_speed(1.0, false, 2.6, 5.6), 2.6)
	assert_near(ExplorerMotion.target_speed(1.0, true, 2.6, 5.6), 5.6)
	assert_near(ExplorerMotion.target_speed(0.5, false, 2.6, 5.6), 1.3)
	assert_near(ExplorerMotion.target_speed(1.4, false, 2.6, 5.6), 2.6, 0.0001, "deflection is capped")


func test_turn_towards_faces_plus_z_model_along_direction() -> void:
	var yaw := 0.0
	for i in 200:
		yaw = ExplorerMotion.turn_towards(yaw, Vector3(1, 0, 0), 12.0, 1.0 / 60.0)
	assert_near(yaw, PI * 0.5, 0.001)
	var facing := Basis(Vector3.UP, yaw) * Vector3(0, 0, 1)
	assert_true(facing.is_equal_approx(Vector3(1, 0, 0)), "model front ends up pointing along the move")


func test_turn_takes_short_way_and_ignores_zero() -> void:
	var start := deg_to_rad(170.0)
	var next := ExplorerMotion.turn_towards(start, Vector3(-0.17, 0, -0.98), 12.0, 0.016)
	assert_true(next > start, "170° to about -170° goes up through 180°, not back down")
	assert_eq(ExplorerMotion.turn_towards(1.2, Vector3.ZERO, 12.0, 0.016), 1.2)


func test_approach_moves_at_acceleration() -> void:
	var v := ExplorerMotion.approach(Vector3.ZERO, Vector3(5, 0, 0), 24.0, 0.1)
	assert_true(v.is_equal_approx(Vector3(2.4, 0, 0)))
	assert_true(ExplorerMotion.approach(v, Vector3(5, 0, 0), 24.0, 1.0).is_equal_approx(Vector3(5, 0, 0)), "doesn't overshoot")


func test_animation_for_speed() -> void:
	assert_eq(ExplorerMotion.animation_for(0.0, 2.6), ExplorerAnimations.IDLE)
	assert_eq(ExplorerMotion.animation_for(2.6, 2.6), ExplorerAnimations.WALK)
	assert_eq(ExplorerMotion.animation_for(5.6, 2.6), ExplorerAnimations.RUN)


func test_slide_along_drops_only_the_outward_part() -> void:
	var n := Vector2(1, 0)
	assert_eq(ExplorerMotion.slide_along(Vector2(3, 0), n), Vector2.ZERO, "head on stops")
	assert_eq(ExplorerMotion.slide_along(Vector2(2, 1.5), n), Vector2(0, 1.5), "glancing slides")
	assert_eq(ExplorerMotion.slide_along(Vector2(-2, 1), n), Vector2(-2, 1), "moving away is untouched")
