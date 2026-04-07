shader_type canvas_item;

uniform float wave_speed = 0.5;
uniform float wave_strength = 0.1;
uniform float wave_scale = 5.0;

void fragment() {
    vec2 uv = UV;
    float t = TIME * wave_speed;

    uv.x += sin(uv.y * wave_scale + t) * wave_strength;
    uv.y += cos(uv.x * wave_scale * 0.8 + t * 0.8) * wave_strength * 0.7;

    COLOR = texture(TEXTURE, uv);
}