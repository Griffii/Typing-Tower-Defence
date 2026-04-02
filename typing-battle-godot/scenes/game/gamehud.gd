extends CanvasLayer

signal start_wave_pressed
signal game_menu_pressed
signal text_submitted(text: String)
signal text_changed(text: String)

@onready var wave_label: Label = %WaveLabel
@onready var timer_label: Label = %TimerLabel
@onready var points_label: Label = %PointsLabel
@onready var status_label: Label = %StatusLabel

@onready var start_wave_button: Button = %StartWaveButton
@onready var game_menu_button: Button = %GameMenuButton

@onready var input_field: LineEdit = %InputField
@onready var progress_bar: ProgressBar = %ProgressBar

@onready var base_hp_label: Label = %BaseHpLabel
@onready var gold_label: Label = %GoldLabel

@onready var feedback_label: Label = %FeedbackLabel
@onready var typing_sfx_player: AudioStreamPlayer2D = %TypingSfxPlayer



func _ready() -> void:
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	game_menu_button.pressed.connect(_on_game_menu_button_pressed)

	input_field.text_changed.connect(_on_input_field_text_changed)
	input_field.text_submitted.connect(_on_input_field_text_submitted)

	input_field.editable = false
	feedback_label.visible = false
	timer_label.visible = false

	show_start_wave_button("Start Wave")
	set_wave_text(1, 1)



func _on_start_wave_button_pressed() -> void:
	start_wave_pressed.emit()
	_focus_input()


func _on_game_menu_button_pressed() -> void:
	game_menu_pressed.emit()


func _on_input_field_text_changed(new_text: String) -> void:
	typing_sfx_player.play()
	text_changed.emit(new_text)


func _on_input_field_text_submitted(text: String) -> void:
	text_submitted.emit(text)


func set_wave_text(current_wave: int, total_waves: int) -> void:
	wave_label.text = "Wave %d / %d" % [current_wave, total_waves]


func set_score(score: int) -> void:
	points_label.text = "Points: %d" % score


func set_gold(gold: int) -> void:
	gold_label.text = "Gold: %d" % gold


func set_base_hp(current_hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		base_hp_label.text = "Base HP: %d" % current_hp
	else:
		base_hp_label.text = "Base HP: %d / %d" % [current_hp, max_hp]


func set_arrow_meter(current_value: float, max_value: float) -> void:
	progress_bar.max_value = max(0.001, max_value)
	progress_bar.value = clampf(current_value, 0.0, progress_bar.max_value)


func set_status_text(text: String) -> void:
	status_label.text = text


func set_timer_text(text: String) -> void:
	timer_label.text = text
	timer_label.visible = not text.is_empty()


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
