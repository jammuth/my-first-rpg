shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/desert_ground.gdshaderinc"

uniform sampler2D asphalt_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalt_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalt_roughness : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float asphalt_tile = 4.0;
/** Sun-bleached, dust-stained tint over the photographed asphalt. */
uniform vec3 asphalt_tint : source_color = vec3(0.92, 0.84, 0.74);
uniform vec3 line_color : source_color = vec3(0.85, 0.74, 0.40);
/** Fraction of the road (from the edges in) buried under drifted sand. */
uniform float edge_sand : hint_range(0.0, 1.0) = 0.35;
/** How much sand pools in patches across the whole road surface. */
uniform float patch_sand : hint_range(0.0, 1.0) = 0.6;


varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz + world_origin;
}

void fragment() {
	vec2 p = world_pos.xz;
	vec3 gn = vec3(0.0, 1.0, 0.0);
	vec3 sand;
	vec3 sand_n;
	float sand_r;
	desert_sand(p, gn, TIME, sand, sand_n, sand_r);

	// Cracks have no direction, so asphalt is projected in world space like the sand.
	vec2 uv = p / asphalt_tile;
	vec3 asphalt = texture(asphalt_color, uv).rgb * asphalt_tint;
	vec3 asphalt_n = blend_top_down(unpack_normal(texture(asphalt_normal, uv)), gn);
	float asphalt_r = texture(asphalt_roughness, uv).r;

	// UV.x runs across the road and UV.y along it, in road widths, so dashes follow the road.
	float centre = 1.0 - step(0.035, abs(UV.x - 0.5));
	float dash = step(0.5, fract(UV.y * 0.5)) * centre;
	// UV2.x is distance to the road's nearer end in units of that POI's junction pad radius. Inside
	// the pad roads drop their edge sand and centre line, so they're plain asphalt like the pad and
	// overlapping road ends render identically. UV2.y = 1 marks the pad itself (keeps its rim sand).
	// The fade starts at RoadNetwork.JUNCTION_CORE and tracks the pad's own sandy rim (edge_sand).
	float junction = (1.0 - smoothstep(0.6, 0.85, UV2.x)) * (1.0 - UV2.y);
	dash *= 1.0 - junction;
	float worn = smoothstep(0.25, 0.65, noise(p * 0.4));
	asphalt = mix(asphalt, line_color, dash * worn * 0.85);

	float edge = abs(UV.x - 0.5) * 2.0;
	float edge_cover = smoothstep(1.0 - edge_sand, 1.0, edge + (noise(p * 0.12) - 0.5) * 0.35) * (1.0 - junction);
	// Value noise has axis-aligned cell artefacts that a sharp threshold turns into stair-stepped
	// rectangles; sampling two octaves on rotated, offset grids breaks the alignment up.
	vec2 q1 = mat2(vec2(0.866, 0.5), vec2(-0.5, 0.866)) * p;
	vec2 q2 = mat2(vec2(0.342, 0.940), vec2(-0.940, 0.342)) * p + vec2(37.0, 11.0);
	float drift_n = noise(q1 * 0.035) * 0.6 + noise(q2 * 0.09) * 0.25 + noise(q1 * 0.31) * 0.15;
	float patch_cover = smoothstep(0.56, 0.86, drift_n) * patch_sand;
	float cover = clamp(max(edge_cover, patch_cover), 0.0, 1.0);

	ALBEDO = mix(asphalt, sand, cover);
	ROUGHNESS = mix(asphalt_r, sand_r, cover);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(mix(asphalt_n, sand_n, cover)), 0.0)).xyz);
}
