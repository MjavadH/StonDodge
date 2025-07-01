shader_type canvas_item;
render_mode blend_mix;

uniform vec4 crack_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform int steps : hint_range(1, 50) = 10;
uniform float seed : hint_range(0.0, 100.0) = 1.0;
uniform float crack_density : hint_range(1.0, 50.0) = 10.0;
uniform float crack_thickness : hint_range(0.0, 0.05, 0.001) = 0.03;
uniform float border_width : hint_range(0.0, 0.05, 0.001) = 0.03;
uniform float thickness_variation : hint_range(0.0, 5.0) = 0.0;
uniform float depth : hint_range(0.0, 1.0) = 1.0;

vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	float n = mix(mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
	                  dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
	              mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
	                  dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
	return n;
}

vec2 rand(vec2 n) {
    return fract(sin(vec2(dot(n, vec2(12.9898, 4.1414)), dot(n, vec2(12.9898, 4.1414)) + seed)) * 43758.5453);
}

vec2 worley(vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    float F1 = 1.0;
    float F2 = 1.0;

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = rand(n + g);
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < F1) {
                F2 = F1;
                F1 = d;
            } else if (d < F2) {
                F2 = d;
            }
        }
    }
    return vec2(sqrt(F1), sqrt(F2));
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);

    if (original_color.a < 0.1) {
        discard;
    }

    float thickness_mod = noise(UV * 15.0 + seed);
    float current_thickness = crack_thickness + (crack_thickness * thickness_mod * thickness_variation);
	current_thickness = max(0.0001, current_thickness);

    vec2 p = UV * crack_density + seed;
    vec2 worley_dist = worley(p);
    float crack_value = worley_dist.y - worley_dist.x;

    float crack_line = 1.0 - smoothstep(0.0, current_thickness, crack_value);
    float border_line = 1.0 - smoothstep(0.0, current_thickness + border_width, crack_value);
    float border_only = clamp(border_line - crack_line, 0.0, 1.0);
    float reveal_noise = (noise(UV * 3.0 + seed * 1.5) + 1.0) * 0.5;

    float quantized_noise_level = ceil(reveal_noise * float(steps)) / float(steps);

	quantized_noise_level -= 0.0001;

    float final_crack = 0.0;
	float final_border = 0.0;

    if (progress >= quantized_noise_level) {
        final_crack = crack_line;
		final_border = border_only;
    }

	if (progress < 0.001) {
		final_crack = 0.0;
		final_border = 0.0;
	}

	vec3 final_rgb = original_color.rgb;
	final_rgb = mix(final_rgb, final_rgb * (1.0 - depth), final_border + final_crack);
    final_rgb = mix(final_rgb, crack_color.rgb, final_crack);
    final_rgb = mix(final_rgb, crack_color.rgb * 0.25, final_border);

    COLOR = vec4(final_rgb, original_color.a);
}
