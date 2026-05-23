# res://scripts/ui/magic_title_label.gd
class_name MagicTitleLabel
extends Control

@export var title_text: String = "Leximancer"

@export var title_font: FontFile
@export var font_size: int = 112
@export var letter_shader_material: ShaderMaterial
@export var letter_spacing: float = 4.0

@export_group("Intro Animation")
@export var intro_letter_delay: float = 0.1
@export var intro_time: float = 0.65
@export var intro_y_offset: float = 50.0
@export var intro_start_scale: Vector2 = Vector2(0.92, 0.92)

@export_group("Idle Motion")
@export var idle_float_height: float = 2.5
@export var idle_float_speed: float = 1.2

@export_group("Mouse Interaction")
@export var mouse_push_radius: float = 85.0
@export var mouse_push_strength: float = 14.0
@export var mouse_lerp_speed: float = 10.0

@export_group("Visuals")
@export var font_color: Color = Color("#ffd978")
@export var outline_color: Color = Color("#4a2200")
@export var outline_size: int = 10

@export_group("Glow Layer")
@export var use_glow_layer: bool = true
@export var glow_color: Color = Color("#ffb936")
@export var glow_alpha: float = 0.7
@export var glow_offset: Vector2 = Vector2.ZERO
@export var glow_outline_size: int = 14

@export_group("Magical Color Cycle")
@export var use_color_cycle: bool = true
@export var color_cycle_speed: float = 0.75
@export var color_cycle_blend_width: float = 0.35

@export var color_cycle_palette: Array[Color] = [
	Color("#fff4c2"),
	Color("#ffd978"),
	Color("#ffbf47"),
	Color("#ffe7a8"),
	Color("#ffcf63")
]

@export_group("Block Shadow")
@export var use_block_shadow: bool = true
@export var shadow_color: Color = Color("#120400")
@export var shadow_alpha: float = 0.82
@export var shadow_offset: Vector2 = Vector2(8.0, 10.0)

@onready var letter_container: Control = %LetterContainer

var letters: Array[Label] = []
var glow_letters: Array[Label] = []
var shadow_letters: Array[Label] = []

var base_positions: Array[Vector2] = []
var push_offsets: Array[Vector2] = []
var idle_phases: Array[float] = []
var letter_intro_active: Array[bool] = []

var time_passed: float = 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_setup")


func _setup() -> void:
	await _build_letters()
	animate_in()


func _process(delta: float) -> void:
	time_passed += delta
	_update_letter_colors()
	_update_letter_motion(delta)


func _build_letters() -> void:
	for child in letter_container.get_children():
		child.queue_free()

	letters.clear()
	glow_letters.clear()
	shadow_letters.clear()
	base_positions.clear()
	push_offsets.clear()
	idle_phases.clear()
	letter_intro_active.clear()

	var x: float = 0.0

	for i in range(title_text.length()):
		var letter_text: String = title_text.substr(i, 1)

		var shadow: Label = _make_letter(letter_text, "shadow")
		var glow: Label = _make_letter(letter_text, "glow")
		var letter: Label = _make_letter(letter_text, "main")

		if use_block_shadow:
			letter_container.add_child(shadow)

		if use_glow_layer:
			letter_container.add_child(glow)

		letter_container.add_child(letter)

		await get_tree().process_frame

		var letter_size: Vector2 = letter.get_combined_minimum_size()
		var base_pos := Vector2(x, 0.0)

		if use_block_shadow:
			shadow.position = base_pos + shadow_offset
			shadow.pivot_offset = letter_size * 0.5

		if use_glow_layer:
			glow.position = base_pos + glow_offset
			glow.pivot_offset = letter_size * 0.5

		letter.position = base_pos
		letter.pivot_offset = letter_size * 0.5

		letters.append(letter)
		glow_letters.append(glow)
		shadow_letters.append(shadow)

		base_positions.append(base_pos)
		push_offsets.append(Vector2.ZERO)
		idle_phases.append(rng.randf_range(0.0, TAU))
		letter_intro_active.append(false)

		x += letter_size.x + letter_spacing

	letter_container.custom_minimum_size = Vector2(x, font_size)


func _make_letter(letter_text: String, layer_type: String) -> Label:
	var label := Label.new()

	label.text = letter_text
	label.modulate.a = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label.add_theme_font_size_override("font_size", font_size)

	if title_font != null:
		label.add_theme_font_override("font", title_font)

	match layer_type:
		"shadow":
			var c := shadow_color
			c.a = shadow_alpha

			label.add_theme_color_override("font_color", c)
			label.add_theme_color_override("font_outline_color", c)
			label.add_theme_constant_override("outline_size", max(1, outline_size))

		"glow":
			var c := glow_color
			c.a = glow_alpha

			label.add_theme_color_override("font_color", c)
			label.add_theme_color_override("font_outline_color", c)
			label.add_theme_constant_override("outline_size", glow_outline_size)

			if letter_shader_material != null:
				label.material = letter_shader_material.duplicate(true)

		_:
			label.add_theme_color_override("font_color", font_color)
			label.add_theme_color_override("font_outline_color", outline_color)
			label.add_theme_constant_override("outline_size", outline_size)

	return label


func animate_in() -> void:
	var indices: Array[int] = []

	for i in range(letters.size()):
		indices.append(i)

	indices.shuffle()

	for index in indices:
		var letter: Label = letters[index]
		var glow: Label = glow_letters[index]
		var shadow: Label = shadow_letters[index]

		var base_pos: Vector2 = base_positions[index]

		letter_intro_active[index] = true

		letter.position = base_pos + Vector2(0.0, intro_y_offset)
		letter.scale = intro_start_scale
		letter.modulate.a = 0.0

		if use_glow_layer and glow != null:
			glow.position = base_pos + glow_offset + Vector2(0.0, intro_y_offset)
			glow.scale = intro_start_scale
			glow.modulate.a = 0.0

		if use_block_shadow and shadow != null:
			shadow.position = base_pos + shadow_offset + Vector2(0.0, intro_y_offset)
			shadow.scale = intro_start_scale
			shadow.modulate.a = 0.0

		var tween := create_tween()

		tween.parallel().tween_property(letter, "modulate:a", 1.0, intro_time)
		tween.parallel().tween_property(letter, "scale", Vector2.ONE, intro_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(letter, "position", base_pos, intro_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		if use_glow_layer and glow != null:
			tween.parallel().tween_property(glow, "modulate:a", glow_alpha, intro_time)
			tween.parallel().tween_property(glow, "scale", Vector2.ONE, intro_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(glow, "position", base_pos + glow_offset, intro_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		if use_block_shadow and shadow != null:
			tween.parallel().tween_property(shadow, "modulate:a", shadow_alpha, intro_time)
			tween.parallel().tween_property(shadow, "scale", Vector2.ONE, intro_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(shadow, "position", base_pos + shadow_offset, intro_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween.finished.connect(func() -> void:
			letter_intro_active[index] = false
		)

		await get_tree().create_timer(intro_letter_delay).timeout


func _update_letter_colors() -> void:
	if not use_color_cycle:
		return

	if color_cycle_palette.is_empty():
		return

	for i in range(letters.size()):
		var letter := letters[i]

		if letter == null or not is_instance_valid(letter):
			continue

		var color := _get_cycle_color(-float(i) * color_cycle_blend_width)
		letter.add_theme_color_override("font_color", color)


func _get_cycle_color(offset: float) -> Color:
	var count := color_cycle_palette.size()

	if count == 1:
		return color_cycle_palette[0]

	var t := fposmod(time_passed * color_cycle_speed + offset, float(count))
	var index_a := int(floor(t)) % count
	var index_b := (index_a + 1) % count

	var blend := smoothstep(0.0, 1.0, t - floor(t))

	return color_cycle_palette[index_a].lerp(
		color_cycle_palette[index_b],
		blend
	)


func _update_letter_motion(delta: float) -> void:
	if letters.is_empty():
		return

	var mouse_global: Vector2 = get_global_mouse_position()

	for i in range(letters.size()):
		var letter := letters[i]
		var glow := glow_letters[i]
		var shadow := shadow_letters[i]

		if letter == null or not is_instance_valid(letter):
			continue

		if bool(letter_intro_active[i]):
			continue

		var base_pos: Vector2 = base_positions[i]

		var idle_y := sin(
			time_passed * idle_float_speed +
			idle_phases[i]
		) * idle_float_height

		var target_push := _get_mouse_push_for_letter(letter, mouse_global)

		push_offsets[i] = push_offsets[i].lerp(
			target_push,
			clampf(mouse_lerp_speed * delta, 0.0, 1.0)
		)

		var final_pos := base_pos + Vector2(0.0, idle_y) + push_offsets[i]

		letter.position = final_pos

		if use_glow_layer and glow != null:
			glow.position = final_pos + glow_offset

		if use_block_shadow and shadow != null:
			shadow.position = final_pos + shadow_offset


func _get_mouse_push_for_letter(
	letter: Label,
	mouse_global: Vector2
) -> Vector2:
	var letter_center: Vector2 = letter.global_position + letter.size * 0.5
	var to_letter: Vector2 = letter_center - mouse_global
	var distance: float = to_letter.length()

	if distance >= mouse_push_radius:
		return Vector2.ZERO

	if distance <= 0.001:
		return Vector2(
			rng.randf_range(-1.0, 1.0),
			rng.randf_range(-1.0, 1.0)
		).normalized() * mouse_push_strength

	var strength: float = 1.0 - (distance / mouse_push_radius)
	strength *= strength

	return to_letter.normalized() * mouse_push_strength * strength
