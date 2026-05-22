shader_type canvas_item;

render_mode blend_mix;

uniform vec4 ice_color : source_color = vec4(0.45, 0.85, 1.0, 0.32);
uniform vec4 frost_color : source_color = vec4(0.85, 0.97, 1.0, 0.22);
uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float edge_softness : hint_range(0.001, 0.5) = 0.12;
uniform float noise_scale : hint_range(1.0, 80.0) = 22.0;
uniform float shimmer_speed : hint_range(0.0, 5.0) = 0.45;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.25;
uniform float crack_strength : hint_range(0.0, 1.0) = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) + 
		(c - a) * u.y * (1.0 - u.x) + 
		(d - b) * u.x * u.y;
}

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);

	float circle_mask = 1.0 - smoothstep(radius, radius + edge_softness, dist);
	float inner_fade = smoothstep(0.0, radius, dist);

	float n1 = noise(UV * noise_scale + vec2(TIME * shimmer_speed, 0.0));
	float n2 = noise(UV * noise_scale * 2.2 - vec2(0.0, TIME * shimmer_speed));

	float shimmer = (n1 * 0.6 + n2 * 0.4) * shimmer_strength;

	float cracks = smoothstep(0.72, 0.82, n2) * crack_strength;
	float edge_glow = smoothstep(radius, radius - edge_softness * 1.8, dist) * inner_fade;

	vec4 final_color = ice_color;
	final_color.rgb = mix(final_color.rgb, frost_color.rgb, shimmer + cracks);
	final_color.a = (ice_color.a + shimmer * 0.18 + cracks * 0.22 + edge_glow * 0.18) * circle_mask;

	COLOR = final_color;
}