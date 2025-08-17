shader_type canvas_item;

group_uniforms noise_uniforms;
uniform sampler2D lightning_noise : repeat_enable;
uniform sampler2D background_noise : repeat_enable;
group_uniforms;

group_uniforms color_uniforms;
uniform sampler2D color_gradient;
uniform bool use_color_gradient = false;
uniform float color_effect_mod : hint_range(0.0, 3.0, 0.05) = 0.5;
group_uniforms;

group_uniforms beam_properties;
uniform float intensive : hint_range(0.0, 5.0, 0.05) = 0.8;
uniform float lightning_thin = 2.0;
uniform int number_lightning = 8;
uniform float speed = 1.0;
uniform float position : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
group_uniforms;

uniform float heat_progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D heat_gradient;

float random (vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec4 base_color = COLOR;
	if (use_color_gradient) {
		base_color = texture(color_gradient, vec2(UV.y, UV.x));
	}
	vec4 final_color = vec4(0.0);
	float time = TIME * speed;

	for (int i = 0; i < number_lightning; i++){
		float offset_x = random(vec2(time));
		vec2 noise_coords = vec2(time * 0.4 * (0.5 + fract(sin(float(i) * 50.0))), abs(UV.y - 0.5));
		vec2 offset = (texture(lightning_noise, noise_coords).rg - vec2(0.5)) * intensive;
		vec2 uv_off = UV + offset;
		float dist_x = abs(uv_off.x - position) * lightning_thin;

		float color_lower_bound = 0.1 + 0.5 * (float(i) - 0.5);
		float color_mod = smoothstep(color_lower_bound, 1.0, texture(background_noise, UV * sin(offset_x)).x);

		vec4 new_color = base_color * color_mod / dist_x;
		new_color *= 0.1 * texture(background_noise, uv_off + vec2(time)).r;

		final_color += new_color;
		final_color.a -= min(color_effect_mod, new_color.a);
	}

	vec3 hot_color = texture(heat_gradient, vec2(heat_progress, 0.5)).rgb;
	final_color.rgb = mix(final_color.rgb, hot_color, heat_progress);

	float reveal_mask = step(UV.y, progress);

	COLOR = final_color;
	COLOR.a *= reveal_mask;
}
