shader_type spatial;

// Recolours a texture-atlas part while keeping its painted shading: the texel's brightness,
// relative to the atlas's typical mid-tone, scales the tint.
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(0.76, 0.66, 0.46);
uniform float mid_luminance = 0.42;

void fragment() {
	vec3 c = texture(albedo_texture, UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = tint * clamp(l / mid_luminance, 0.0, 1.6);
	ROUGHNESS = 0.9;
}
