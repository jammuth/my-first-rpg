class_name Geometry2DUtil
extends RefCounted


## Liang–Barsky clip. Returns [] when the segment misses the rect, else [p0, p1].
static func clip_segment_to_rect(a: Vector2, b: Vector2, rect: Rect2) -> PackedVector2Array:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [a.x - rect.position.x, rect.end.x - a.x, a.y - rect.position.y, rect.end.y - a.y]
	for i in 4:
		if is_zero_approx(p[i]):
			if q[i] < 0.0:
				return PackedVector2Array()
			continue
		var r: float = q[i] / p[i]
		if p[i] < 0.0:
			t0 = maxf(t0, r)
		else:
			t1 = minf(t1, r)
		if t0 > t1:
			return PackedVector2Array()
	return PackedVector2Array([a + d * t0, a + d * t1])


static func distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
