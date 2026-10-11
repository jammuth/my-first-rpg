shader_type spatial;

// Low-poly cactus skin: vertical ribs, mottling and sand dust at the base, so stylised geometry
// sits next to scanned rocks and plants without looking flat.

uniform vec3 base_color : source_color = vec3(0.30, 0.42, 0.24);
uniform vec3 rib_color : source_color = vec3(0.20, 0.30, 0.17);
uniform vec3 dust_color : source_color = vec3(0.80, 0.68, 0.48);
uniform float rib_count = 14.0;
/** Height in model units (before instance scale) that sand dust reaches up the stem. */
uniform float dust_height = 0.18;

varying vec3 local_pos;

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
	local_pos = VERTEX;
}

void fragment() {
	float angle = atan(local_pos.z, local_pos.x);
	float rib = pow(abs(sin(angle * rib_count * 0.5)), 3.0);
	float mottle = noise(local_pos.xy * vec2(30.0, 6.0)) * 0.5 + noise(local_pos.zy * 60.0) * 0.5;
	vec3 c = mix(base_color, rib_color, rib * 0.6);
	c *= 0.85 + mottle * 0.3;
	float dust = 1.0 - smoothstep(0.0, dust_height, local_pos.y + (noise(local_pos.xz * 40.0) - 0.5) * 0.06);
	ALBEDO = mix(c, dust_color, dust * 0.7);
	ROUGHNESS = mix(0.55, 0.95, dust);
}
