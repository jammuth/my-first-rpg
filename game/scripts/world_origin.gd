class_name WorldOrigin
extends RefCounted

## Floating origin maths. The scene keeps the truck near (0, 0) by periodically moving the world
## origin; world = local + origin. Steps are whole multiples of STEP so origins are exact in float32.

const STEP := 1024.0
## How far (on either axis) the truck may drift from the origin before the world is re-centred.
const SHIFT_DISTANCE := 1536.0


static func origin_for(world_position: Vector2) -> Vector3:
	return Vector3(snappedf(world_position.x, STEP), 0.0, snappedf(world_position.y, STEP))


## How much to move the origin (and subtract from local positions) for a truck at `local`; ZERO if
## no shift is needed yet.
static func shift_for(local: Vector3) -> Vector3:
	if absf(local.x) <= SHIFT_DISTANCE and absf(local.z) <= SHIFT_DISTANCE:
		return Vector3.ZERO
	return Vector3(snappedf(local.x, STEP), 0.0, snappedf(local.z, STEP))
