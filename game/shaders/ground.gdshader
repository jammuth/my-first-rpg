shader_type spatial;
render_mode cull_back;

uniform vec4 color_a : source_color = vec4(0.85, 0.71, 0.49, 1.0);
uniform vec4 color_b : source_color = vec4(0.77, 0.60, 0.40, 1.0);

global uniform vec2 wind_direction;
global uniform float wind_strength;

varying vec3 world_pos;

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

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float n = noise(p * 0.015) * 0.6 + noise(p * 0.07) * 0.3 + noise(p * 0.6) * 0.1;
	float ripple = sin(p.x * 0.3 + p.y * 0.1 + noise(p * 0.04) * 8.0) * 0.5 + 0.5;
	vec3 albedo = mix(color_a.rgb, color_b.rgb, clamp(n * 0.85 + ripple * 0.15, 0.0, 1.0));
	// Streaks stretched along the wind and scrolled downwind read as sand skimming the surface.
	vec2 wd = normalize(wind_direction);
	vec2 wind_space = vec2(dot(p, wd), dot(p, vec2(-wd.y, wd.x)));
	float t = TIME * wind_strength;
	float streak = noise(vec2(wind_space.x * 0.03 - t * 0.9, wind_space.y * 0.45));
	float gust = noise(vec2(wind_space.x * 0.004 - t * 0.12, wind_space.y * 0.01));
	float drift = smoothstep(0.62, 0.9, streak) * smoothstep(0.35, 0.75, gust) * wind_strength;
	ALBEDO = albedo + vec3(0.10, 0.085, 0.06) * drift;
	ROUGHNESS = 0.95;
}
