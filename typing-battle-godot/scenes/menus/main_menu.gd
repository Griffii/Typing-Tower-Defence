extends Control

signal play_requested
signal settings_requested

@onready var play_button: Button = %PlayButton
@onready var multiplayer_button: Button = %MultiplayerButton
@onready var settings_button: Button = %SettingsButton
@onready var title_label: RichTextLabel = %TitleLabel


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	multiplayer_button.disabled = true
	multiplayer_button.focus_mode = Control.FOCUS_NONE

	title_label.bbcode_enabled = true
	title_label.scroll_active = false
	title_label.fit_content = true

	var wave_effect := WaveTextEffect.new()
	title_label.install_effect(wave_effect)

	title_label.text = "[center][wave height=8 speed=2.2 spacing=0.45]Super Fun & Cool Typing Battle Game![/wave][/center]"


func _on_play_pressed() -> void:
	play_requested.emit()


func _on_settings_pressed() -> void:
	settings_requested.emit()
