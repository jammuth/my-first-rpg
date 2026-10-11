shader_type spatial;
render_mode cull_disabled;

uniform vec3 asphalt : source_color = vec3(0.30, 0.27, 0.25);
uniform vec3 sand : source_color = vec3(0.80, 0.66, 0.47);
uniform vec3 line_color : source_color = vec3(0.85, 0.74, 0.40);

void fragment() {
	float edge = abs(UV.x - 0.5) * 2.0;
	vec3 c = mix(asphalt, sand, smoothstep(0.7, 1.0, edge));
	float dash = step(0.5, fract(UV.y * 0.5)) * (1.0 - step(0.035, abs(UV.x - 0.5)));
	c = mix(c, line_color, dash * 0.8);
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
