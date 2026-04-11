# res://scripts/game/ui/word_label_controller.gd
class_name WordLabelController
extends Node2D

@export var home_offset: Vector2 = Vector2.ZERO
@export var max_drift_distance: float = 110.0

@export var spring_strength_near: float = 0.25
@export var spring_strength_far: float = 18.0
@export var spring_ramp_distance: float = 90.0
@export var damping_strength: float = 3.0
@export var collision_push_strength: float = 300.0

@export var bob_amplitude: float = 10.0
@export var bob_speed: float = 2.2
@export var bob_phase_randomness: float = 10.0
@export var upward_bias_strength: float = 10.0

@export var collision_padding: Vector2 = Vector2(20.0, 12.0)

@onready var label_body: CharacterBody2D = %LabelBody
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var label_ui: Control = %LabelUI
@onready var background: PanelContainer = %Background
@onready var word_label: RichTextLabel = %WordLabel

var anchor: Node2D = null
var current_word: String = ""
var typing_progress: String = ""
var is_targeted: bool = false

var _home_global_position: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _layout_refresh_pending: bool = false
var _bob_time: float = 0.0
var _bob_phase: float = 0.0


func _ready() -> void:
	if collision_shape != null:
		if collision_shape.shape == null:
			collision_shape.shape = RectangleShape2D.new()
		else:
			collision_shape.shape = collision_shape.shape.duplicate()

	if word_label != null:
		word_label.bbcode_enabled = true
		word_label.fit_content = true
		word_label.scroll_active = false
		word_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	if background != null:
		background.custom_minimum_size = Vector2.ZERO

	randomize()
	_bob_phase = randf() * TAU * bob_phase_randomness

	_update_word_visual()
	_queue_layout_refresh()


func _physics_process(delta: float) -> void:
	if label_body == null:
		return

	_bob_time += delta
	_update_home_position()

	var bob_offset := Vector2(
		sin((_bob_time * bob_speed * 0.73) + _bob_phase) * 2.0,
		-sin((_bob_time * bob_speed) + _bob_phase) * bob_amplitude
	)

	var target_home: Vector2 = _home_global_position + bob_offset
	var current_pos: Vector2 = label_body.global_position
	var to_home: Vector2 = target_home - current_pos
	var distance_to_home: float = to_home.length()

	if distance_to_home > max_drift_distance and distance_to_home > 0.001:
		label_body.global_position = target_home - to_home.normalized() * max_drift_distance
		current_pos = label_body.global_position
		to_home = target_home - current_pos
		distance_to_home = to_home.length()

	var spring_ratio: float = clamp(distance_to_home / spring_ramp_distance, 0.0, 1.0)
	var spring_strength: float = lerp(spring_strength_near, spring_strength_far, spring_ratio)

	var spring_force: Vector2 = to_home * spring_strength
	var damping_force: Vector2 = -_velocity * damping_strength

	var near_home_ratio: float = 1.0 - spring_ratio
	var buoyancy_force := Vector2(0.0, -upward_bias_strength * near_home_ratio)

	_velocity += (spring_force + damping_force + buoyancy_force) * delta

	label_body.velocity = _velocity
	label_body.move_and_slide()
	_velocity = label_body.velocity

	for i in range(label_body.get_slide_collision_count()):
		var collision := label_body.get_slide_collision(i)
		if collision == null:
			continue

		var normal: Vector2 = collision.get_normal()
		if normal == Vector2.ZERO:
			continue

		_velocity += normal * collision_push_strength * delta
		_velocity += Vector2.UP * (collision_push_strength * 0.14) * delta

		var other := collision.get_collider()
		if other is CharacterBody2D:
			var other_body := other as CharacterBody2D
			other_body.velocity -= normal * collision_push_strength * delta * 0.32
			other_body.velocity += Vector2.UP * (collision_push_strength * 0.08) * delta


func set_anchor(new_anchor: Node2D) -> void:
	anchor = new_anchor
	_update_home_position()

	if label_body != null:
		label_body.global_position = _home_global_position
		_velocity = Vector2.ZERO


func set_word(word: String) -> void:
	current_word = word
	typing_progress = ""
	_update_word_visual()
	_queue_layout_refresh()


func set_typing_progress(text: String) -> void:
	typing_progress = text
	_update_word_visual()


func clear_typing_feedback() -> void:
	typing_progress = ""
	_update_word_visual()


func set_targeted(targeted: bool) -> void:
	is_targeted = targeted
	_update_target_visual()


func get_current_word() -> String:
	return current_word


func _update_home_position() -> void:
	if anchor != null and is_instance_valid(anchor):
		_home_global_position = anchor.global_position + home_offset
	else:
		_home_global_position = global_position + home_offset


func _update_word_visual() -> void:
	if word_label == null:
		return

	word_label.text = _build_word_bbcode(typing_progress)
	_update_target_visual()


func _update_target_visual() -> void:
	if background == null:
		return

	background.modulate = Color(1, 1, 1, 1.0 if is_targeted else 0.92)


func _queue_layout_refresh() -> void:
	if _layout_refresh_pending:
		return

	_layout_refresh_pending = true
	call_deferred("_refresh_layout")


func _refresh_layout() -> void:
	_layout_refresh_pending = false

	if word_label == null or background == null or label_ui == null or collision_shape == null:
		return

	await get_tree().process_frame

	var text_size: Vector2 = word_label.get_combined_minimum_size()
	var final_size: Vector2 = text_size + collision_padding
	final_size.x = max(final_size.x, 24.0)
	final_size.y = max(final_size.y, 24.0)

	label_ui.custom_minimum_size = final_size
	label_ui.size = final_size
	label_ui.position = -final_size * 0.5

	background.custom_minimum_size = final_size
	background.size = final_size
	background.position = Vector2.ZERO

	var rect := collision_shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		collision_shape.shape = rect

	rect.size = final_size
	collision_shape.position = Vector2.ZERO


func _build_word_bbcode(input_text: String) -> String:
	if current_word.is_empty():
		return ""

	var bbcode: String = "[center]"

	for i in range(current_word.length()):
		var target_char: String = current_word.substr(i, 1)

		if i < input_text.length():
			var typed_char: String = input_text.substr(i, 1)

			if typed_char == target_char:
				# Bright neon green (very readable)
				bbcode += "[color=#4CFF4C]" + _escape_bbcode(target_char) + "[/color]"
			else:
				# Strong red (clear failure)
				bbcode += "[color=#FF4C4C]" + _escape_bbcode(target_char) + "[/color]"
		else:
			# Brighter white with slight blue tint for clarity
			bbcode += "[color=#F5F7FF]" + _escape_bbcode(target_char) + "[/color]"

	bbcode += "[/center]"
	return bbcode


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")
