shader_type canvas_item;

// Fade the lower part of the ferryman so he reads as standing behind the
// boat's near gunwale, without pasting a hard rectangular foreground strip.
uniform float fade_start = 0.72;
uniform float fade_end = 0.80;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float fade = smoothstep(fade_start, fade_end, UV.y);
	c.a *= 1.0 - fade;
	COLOR = c;
}
