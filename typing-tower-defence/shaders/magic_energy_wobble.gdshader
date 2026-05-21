shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.15, 0.65, 1.0, 1.0);

uniform float glow_strength = 1.8;
uniform float pulse_speed = 3.0;
uniform float edge_width = 0.08;

uniform float distortion_strength = 0.025;
uniform float flame_speed = 1.5;

uniform float top_flame_strength = 1.2;
uniform float top_flame_height = 0.22;
uniform float top_flame_breakup = 0.55;
uniform float top_flame_wobble = 0.045;

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

	// Original internal wobble.
	float flame_noise = noise(vec2(uv.x * 8.0, uv.y * 10.0 - TIME * flame_speed));
	uv.x += (flame_noise - 0.5) * distortion_strength;

	vec4 tex = texture(TEXTURE, uv);
	float alpha = tex.a;

	float edge = smoothstep(0.0, edge_width, alpha) - smoothstep(edge_width, edge_width * 2.0, alpha);
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed);

	float upward_flame = smoothstep(1.0, 0.15, UV.y);
	float magic_energy = noise(vec2(UV.x * 14.0, UV.y * 18.0 - TIME * 2.0));

	float glow_alpha = alpha * glow_strength * pulse;
	glow_alpha += edge * glow_strength;
	glow_alpha += magic_energy * 0.25 * upward_flame * alpha;

	// Extra top flame: sample the sprite from lower down and pull it upward.
	float top_zone = smoothstep(top_flame_height, 0.0, UV.y);

	vec2 flame_uv = UV;

	float vertical_pull = top_zone * top_flame_height;
	flame_uv.y += vertical_pull;

	float top_wobble_noise = noise(vec2(UV.x * 10.0, UV.y * 16.0 - TIME * flame_speed * 1.8));
	flame_uv.x += (top_wobble_noise - 0.5) * top_flame_wobble * top_zone;

	vec4 stretched_tex = texture(TEXTURE, flame_uv);

	float breakup_noise = noise(vec2(UV.x * 24.0, UV.y * 18.0 - TIME * flame_speed * 2.4));
	float breakup = smoothstep(top_flame_breakup, 1.0, breakup_noise);

	float finger_noise = noise(vec2(UV.x * 42.0, UV.y * 10.0 - TIME * flame_speed * 2.8));
	float fingers = smoothstep(0.35, 0.9, finger_noise);

	float fade_upward = smoothstep(0.0, top_flame_height, UV.y);
	float connected_base = 1.0 - fade_upward;

	float stretched_alpha = stretched_tex.a * top_zone;
	stretched_alpha *= mix(1.0, breakup * fingers, fade_upward);
	stretched_alpha *= top_flame_strength * pulse;

	// Keep the flame visually connected near the sprite top.
	stretched_alpha += stretched_tex.a * connected_base * 0.45 * top_flame_strength;

	glow_alpha += stretched_alpha;

	COLOR = vec4(glow_color.rgb, glow_alpha);
}