shader_type canvas_item;

uniform vec3 color: source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 background_color: source_color = vec3(0.0, 0.0, 0.0);
uniform float speed: hint_range(0.01, 10.0, 0.01) = 0.2;
uniform float density: hint_range(1.0, 500.0, 1.0) = 145.0;
uniform float compression: hint_range(0.1, 1.0, 0.01) = 0.5;
uniform float trail_size: hint_range(5.0, 100.0, 0.1) = 100.0;
uniform float brightness: hint_range(0.1, 10.0, 0.1) = 0.8;

const float FALL_FREQUENCY = 30.0;

void fragment() {
	vec2 uv = -UV;
	float time = TIME * speed;

	uv.x *= density;
	vec2 column_uv = vec2(floor(uv.x), uv.y) * compression;

	float column_offset = sin(column_uv.x);

	float fall_speed_variance = 0.5 + 0.5 * cos(column_uv.x * FALL_FREQUENCY);
	float current_trail_size = mix(100.0, trail_size, fall_speed_variance);

	float drop = fract(column_uv.y + time * fall_speed_variance + column_offset) * current_trail_size;

	drop = 1.0 / drop;
	drop = smoothstep(0.0, 1.0, drop * drop);

	drop = sin(drop * PI) * fall_speed_variance * brightness;

	float column_shape = sin(fract(uv.x) * PI);
	drop *= column_shape * column_shape;

	vec3 final_effect = color * drop;
	COLOR = vec4(mix(background_color, final_effect, drop), 1.0);
}