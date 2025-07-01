shader_type canvas_item;

uniform sampler2D crack_texture : source_color, filter_nearest;
uniform vec4 fill_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.2, 0.7);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.1;
uniform float glow_radius : hint_range(0.0, 10.0) = 3.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	float dist_from_center = distance(UV, vec2(0.5));
	float wave_alpha = 1.0 - smoothstep(progress - edge_softness, progress, dist_from_center);

	if (wave_alpha < 0.01) {
		discard;
	}

	float crack_alpha = texture(crack_texture, UV).a;

	vec2 texel_size = 1.0 / vec2(textureSize(crack_texture, 0));
	float total_neighbor_alpha = 0.0;

	total_neighbor_alpha += texture(crack_texture, UV + vec2(-1.0, -1.0) * texel_size * glow_radius).a;
	total_neighbor_alpha += texture(crack_texture, UV + vec2( 0.0, -1.0) * texel_size * glow_radius).a;
	total_neighbor_alpha += texture(crack_texture, UV + vec2( 1.0, -1.0) * texel_size * glow_radius).a;
	total_neighbor_alpha += texture(crack_texture, UV + vec2(-1.0,  0.0) * texel_size * glow_radius).a;
	total_neighbor_alpha += texture(crack_texture, UV + vec2( 1.0,  0.0) * texel_size * glow_radius).a;
	total_neighbor_alpha += texture(crack_texture, UV + vec2(-1.0,  1.0) * texel_size * glow_radius).a;
	total_neighbor_alpha += texture(crack_texture, UV + vec2( 0.0,  1.0) * texel_size * glow_radius).a;
	total_neighbor_alpha += texture(crack_texture, UV + vec2( 1.0,  1.0) * texel_size * glow_radius).a;

	float average_neighbor_alpha = total_neighbor_alpha / 8.0;
	float glow_amount = smoothstep(0.01, 0.6, average_neighbor_alpha) * (1.0 - smoothstep(0.0, 0.2, crack_alpha));
	glow_amount = clamp(glow_amount * glow_intensity, 0.0, 1.0);

	vec4 fill_component = vec4(fill_color.rgb, fill_color.a * crack_alpha);
	vec4 glow_component = vec4(glow_color.rgb, glow_color.a * glow_amount);

	fill_component.a *= wave_alpha;
	glow_component.a *= wave_alpha;

	float final_alpha = fill_component.a + glow_component.a * (1.0 - fill_component.a);
	vec3 final_rgb = (fill_component.rgb * fill_component.a + glow_component.rgb * glow_component.a * (1.0 - fill_component.a)) / max(final_alpha, 0.0001);

	COLOR = vec4(final_rgb, final_alpha);
}