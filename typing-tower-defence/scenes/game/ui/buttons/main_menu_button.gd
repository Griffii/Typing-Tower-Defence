# res://scripts/ui/main_menu_button.gd
class_name MainMenuButton
extends Control

signal pressed
signal button_animation_finished

@export var label_text: String = "Menu Button":
	set(value):
		label_text = value
		if button != null:
			button.text = label_text

@export_group("Hover Juice")
@export var hover_scale: Vector2 = Vector2(1.08, 1.08)
@export var hover_pop_scale: Vector2 = Vector2(1.13, 1.13)
@export var hover_nudge: Vector2 = Vector2(8.0, 0.0)
@export var hover_rotation_degrees: float = -1.5
@export var hover_pop_time: float = 0.07
@export var hover_settle_time: float = 0.11
@export var hover_exit_time: float = 0.10

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var button: Button = %Button

var button_base_position: Vector2 = Vector2.ZERO
var button_base_scale: Vector2 = Vector2.ONE
var button_base_rotation: float = 0.0

var hover_tween: Tween = null
var is_animating: bool = false
var is_hovered: bool = false


func _ready() -> void:
	if button != null:
		button.text = label_text
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		button_base_position = button.position
		button_base_scale = button.scale
		button_base_rotation = button.rotation

		button.pivot_offset = button.size * 0.5
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if not button.pressed.is_connected(_on_button_pressed):
			button.pressed.connect(_on_button_pressed)

		if not button.mouse_entered.is_connected(_on_mouse_entered):
			button.mouse_entered.connect(_on_mouse_entered)

		if not button.mouse_exited.is_connected(_on_mouse_exited):
			button.mouse_exited.connect(_on_mouse_exited)

	if animation_player != null and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)


func animate_in_button() -> void:
	_kill_hover_tween()

	visible = true
	is_animating = true
	is_hovered = false

	if button != null:
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_reset_button_hover_transform()

	if animation_player != null and animation_player.has_animation("slide_in"):
		animation_player.play("slide_in")
	else:
		if button != null:
			button.mouse_filter = Control.MOUSE_FILTER_STOP
		is_animating = false
		button_animation_finished.emit()


func animate_out_button() -> void:
	_kill_hover_tween()

	is_animating = true
	is_hovered = false

	if button != null:
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_reset_button_hover_transform()

	if animation_player != null and animation_player.has_animation("slide_out"):
		animation_player.play("slide_out")
	else:
		visible = false
		is_animating = false
		button_animation_finished.emit()


func snap_in_hidden_left() -> void:
	_kill_hover_tween()

	visible = true
	is_animating = false
	is_hovered = false

	if button != null:
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_reset_button_hover_transform()

	if animation_player != null and animation_player.has_animation("hidden_left"):
		animation_player.play("hidden_left")
		animation_player.seek(0.0, true)


func snap_in_place() -> void:
	_kill_hover_tween()

	visible = true
	is_animating = false
	is_hovered = false

	if button != null:
		_reset_button_hover_transform()
		button.mouse_filter = Control.MOUSE_FILTER_STOP

	if animation_player != null and animation_player.has_animation("RESET"):
		animation_player.play("RESET")
		animation_player.seek(0.0, true)


func refresh_base_transform() -> void:
	if button == null:
		return

	button_base_position = button.position
	button_base_scale = button.scale
	button_base_rotation = button.rotation
	button.pivot_offset = button.size * 0.5


func set_interactable(enabled: bool) -> void:
	if button == null:
		return

	button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slide_in":
		is_animating = false
		set_interactable(true)
		button_animation_finished.emit()
	elif anim_name == "slide_out":
		is_animating = false
		visible = false
		set_interactable(false)
		button_animation_finished.emit()


func _on_button_pressed() -> void:
	pressed.emit()


func _on_mouse_entered() -> void:
	if is_animating:
		return

	if button == null:
		return

	if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return

	is_hovered = true
	_play_hover_in()


func _on_mouse_exited() -> void:
	if is_animating:
		return

	if button == null:
		return

	is_hovered = false
	_play_hover_out()


func _play_hover_in() -> void:
	if button == null:
		return

	_kill_hover_tween()

	var hover_position := button_base_position + hover_nudge
	var hover_rotation := button_base_rotation + deg_to_rad(hover_rotation_degrees)

	hover_tween = create_tween()

	hover_tween.parallel().tween_property(
		button,
		"scale",
		button_base_scale * hover_pop_scale,
		hover_pop_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	hover_tween.parallel().tween_property(
		button,
		"position",
		hover_position + Vector2(3.0, 0.0),
		hover_pop_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	hover_tween.parallel().tween_property(
		button,
		"rotation",
		hover_rotation,
		hover_pop_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	hover_tween.tween_property(
		button,
		"scale",
		button_base_scale * hover_scale,
		hover_settle_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	hover_tween.parallel().tween_property(
		button,
		"position",
		hover_position,
		hover_settle_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	hover_tween.finished.connect(func() -> void:
		hover_tween = null
	)


func _play_hover_out() -> void:
	if button == null:
		return

	_kill_hover_tween()

	hover_tween = create_tween()

	hover_tween.parallel().tween_property(
		button,
		"scale",
		button_base_scale,
		hover_exit_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	hover_tween.parallel().tween_property(
		button,
		"position",
		button_base_position,
		hover_exit_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	hover_tween.parallel().tween_property(
		button,
		"rotation",
		button_base_rotation,
		hover_exit_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	hover_tween.finished.connect(func() -> void:
		hover_tween = null
	)


func _reset_button_hover_transform() -> void:
	if button == null:
		return

	button.position = button_base_position
	button.scale = button_base_scale
	button.rotation = button_base_rotation


func _kill_hover_tween() -> void:
	if hover_tween != null and hover_tween.is_valid():
		hover_tween.kill()

	hover_tween = null
