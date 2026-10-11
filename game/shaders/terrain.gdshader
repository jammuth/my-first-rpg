shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/desert_ground.gdshaderinc"

uniform vec3 rock_a : source_color = vec3(0.72, 0.42, 0.25);
uniform vec3 rock_b : source_color = vec3(0.55, 0.30, 0.18);
uniform sampler2D cliff_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_roughness : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float cliff_tile = 14.0;
uniform float cliff_mean_luma = 0.349;
/** How much of the photo's own colour survives on cliffs (the rest is the stylised palette). */
uniform float cliff_photo_color : hint_range(0.0, 1.0) = 0.55;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + world_origin;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = world_pos.xz;
	vec3 gn = normalize(world_normal);
	vec3 albedo;
	vec3 n_world;
	float rough;
	desert_sand(p, gn, TIME, albedo, n_world, rough);

	float steep = 1.0 - smoothstep(0.55, 0.8, gn.y);
	if (steep > 0.001) {
		// Cliffs are projected from the side only (X and Z planes) so strata stay horizontal.
		vec2 uv_x = vec2(world_pos.z, -world_pos.y) / cliff_tile;
		vec2 uv_z = vec2(world_pos.x, -world_pos.y) / cliff_tile;
		vec2 w = pow(abs(gn.xz), vec2(4.0));
		w /= max(w.x + w.y, 0.0001);
		vec3 c_tex = texture(cliff_color, uv_x).rgb * w.x + texture(cliff_color, uv_z).rgb * w.y;
		float c_r = texture(cliff_roughness, uv_x).r * w.x + texture(cliff_roughness, uv_z).r * w.y;
		vec3 tn_x = unpack_normal(texture(cliff_normal, uv_x));
		vec3 tn_z = unpack_normal(texture(cliff_normal, uv_z));
		vec3 cn = normalize(
			vec3(tn_x.z * gn.x, tn_x.y + gn.y, tn_x.x + gn.z) * w.x
			+ vec3(tn_z.x + gn.x, tn_z.y + gn.y, tn_z.z * gn.z) * w.y);

		float strata = sin(world_pos.y * 1.3 + noise(p * 0.05) * 3.0) * 0.5 + 0.5;
		vec3 rock_palette = mix(rock_a, rock_b, strata * 0.7 + noise(p * 0.3) * 0.3);
		vec3 stylised = rock_palette * (luma(c_tex) / cliff_mean_luma);
		vec3 rock = mix(stylised, c_tex * (luma(rock_palette) / cliff_mean_luma), cliff_photo_color);

		albedo = mix(albedo, rock, steep);
		n_world = normalize(mix(n_world, cn, steep));
		rough = mix(rough, mix(0.8, 1.0, c_r), steep);
	}

	ALBEDO = albedo;
	ROUGHNESS = rough;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
}
