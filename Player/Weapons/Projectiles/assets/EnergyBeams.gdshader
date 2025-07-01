// This shader is intended for Godot 4.x
shader_type canvas_item;
render_mode blend_add;

// --- Uniforms for Artistic & Gameplay Control ---
uniform int beams : hint_range(1, 8) = 2; // How many beams the energy field should have.
uniform float energy : hint_range(0.0, 20.0) = 3.0; // How much the beams will travel up and down.
uniform int roughness : hint_range(1, 10) = 3; // How compact the noise texture will be.
uniform int frequency : hint_range(1, 20) = 10; // Amount of "ripples" in the beams.
uniform float speed : hint_range(0.0, 5.0) = 1.0; // Animation speed.
uniform float thickness : hint_range(0.0, 0.1) = 0.006; // Thickness of the main beam.
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.03; // Thickness of the outline color.
uniform float beam_difference : hint_range(0.0, 1.0) = 0.0; // Thickness difference between beams.
uniform float progress : hint_range(0.0, 1.0) = 1.0; // Controls the overall intensity/visibility.

// --- Colors ---
uniform vec4 color : source_color = vec4(0.91, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(0.5, 1.0, 0.96, 1.0);

// --- Glow Controls (NEW) ---
// کنترل‌های جدید برای افکت درخشش
uniform vec4 glow_color : source_color = vec4(0.1, 0.7, 1.0, 1.0); // رنگ درخشش
uniform float glow_thickness : hint_range(0.0, 0.2) = 0.05; // ضخامت لایه درخشش
uniform float glow_falloff : hint_range(0.0, 0.5) = 0.1; // نرمی لبه‌های درخشش

// --- Helper Functions ---

// Simple pseudo-random generator.
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Generates a smooth noise value for a given coordinate.
float noise(vec2 uv) {
	vec2 uv_index = floor(uv);
	vec2 uv_fract = fract(uv);
	float a = random(uv_index);
	float b = random(uv_index + vec2(1.0, 0.0));
	float c = random(uv_index + vec2(0.0, 1.0));
	float d = random(uv_index + vec2(1.0, 1.0));
	vec2 blur = smoothstep(0.0, 1.0, uv_fract);
	return mix(a, b, blur.x) + (c - a) * blur.y * (1.0 - blur.x) + (d - b) * blur.y * blur.x;
}

// Fractal Brownian Motion: layers multiple octaves of noise for a detailed texture.
float fbm(vec2 uv, float time) {
	float value = 0.0;
	float amp = 0.01 * energy * progress;
	float freq = float(frequency);

	for(int i = 0; i < roughness; i++) {
		value += amp * noise(freq * vec2(uv.x, uv.y + time));
		amp *= 0.5;
		freq *= 2.0;
	}
	return value;
}

// A standard blend mode function.
vec4 difference(vec4 base, vec4 blend){
	return abs(base - blend);
}

// Function to calculate a single animated bolt of energy.
vec4 create_bolt(vec2 uv, float time, float i) {
	// Lock the beam to the vertical edges for stability.
	float falloff = smoothstep(0.0, 0.05, uv.x) * smoothstep(0.0, 0.05, 1.0 - uv.x);

	// Generate the core "cloud" texture for the beam.
	vec4 clouds = vec4(fbm(uv + float(i), time * speed)) * falloff;
	vec4 diff_clouds = difference(clouds, vec4(uv.y - 0.5 + (uv.y * falloff * 0.02 * energy * progress)));

	// Create another noise layer to make the "turn-off" effect more interesting.
	vec4 turn_off_mask = vec4(fbm(uv * 2.0, time)) * 5.0;
	diff_clouds += smoothstep(0.0, 0.8, turn_off_mask) * 0.1 * (1.0 - progress);

	// --- Beam Thickness Logic ---
	float beam_t = 1.0 - (thickness / (min(float(i) + beam_difference, 1.0) + (1.0 - beam_difference))) * progress;
	vec4 beam = smoothstep(beam_t, beam_t + 0.005 * progress, 1.0 - diff_clouds);

	// --- Beam Outline Logic ---
	float outline_t = beam_t - (outline_thickness * progress);
	vec4 beam_outline_shape = smoothstep(outline_t, outline_t + 0.04, 1.0 - diff_clouds);
	
	// --- Glow Logic (NEW) ---
	// منطق جدید برای محاسبه درخشش
	float glow_t = outline_t - (glow_thickness * progress);
	vec4 glow_shape = smoothstep(glow_t, glow_t + glow_falloff, 1.0 - diff_clouds);

	// --- Layering ---
	// لایه‌بندی برای اطمینان از اینکه هر لایه روی لایه قبلی قرار می‌گیرد
	vec4 glow = clamp(glow_shape - beam_outline_shape, 0.0, 1.0) * glow_color; // لایه بیرونی (درخشش)
	vec4 outline = clamp(beam_outline_shape - beam, 0.0, 1.0) * outline_color; // لایه میانی (حاشیه)
	vec4 core_beam = beam * color; // لایه داخلی (هسته اصلی)

	// Combine and return the final color for this single bolt.
	// ترکیب لایه‌ها برای ساخت رنگ نهایی
	return core_beam + outline + glow;
}

// --- Main Fragment Function ---
void fragment() {
	vec4 final_beam = vec4(0.0);

	// Loop through the number of beams and combine them by taking the brightest value.
	for (int i = 0; i < beams; i++){
		final_beam = max(final_beam, create_bolt(UV, TIME, float(i)));
	}

	COLOR = final_beam;
}