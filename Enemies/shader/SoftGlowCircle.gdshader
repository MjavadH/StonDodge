shader_type canvas_item;

group_uniforms Circle;
uniform vec4 circle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float radius : hint_range(0.0, 0.5, 0.01) = 0.25;
uniform float edge_softness : hint_range(0.0, 0.5, 0.01) = 0.1;

group_uniforms Glow;
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.2, 0.5);
uniform float glow_radius : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float glow_edge_softness : hint_range(0.0, 1.0, 0.01) = 0.2;

void fragment() {
	float distance_from_center = distance(UV, vec2(0.5));
	float circle_alpha = 1.0 - smoothstep(radius - edge_softness, radius, distance_from_center);
	float glow_alpha = 1.0 - smoothstep(glow_radius - glow_edge_softness, glow_radius, distance_from_center);
	vec3 final_rgb = glow_color.rgb;
	final_rgb = mix(final_rgb, circle_color.rgb, circle_alpha);
	float final_alpha = max(circle_alpha * circle_color.a, glow_alpha * glow_color.a);
	COLOR = vec4(final_rgb, final_alpha);
}
