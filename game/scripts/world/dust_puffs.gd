class_name DustPuffs
extends RefCounted

## Shared pieces for soft, sand-coloured particle puffs (blowing sand, truck dust).


static func wind() -> Vector3:
	var dir: Vector2 = ProjectSettings.get_setting("shader_globals/wind_direction").value
	var strength: float = ProjectSettings.get_setting("shader_globals/wind_strength").value
	dir = dir.normalized() * strength
	return Vector3(dir.x, 0.0, dir.y)


## Fades in, holds, fades out over a particle's life.
static func fade_ramp(fade_in: float = 0.25, fade_out: float = 0.75) -> GradientTexture1D:
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(fade_in, Color(1, 1, 1, 1))
	fade.add_point(fade_out, Color(1, 1, 1, 1))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	return ramp


## Billboard quad with a soft radial falloff, tinted `color` (alpha = peak opacity).
static func puff_mesh(size: float, color: Color) -> QuadMesh:
	var puff := Gradient.new()
	puff.set_color(0, Color(1, 1, 1, 1))
	puff.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = puff
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	quad.material = mat
	return quad
