class_name MinimapMath
extends RefCounted

## Projecting world x/z onto a round minimap that turns with the camera, so the way the camera looks
## is always up.


## Map offset in pixels from the map's centre. `yaw` is the camera's yaw (0 looks along -Z) and
## `scale` is pixels per metre.
static func to_map(world: Vector2, center: Vector2, yaw: float, scale: float) -> Vector2:
	return (world - center).rotated(yaw) * scale


## Pulls a point that falls off the map back onto its rim, for things worth pointing towards.
static func clamp_to_radius(p: Vector2, radius: float) -> Vector2:
	return p if p.length() <= radius else p.normalized() * radius
