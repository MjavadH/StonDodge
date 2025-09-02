shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.7, 0.9, 1.0, 0.8);
uniform float width : hint_range(0.0, 1.0) = 0.5;
uniform float intensity : hint_range(0.0, 5.0) = 1.5;
uniform float falloff : hint_range(0.1, 10.0) = 2.0;

void fragment() {
	float dist_from_edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float glow_progress = 1.0 - smoothstep(0.0, width, dist_from_edge);
	float glow_value = pow(glow_progress, falloff) * intensity;
	COLOR = vec4(glow_color.rgb, clamp(glow_value * glow_color.a, 0.0, 1.0));
}
