extends TestCase


func test_empty_stats_are_zero() -> void:
	var s := FrameStats.new()
	assert_eq(s.average(), 0.0)
	assert_eq(s.percentile(0.99), 0.0)


func test_average_percentile_worst() -> void:
	var s := FrameStats.new(0)
	for i in range(1, 101):
		s.push(float(i))
	assert_near(s.average(), 50.5)
	assert_near(s.percentile(0.5), 50.0)
	assert_near(s.percentile(0.99), 99.0)
	assert_near(s.worst(), 100.0)
	assert_eq(s.count(), 100)


func test_rolling_window_drops_old_samples() -> void:
	var s := FrameStats.new(3)
	for v in [100.0, 1.0, 2.0, 3.0]:
		s.push(v)
	assert_eq(s.count(), 3)
	assert_near(s.worst(), 3.0)


func test_count_over() -> void:
	var s := FrameStats.new(0)
	for v in [5.0, 16.0, 17.0, 40.0]:
		s.push(v)
	assert_eq(s.count_over(16.7), 2)
	assert_eq(s.count_over(33.3), 1)
