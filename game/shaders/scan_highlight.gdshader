shader_type spatial;
// Drawn as a material overlay on top of a piece's own material while the drone has it in view.
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(0.35, 0.95, 1.0, 1.0);

void fragment() {
	// Back faces show too (the pieces are double-sided), so their normal is flipped to face the view.
	vec3 n = FRONT_FACING ? NORMAL : -NORMAL;
	float rim = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 1.5);
	float pulse = 0.75 + 0.25 * sin(TIME * 4.0);
	// A flat tint as well as the rim, so small pieces still read against bright sand.
	ALBEDO = glow_color.rgb * (0.4 + rim * 1.6) * pulse;
}
