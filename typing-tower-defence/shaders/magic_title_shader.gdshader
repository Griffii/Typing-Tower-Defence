shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(1.0, 0.72, 0.22, 1.0);
uniform float glow_strength = 0.45;
uniform float pulse_strength = 0.12;
uniform float pulse_speed = 1.1;

uniform float blur_offset = 0.006;

void fragment() {
	float a = 0.0;

	a += texture(TEXTURE, UV + vec2( blur_offset, 0.0)).a;
	a += texture(TEXTURE, UV + vec2(-blur_offset, 0.0)).a;
	a += texture(TEXTURE, UV + vec2(0.0,  blur_offset)).a;
	a += texture(TEXTURE, UV + vec2(0.0, -blur_offset)).a;

	a += texture(TEXTURE, UV + vec2( blur_offset,  blur_offset)).a;
	a += texture(TEXTURE, UV + vec2(-blur_offset,  blur_offset)).a;
	a += texture(TEXTURE, UV + vec2( blur_offset, -blur_offset)).a;
	a += texture(TEXTURE, UV + vec2(-blur_offset, -blur_offset)).a;

	a /= 8.0;

	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_strength;

	COLOR = vec4(
		glow_color.rgb,
		a * glow_strength * pulse
	);
}