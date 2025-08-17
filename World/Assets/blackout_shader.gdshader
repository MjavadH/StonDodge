shader_type canvas_item;

const int MAX_LIGHTS = 8;
uniform vec2 light_origins[MAX_LIGHTS];
uniform float light_radii[MAX_LIGHTS];
uniform int active_light_count;
uniform float feather : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	float final_mask = 1.0;
	for (int i = 0; i < active_light_count; i++) {
		float dist = distance(UV, light_origins[i]);
		float radius = light_radii[i];
		float current_mask = smoothstep(radius, radius + feather, dist);
		final_mask = min(final_mask, current_mask);
	}
	COLOR = vec4(0.0, 0.0, 0.0, final_mask);
}
