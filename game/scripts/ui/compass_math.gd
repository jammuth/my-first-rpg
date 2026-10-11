class_name CompassMath
extends RefCounted


## 0 = north (-Z), increasing clockwise (east = +X = PI/2).
static func heading_of(direction: Vector2) -> float:
	return atan2(direction.x, -direction.y)


## Heading the camera/vehicle faces for a Node3D yaw (rotation.y), since forward is -Z.
static func heading_for_yaw(yaw: float) -> float:
	return wrapf(-yaw, -PI, PI)


## Signed angle from `heading` to the target: negative = left, positive = right.
static func relative_bearing(heading: float, from: Vector2, to: Vector2) -> float:
	return wrapf(heading_of(to - from) - heading, -PI, PI)


## Maps a relative bearing to an x position in a bar of `width` showing +/- `half_fov`.
## Clamped to the bar edges so off-screen POIs stay visible at the side.
static func bearing_to_x(bearing: float, half_fov: float, width: float) -> float:
	return (clampf(bearing / half_fov, -1.0, 1.0) * 0.5 + 0.5) * width


## Greedy row assignment so labels centred at `centers` with `widths` don't overlap.
## Returns a row index per input label (0 = top row).
static func label_rows(centers: Array[float], widths: Array[float], gap: float = 8.0) -> Array[int]:
	var order := range(centers.size())
	order.sort_custom(func(a: int, b: int) -> bool: return centers[a] < centers[b])
	var rows: Array[int] = []
	rows.resize(centers.size())
	var row_ends: Array[float] = []
	for i: int in order:
		var left := centers[i] - widths[i] * 0.5
		var row := 0
		while row < row_ends.size() and left < row_ends[row] + gap:
			row += 1
		if row == row_ends.size():
			row_ends.append(0.0)
		row_ends[row] = centers[i] + widths[i] * 0.5
		rows[i] = row
	return rows
