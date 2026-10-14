extends TestCase


func test_drone_hovers_behind_right_and_above() -> void:
	var p := DroneMotion.hover_point(Vector3(10, 1, 20), Vector2(0, -1), 0.0)
	assert_near(p.x, 10.0 + DroneMotion.OFFSET_SIDE * 1.0, 0.0001, "facing -Z, right is +X")
	assert_near(p.z, 20.0 + DroneMotion.OFFSET_BACK)
	assert_near(p.y, 1.0 + DroneMotion.HOVER_HEIGHT)


func test_drone_hover_follows_facing() -> void:
	var p := DroneMotion.hover_point(Vector3.ZERO, Vector2(1, 0), 0.0)
	assert_true(p.x < 0.0, "behind an explorer facing +X is -X")
	assert_true(p.z > 0.0, "the right of +X is +Z")


func test_drone_bobs_within_its_height() -> void:
	for i in 50:
		var y := DroneMotion.hover_point(Vector3.ZERO, Vector2(0, 1), i * 0.17).y
		assert_true(absf(y - DroneMotion.HOVER_HEIGHT) <= DroneMotion.BOB_HEIGHT + 0.0001)


func test_drone_eases_in_and_snaps_when_far() -> void:
	var p := DroneMotion.step(Vector3.ZERO, Vector3(4, 0, 0), 1.0 / 60.0)
	assert_true(p.x > 0.0 and p.x < 4.0, "moves part of the way")
	var q := Vector3.ZERO
	for i in 120:
		q = DroneMotion.step(q, Vector3(4, 0, 0), 1.0 / 60.0)
	assert_near(q.x, 4.0, 0.01, "arrives within two seconds")
	assert_eq(DroneMotion.step(Vector3.ZERO, Vector3(50, 0, 0), 0.016), Vector3(50, 0, 0))


func test_scan_range() -> void:
	assert_true(ScanRules.in_range(Vector2.ZERO, Vector2(0, 25)))
	assert_false(ScanRules.in_range(Vector2.ZERO, Vector2(0, 25.1)))


func test_line_of_sight_accepts_hits_on_the_target_itself() -> void:
	assert_true(ScanRules.unobstructed(null, Vector2(5, 0), 1.0), "nothing in the way")
	assert_true(ScanRules.unobstructed(Vector2(4.1, 0), Vector2(5, 0), 1.0), "hit the target's own side")
	assert_false(ScanRules.unobstructed(Vector2(2, 0), Vector2(5, 0), 1.0), "a wall in front")


func test_probe_points_aim_at_the_centre_and_both_sides() -> void:
	var points := ScanRules.probe_points(Vector2(0, -10), 2.0, Vector2.ZERO)
	assert_eq(points.size(), 3)
	assert_eq(points[0], Vector2(0, -10))
	var reach := 2.0 * ScanRules.SIDE_REACH
	assert_true(points[1].is_equal_approx(Vector2(reach, -10)) or points[1].is_equal_approx(Vector2(-reach, -10)))
	assert_true(points[2].is_equal_approx(Vector2(-points[1].x, -10)), "the other side")
	assert_eq(ScanRules.probe_points(Vector2(3, 3), 0.0, Vector2.ZERO), [Vector2(3, 3)] as Array[Vector2], "doors are a point")


func test_record_reports_first_sightings_once() -> void:
	var seen := {"c1": true}
	var first := ScanRules.record(["c1", "c2", "d3"] as Array[String], seen)
	assert_eq(first, ["c2", "d3"] as Array[String])
	assert_eq(ScanRules.record(["c2", "d3"] as Array[String], seen), [] as Array[String])
	assert_eq(seen, {"c1": true, "c2": true, "d3": true})


func test_minimap_puts_the_camera_view_up() -> void:
	var ahead := MinimapMath.to_map(Vector2(0, -10), Vector2.ZERO, 0.0, 2.0)
	assert_true(ahead.is_equal_approx(Vector2(0, -20)), "looking along -Z, ahead is up on the map")
	var turned := MinimapMath.to_map(Vector2(-10, 0), Vector2.ZERO, PI * 0.5, 2.0)
	assert_true(turned.is_equal_approx(Vector2(0, -20)), "turned to look along -X, -X is up: %s" % turned)
	var right := MinimapMath.to_map(Vector2(10, 0), Vector2.ZERO, 0.0, 1.0)
	assert_true(right.is_equal_approx(Vector2(10, 0)), "+X is right when looking along -Z")


func test_minimap_is_relative_to_its_centre() -> void:
	assert_true(MinimapMath.to_map(Vector2(105, 50), Vector2(100, 50), 0.0, 3.0).is_equal_approx(Vector2(15, 0)))


func test_minimap_clamps_to_the_rim() -> void:
	assert_eq(MinimapMath.clamp_to_radius(Vector2(3, 4), 10.0), Vector2(3, 4))
	assert_true(MinimapMath.clamp_to_radius(Vector2(30, 40), 10.0).is_equal_approx(Vector2(6, 8)))
