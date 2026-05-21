shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.35, 0.75, 1.0, 1.0);

uniform float glow_strength = 0.55;
uniform float pulse_speed = 1.6;
uniform float edge_width = 0.045;

uniform float distortion_strength = 0.006;
uniform float flame_speed = 0.75;

uniform float top_flame_strength = 0.22;
uniform float top_flame_height = 0.10;
uniform float top_flame_breakup = 0.72;
uniform float top_flame_wobble = 0.012;

uniform float alpha_cut = 0.02;

float rand(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		(c - a) * u.y * (1.0 - u.x) +
		(d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV;

	float flame_noise = noise(vec2(
		uv.x * 6.0,
		uv.y * 8.0 - TIME * flame_speed
	));

	uv.x += (flame_noise - 0.5) * distortion_strength;

	vec4 tex = texture(TEXTURE, uv);
	float alpha = tex.a;

	float alpha_mask = step(alpha_cut, alpha);

	float edge = smoothstep(0.0, edge_width, alpha)
		- smoothstep(edge_width, edge_width * 2.0, alpha);

	float pulse = 0.88 + 0.12 * sin(TIME * pulse_speed);

	float upward_flame = smoothstep(1.0, 0.2, UV.y);
	float magic_energy = noise(vec2(
		UV.x * 10.0,
		UV.y * 12.0 - TIME * 0.9
	));

	float glow_alpha = alpha * glow_strength * pulse;
	glow_alpha += edge * glow_strength * 0.35;
	glow_alpha += magic_energy * 0.055 * upward_flame * alpha;

	float top_zone = smoothstep(top_flame_height, 0.0, UV.y);

	vec2 flame_uv = UV;
	flame_uv.y += top_zone * top_flame_height;

	float top_wobble_noise = noise(vec2(
		UV.x * 8.0,
		UV.y * 12.0 - TIME * flame_speed * 1.3
	));

	flame_uv.x += (top_wobble_noise - 0.5) * top_flame_wobble * top_zone;

	vec4 stretched_tex = texture(TEXTURE, flame_uv);

	float breakup_noise = noise(vec2(
		UV.x * 18.0,
		UV.y * 14.0 - TIME * flame_speed * 1.6
	));

	float breakup = smoothstep(top_flame_breakup, 1.0, breakup_noise);

	float finger_noise = noise(vec2(
		UV.x * 28.0,
		UV.y * 8.0 - TIME * flame_speed * 1.9
	));

	float fingers = smoothstep(0.55, 0.95, finger_noise);

	float fade_upward = smoothstep(0.0, top_flame_height, UV.y);
	float connected_base = 1.0 - fade_upward;

	float stretched_alpha = stretched_tex.a * top_zone;
	stretched_alpha *= mix(0.65, breakup * fingers, fade_upward);
	stretched_alpha *= top_flame_strength * pulse;

	stretched_alpha += stretched_tex.a * connected_base * 0.12 * top_flame_strength;

	glow_alpha += stretched_alpha;

	COLOR = vec4(glow_color.rgb, glow_alpha * alpha_mask);
}