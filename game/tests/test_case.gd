class_name TestCase
extends RefCounted

var failures: Array[String] = []
var assertions := 0


func fail(msg: String) -> void:
	failures.append(msg)


func assert_true(cond: bool, msg := "expected true") -> void:
	assertions += 1
	if not cond:
		fail(msg)


func assert_false(cond: bool, msg := "expected false") -> void:
	assert_true(not cond, msg)


func assert_eq(actual: Variant, expected: Variant, msg := "") -> void:
	assertions += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("%s expected <%s> got <%s>" % [msg, expected, actual])


func assert_ne(actual: Variant, other: Variant, msg := "") -> void:
	assertions += 1
	if typeof(actual) == typeof(other) and actual == other:
		fail("%s expected values to differ, both <%s>" % [msg, actual])


func assert_near(actual: float, expected: float, tolerance := 0.0001, msg := "") -> void:
	assertions += 1
	if absf(actual - expected) > tolerance:
		fail("%s expected %f ± %f got %f" % [msg, expected, tolerance, actual])


func assert_not_null(value: Variant, msg := "expected non-null") -> void:
	assert_true(value != null, msg)
