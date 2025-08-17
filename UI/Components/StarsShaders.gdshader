shader_type canvas_item;

group_uniforms BackgroundStars;
uniform sampler2D gradientB;
uniform float frequencyBgStar: hint_range(0.950, 1.0, 0.001) = 0.996;
uniform float shineFrequencyBgStar: hint_range(0.0, 5.0, 1.0) = 1.0;
uniform float transparencyBgStar: hint_range(0.0, 1.0, 0.01) = 0.0;

group_uniforms Background;
uniform vec4 colorBackground: source_color = vec4(0.05, 0.04, 0.20, 1.0);
uniform float transparencyBackground: hint_range(0.0, 1.0, 0.01) = 0.0;

group_uniforms Noise;
uniform float seed: hint_range(0.0, 100.0, 1.0) = 0.0;

float rand(vec2 st) {
	return fract(sin(dot(st.xy, vec2(seed+12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	float color = 0.0;
	COLOR = vec4(colorBackground.rgb, 1.0 - transparencyBackground);

	if (rand(SCREEN_UV.xy / 20.0) > frequencyBgStar) {
			float r = rand(SCREEN_UV.xy);
			color = r * (0.85 * sin(TIME * shineFrequencyBgStar * (r * 5.0) + 720.0 * r) + 0.95);
			vec4 colormapB = texture(gradientB, vec2(r));
			COLOR += color * colormapB * (1.0 - transparencyBgStar);
	}
}