extends RichTextEffect
class_name TypeColorEffect

var bbcode := "typecolor"

# How many visible text characters should be recolored from the start.
# Newlines and bbcode structure are ignored automatically because this runs per rendered character.
var typed_count: int = 0

# Default typed color. Can also be overridden in bbcode params.
var default_color: Color = Color("6fdc8c")


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var typed_color := default_color

	if char_fx.env.has("color"):
		typed_color = Color(str(char_fx.env["color"]))

	if char_fx.relative_index < typed_count:
		char_fx.color = typed_color

	return true
