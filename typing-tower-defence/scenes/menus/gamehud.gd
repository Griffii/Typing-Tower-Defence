extends CanvasLayer

signal start_wave_pressed
signal game_menu_pressed
signal text_submitted(text: String)
signal text_changed(text: String)

const GAME_MENU_HOVER_OFFSET: Vector2 = Vector2(5.0, 0.0)
const GAME_MENU_TWEEN_DURATION: float = 0.1

@onready var wave_label: Label = %WaveLabel
@onready var status_label: Label = %StatusLabel

@onready var start_wave_button: Button = %StartWaveButton
@onready var game_menu_button: Button = %GameMenuButton

@onready var input_field: LineEdit = %InputField

@onready var base_hp_label: Label = %BaseHpLabel

@onready var feedback_label: Label = %FeedbackLabel
@onready var typing_sfx_player: AudioStreamPlayer2D = %TypingSfxPlayer

var game_menu_button_base_position: Vector2 = Vector2.ZERO
var game_menu_button_tween: Tween = null


func _ready() -> void:
	game_menu_button_base_position = game_menu_button.position

	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	game_menu_button.pressed.connect(_on_game_menu_button_pressed)
	game_menu_button.mouse_entered.connect(_on_game_menu_button_mouse_entered)
	game_menu_button.mouse_exited.connect(_on_game_menu_button_mouse_exited)

	input_field.text_changed.connect(_on_input_field_text_changed)
	input_field.text_submitted.connect(_on_input_field_text_submitted)

	input_field.editable = false
	feedback_label.visible = false

	show_start_wave_button("Start Wave")
	set_wave_text(1, 1)


func _on_start_wave_button_pressed() -> void:
	start_wave_pressed.emit()
	_focus_input()
	hide_start_wave_button()


func _on_game_menu_button_pressed() -> void:
	game_menu_pressed.emit()


func _on_game_menu_button_mouse_entered() -> void:
	_tween_game_menu_button(game_menu_button_base_position + GAME_MENU_HOVER_OFFSET)


func _on_game_menu_button_mouse_exited() -> void:
	_tween_game_menu_button(game_menu_button_base_position)


func _tween_game_menu_button(target_position: Vector2) -> void:
	if game_menu_button_tween != null:
		game_menu_button_tween.kill()

	game_menu_button_tween = create_tween()
	game_menu_button_tween.tween_property(
		game_menu_button,
		"position",
		target_position,
		GAME_MENU_TWEEN_DURATION
	)


func _on_input_field_text_changed(new_text: String) -> void:
	typing_sfx_player.play()
	text_changed.emit(new_text)


func _on_input_field_text_submitted(text: String) -> void:
	text_submitted.emit(text)


func set_wave_text(current_wave: int, total_waves: int) -> void:
	wave_label.text = "Wave %d / %d" % [current_wave, total_waves]


func set_base_hp(current_hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		base_hp_label.text = "%d" % current_hp
	else:
		base_hp_label.text = "%d / %d" % [current_hp, max_hp]


func set_status_text(text: String) -> void:
	status_label.text = text


func show_start_wave_button(button_text: String) -> void:
	start_wave_button.text = button_text
	start_wave_button.visible = true


func hide_start_wave_button() -> void:
	start_wave_button.visible = false


func set_input_enabled(is_enabled: bool) -> void:
	input_field.editable = is_enabled

	if is_enabled:
		_focus_input()
	else:
		input_field.release_focus()


func clear_input() -> void:
	input_field.clear()


func flash_input_error() -> void:
	feedback_label.text = "MISS"
	feedback_label.visible = true
	feedback_label.modulate = Color(1.0, 0.35, 0.35, 1.0)

	var tween: Tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.2)
	await tween.finished

	feedback_label.visible = false
	feedback_label.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _focus_input() -> void:
	if not input_field.editable:
		return

	input_field.grab_focus()
	input_field.caret_column = input_field.text.length()
