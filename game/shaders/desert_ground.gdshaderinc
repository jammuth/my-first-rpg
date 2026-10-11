// Shared desert sand surface. Terrain and roads both include this so drifted sand on road edges
// is the exact same world-space surface as the terrain beside it.

global uniform vec2 wind_direction;
global uniform float wind_strength;
/** Floating origin (see WorldOrigin): adds back what the scene was shifted by. */
global uniform vec3 world_origin;

uniform vec4 color_a : source_color = vec4(0.85, 0.71, 0.49, 1.0);
uniform vec4 color_b : source_color = vec4(0.77, 0.60, 0.40, 1.0);
uniform sampler2D sand_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_roughness : hint_default_white, filter_linear_mipmap, repeat_enable;
/** World metres covered by one sand texture tile. */
uniform float sand_tile = 7.0;
/** Average luminance of the sand colour map, so tinting keeps the palette's brightness. */
uniform float sand_mean_luma = 0.727;
/** 0 = pure palette colour, 1 = full texture luminance detail. */
uniform float sand_detail : hint_range(0.0, 1.0) = 0.8;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.8;

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

// Whiteout blend of a top-down (XZ-projected) tangent normal onto the world normal `gn`.
vec3 blend_top_down(vec3 tn, vec3 gn) {
	return normalize(vec3(tn.x + gn.x, tn.z * gn.y, -tn.y + gn.z));
}

void desert_sand(vec2 p, vec3 gn, float time, out vec3 albedo, out vec3 n_world, out float rough) {
	float n = noise(p * 0.015) * 0.6 + noise(p * 0.07) * 0.3 + noise(p * 0.6) * 0.1;
	float ripple = sin(p.x * 0.3 + p.y * 0.1 + noise(p * 0.04) * 8.0) * 0.5 + 0.5;
	vec3 palette = mix(color_a.rgb, color_b.rgb, clamp(n * 0.85 + ripple * 0.15, 0.0, 1.0));

	// Two samples at different scale and rotation, blended by large-scale noise, hide the tile grid.
	vec2 uv1 = p / sand_tile;
	vec2 uv2 = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * p / (sand_tile * 2.7);
	float pick = smoothstep(0.3, 0.7, noise(p * 0.02));
	vec3 tex = mix(texture(sand_color, uv1).rgb, texture(sand_color, uv2).rgb, pick);
	vec3 tn = normalize(mix(unpack_normal(texture(sand_normal, uv1)), unpack_normal(texture(sand_normal, uv2)), pick));
	float r = mix(texture(sand_roughness, uv1).r, texture(sand_roughness, uv2).r, pick);
	albedo = palette * mix(1.0, luma(tex) / sand_mean_luma, sand_detail);

	// Streaks stretched along the wind and scrolled downwind read as sand skimming the surface.
	vec2 wd = normalize(wind_direction);
	vec2 wind_space = vec2(dot(p, wd), dot(p, vec2(-wd.y, wd.x)));
	float t = time * wind_strength;
	float streak = noise(vec2(wind_space.x * 0.03 - t * 0.9, wind_space.y * 0.45));
	float gust = noise(vec2(wind_space.x * 0.004 - t * 0.12, wind_space.y * 0.01));
	float drift = smoothstep(0.62, 0.9, streak) * smoothstep(0.35, 0.75, gust) * wind_strength;
	albedo += vec3(0.10, 0.085, 0.06) * drift;

	n_world = blend_top_down(tn, gn);
	rough = mix(0.85, 1.0, r);
}
