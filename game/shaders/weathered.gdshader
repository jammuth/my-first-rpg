shader_type spatial;
render_mode cull_disabled;

// Abandoned-building look for POI pieces: bleached colour, grime rising from the ground, rust
// streaks, sand settled on upward faces. Ruined pieces are cut off along a jagged line and show a
// dark, scorched interior. Base colour/texture come from the source model's material.

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform vec3 sand_color : source_color = vec3(0.82, 0.69, 0.48);
uniform vec3 grime_color : source_color = vec3(0.30, 0.24, 0.18);
uniform vec3 rust_color : source_color = vec3(0.45, 0.24, 0.12);
uniform float bleach : hint_range(0.0, 1.0) = 0.35;

/** World height of the piece's base. */
instance uniform float base_y = 0.0;
/** World height above which a ruined piece is broken off (huge = intact). */
instance uniform float ruin_height = 100000.0;

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

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Jagged break line: coarse slabs plus finer chipping.
	float h_xz = world_pos.x + world_pos.z;
	float jag = (noise(vec2(h_xz * 0.25, 0.0)) - 0.5) * 4.0 + (noise(world_pos.xz * 1.7) - 0.5) * 1.2;
	float cut = ruin_height + jag;
	if (world_pos.y > cut) {
		discard;
	}

	vec3 c = use_texture ? texture(albedo_texture, UV).rgb * albedo.rgb : albedo.rgb;
	c = mix(c, vec3(luma(c)), bleach) * vec3(1.0, 0.95, 0.87);

	vec3 n = normalize(world_normal);
	float h = world_pos.y - base_y;
	vec2 side = vec2(world_pos.x + world_pos.z, world_pos.y);
	float streaks = smoothstep(0.55, 0.85, noise(vec2(side.x * 1.3, side.y * 0.08))) * (1.0 - abs(n.y));
	float ground_grime = 1.0 - smoothstep(0.0, 2.5 + noise(world_pos.xz * 0.5) * 2.0, h);
	float blotches = smoothstep(0.6, 0.9, noise(side * 0.35)) * 0.6;
	c = mix(c, grime_color * (0.6 + luma(c)), clamp(ground_grime * 0.65 + blotches * 0.4, 0.0, 1.0));
	c = mix(c, rust_color, streaks * 0.45);

	float sand = smoothstep(0.55, 0.9, n.y) * smoothstep(0.3, 0.6, noise(world_pos.xz * 0.6));
	c = mix(c, sand_color, sand * 0.75);

	float scorch = 1.0 - smoothstep(0.0, 2.5, cut - world_pos.y);
	if (ruin_height < 10000.0) {
		c *= 1.0 - scorch * 0.55;
	}
	if (!FRONT_FACING) {
		c *= 0.3;
	}
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
