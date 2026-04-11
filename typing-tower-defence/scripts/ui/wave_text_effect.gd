extends RichTextEffect
class_name WaveTextEffect

var bbcode := "wave"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var speed := 2.0
	var height := 6.0
	var spacing := 0.5

	if char_fx.env.has("speed"):
		speed = float(char_fx.env["speed"])

	if char_fx.env.has("height"):
		height = float(char_fx.env["height"])

	if char_fx.env.has("spacing"):
		spacing = float(char_fx.env["spacing"])

	var phase := float(char_fx.relative_index) * spacing
	var y := sin((char_fx.elapsed_time * speed) - phase) * height

	char_fx.offset.y += y
	return true
