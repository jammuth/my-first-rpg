extends TestCase

var rect := Rect2(0, 0, 10, 10)


func test_clip_fully_inside() -> void:
	var r := Geometry2DUtil.clip_segment_to_rect(Vector2(1, 1), Vector2(9, 5), rect)
	assert_eq(r, PackedVector2Array([Vector2(1, 1), Vector2(9, 5)]))


func test_clip_crossing() -> void:
	var r := Geometry2DUtil.clip_segment_to_rect(Vector2(-10, 5), Vector2(20, 5), rect)
	assert_eq(r.size(), 2)
	assert_near(r[0].x, 0.0)
	assert_near(r[1].x, 10.0)


func test_clip_diagonal_corner() -> void:
	var r := Geometry2DUtil.clip_segment_to_rect(Vector2(-5, -5), Vector2(5, 5), rect)
	assert_true(r[0].is_equal_approx(Vector2(0, 0)))
	assert_true(r[1].is_equal_approx(Vector2(5, 5)))


func test_clip_miss() -> void:
	assert_true(Geometry2DUtil.clip_segment_to_rect(Vector2(-5, -5), Vector2(-1, 20), rect).is_empty())
	assert_true(Geometry2DUtil.clip_segment_to_rect(Vector2(11, 0), Vector2(11, 10), rect).is_empty())


func test_adjacent_rects_share_clip_point() -> void:
	var a := Vector2(-30, 3)
	var b := Vector2(25, 17)
	var left := Geometry2DUtil.clip_segment_to_rect(a, b, Rect2(-10, 0, 10, 20))
	var right := Geometry2DUtil.clip_segment_to_rect(a, b, Rect2(0, 0, 10, 20))
	assert_true(left[1].is_equal_approx(right[0]), "road pieces must meet at chunk seams")


func test_distance_to_segment() -> void:
	assert_near(Geometry2DUtil.distance_to_segment(Vector2(5, 3), Vector2(0, 0), Vector2(10, 0)), 3.0)
	assert_near(Geometry2DUtil.distance_to_segment(Vector2(-3, 4), Vector2(0, 0), Vector2(10, 0)), 5.0)
