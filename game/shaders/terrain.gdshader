shader_type spatial;
render_mode cull_disabled;

global uniform vec2 wind_direction;
global uniform float wind_strength;

uniform vec4 color_a : source_color = vec4(0.85, 0.71, 0.49, 1.0);
uniform vec4 color_b : source_color = vec4(0.77, 0.60, 0.40, 1.0);
uniform vec3 rock_a : source_color = vec3(0.72, 0.42, 0.25);
uniform vec3 rock_b : source_color = vec3(0.55, 0.30, 0.18);

uniform sampler2D sand_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_roughness : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D cliff_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_roughness : hint_default_white, filter_linear_mipmap, repeat_enable;

/** World metres covered by one texture tile. */
uniform float sand_tile = 7.0;
uniform float cliff_tile = 14.0;
/** Average luminance of each colour map, so tinting keeps the palette's brightness. */
uniform float sand_mean_luma = 0.727;
uniform float cliff_mean_luma = 0.349;
/** 0 = pure palette colour, 1 = full texture luminance detail. */
uniform float sand_detail : hint_range(0.0, 1.0) = 0.8;
/** How much of the photo's own colour survives on cliffs (the rest is the stylised palette). */
uniform float cliff_photo_color : hint_range(0.0, 1.0) = 0.55;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.8;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// Normal-map compression keeps only RG, so rebuild Z rather than trusting the blue channel.
vec3 unpack_normal(vec4 t) {
	vec2 xy = (t.rg * 2.0 - 1.0) * normal_strength;
	return vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = world_pos.xz;
	vec3 gn = normalize(world_normal);

	float n = noise(p * 0.015) * 0.6 + noise(p * 0.07) * 0.3 + noise(p * 0.6) * 0.1;
	float ripple = sin(p.x * 0.3 + p.y * 0.1 + noise(p * 0.04) * 8.0) * 0.5 + 0.5;
	vec3 palette = mix(color_a.rgb, color_b.rgb, clamp(n * 0.85 + ripple * 0.15, 0.0, 1.0));

	// Two samples at different scale and rotation, blended by large-scale noise, hide the tile grid.
	vec2 uv1 = p / sand_tile;
	vec2 uv2 = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * p / (sand_tile * 2.7);
	float pick = smoothstep(0.3, 0.7, noise(p * 0.02));
	vec3 sand_tex = mix(texture(sand_color, uv1).rgb, texture(sand_color, uv2).rgb, pick);
	vec3 sand_n = normalize(mix(unpack_normal(texture(sand_normal, uv1)), unpack_normal(texture(sand_normal, uv2)), pick));
	float sand_r = mix(texture(sand_roughness, uv1).r, texture(sand_roughness, uv2).r, pick);
	vec3 sand = palette * mix(1.0, luma(sand_tex) / sand_mean_luma, sand_detail);

	// Streaks stretched along the wind and scrolled downwind read as sand skimming the surface.
	vec2 wd = normalize(wind_direction);
	vec2 wind_space = vec2(dot(p, wd), dot(p, vec2(-wd.y, wd.x)));
	float t = TIME * wind_strength;
	float streak = noise(vec2(wind_space.x * 0.03 - t * 0.9, wind_space.y * 0.45));
	float gust = noise(vec2(wind_space.x * 0.004 - t * 0.12, wind_space.y * 0.01));
	float drift = smoothstep(0.62, 0.9, streak) * smoothstep(0.35, 0.75, gust) * wind_strength;
	sand += vec3(0.10, 0.085, 0.06) * drift;

	// Whiteout blend of the top-down projected sand normal onto the surface normal.
	vec3 n_world = normalize(vec3(sand_n.x + gn.x, sand_n.z * gn.y, -sand_n.y + gn.z));
	vec3 albedo = sand;
	float rough = mix(0.85, 1.0, sand_r);

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
