# res://scripts/ui/magic_title_label.gd
class_name MagicTitleLabel
extends Control

@export var title_text: String = "Leximancer"

@export var title_font: FontFile
@export var font_size: int = 64
@export var letter_shader_material: ShaderMaterial

@export var letter_spacing: float = 4.0

@export var intro_delay_min: float = 0.0
@export var intro_delay_max: float = 0.55
@export var intro_time: float = 0.45
@export var intro_y_offset: float = 14.0

@export var idle_float_height: float = 2.5
@export var idle_float_speed: float = 1.2

@export var mouse_push_radius: float = 85.0
@export var mouse_push_strength: float = 14.0
@export var mouse_lerp_speed: float = 10.0

@export var font_color: Color = Color("#fff4d6")
@export var outline_color: Color = Color("#07040f")
@export var outline_size: int = 8

@onready var letter_container: Control = %LetterContainer

var letters: Array[Label] = []
var base_positions: Array[Vector2] = []
var push_offsets: Array[Vector2] = []
var idle_phases: Array[float] = []

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
	_update_letter_motion(delta)


func _build_letters() -> void:
	for child in letter_container.get_children():
		child.queue_free()

	letters.clear()
	base_positions.clear()
	push_offsets.clear()
	idle_phases.clear()

	var x: float = 0.0

	for i in range(title_text.length()):
		var letter_text: String = title_text.substr(i, 1)

		var letter := Label.new()
		letter.text = letter_text
		letter.modulate.a = 0.0
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE

		letter.add_theme_color_override("font_color", font_color)
		letter.add_theme_color_override("font_outline_color", outline_color)
		letter.add_theme_constant_override("outline_size", outline_size)
		letter.add_theme_font_size_override("font_size", font_size)

		if title_font != null:
			letter.add_theme_font_override("font", title_font)

		if letter_shader_material != null:
			letter.material = letter_shader_material.duplicate(true)

		letter_container.add_child(letter)

		await get_tree().process_frame

		var letter_size: Vector2 = letter.get_combined_minimum_size()
		var size_x: float = letter_size.x

		letter.position = Vector2(x, 0.0)
		letter.pivot_offset = letter_size * 0.5

		letters.append(letter)
		base_positions.append(letter.position)
		push_offsets.append(Vector2.ZERO)
		idle_phases.append(rng.randf_range(0.0, TAU))

		x += size_x + letter_spacing

	letter_container.custom_minimum_size = Vector2(x, font_size)


func animate_in() -> void:
	var indices: Array[int] = []

	for i in range(letters.size()):
		indices.append(i)

	indices.shuffle()

	for index in indices:
		var letter: Label = letters[index]
		var base_pos: Vector2 = base_positions[index]

		letter.position = base_pos + Vector2(0.0, intro_y_offset)
		letter.scale = Vector2(0.92, 0.92)
		letter.modulate.a = 0.0

		var delay: float = rng.randf_range(intro_delay_min, intro_delay_max)

		var tween := create_tween()

		tween.tween_interval(delay)

		tween.parallel().tween_property(
			letter,
			"modulate:a",
			1.0,
			intro_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		tween.parallel().tween_property(
			letter,
			"scale",
			Vector2.ONE,
			intro_time
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween.parallel().tween_property(
			letter,
			"position",
			base_pos,
			intro_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _update_letter_motion(delta: float) -> void:
	if letters.is_empty():
		return

	var mouse_global: Vector2 = get_global_mouse_position()

	for i in range(letters.size()):
		var letter: Label = letters[i]

		if letter == null or not is_instance_valid(letter):
			continue

		var base_pos: Vector2 = base_positions[i]

		var idle_y: float = sin(
			time_passed * idle_float_speed + idle_phases[i]
		) * idle_float_height

		var target_push: Vector2 = _get_mouse_push_for_letter(
			letter,
			mouse_global
		)

		push_offsets[i] = push_offsets[i].lerp(
			target_push,
			clampf(mouse_lerp_speed * delta, 0.0, 1.0)
		)

		letter.position = (
			base_pos +
			Vector2(0.0, idle_y) +
			push_offsets[i]
		)


func _get_mouse_push_for_letter(
	letter: Label,
	mouse_global: Vector2
) -> Vector2:
	var letter_center: Vector2 = (
		letter.global_position +
		letter.size * 0.5
	)

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

	return (
		to_letter.normalized() *
		mouse_push_strength *
		strength
	)
