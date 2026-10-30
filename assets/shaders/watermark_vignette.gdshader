shader_type canvas_item;

// Soft bottom-right vignette that hides the AI watermark without a hard box.
void fragment() {
	vec2 uv = UV;
	float d = distance(uv, vec2(1.0, 1.0));
	float a = smoothstep(0.58, 0.03, d) * 0.96;
	COLOR = vec4(0.03, 0.04, 0.035, a);
}
