shader_type spatial;
render_mode cull_back;

uniform vec4 color_a : source_color = vec4(0.85, 0.71, 0.49, 1.0);
uniform vec4 color_b : source_color = vec4(0.77, 0.60, 0.40, 1.0);

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
	ALBEDO = mix(color_a.rgb, color_b.rgb, clamp(n * 0.85 + ripple * 0.15, 0.0, 1.0));
	ROUGHNESS = 0.95;
}
