extends CanvasLayer

signal back_to_menu_requested
signal play_again_requested

@onready var title_label: Label = %TitleLabel
@onready var result_label: Label = %ResultLabel
@onready var summary_label: Label = %SummaryLabel

@onready var back_to_menu_button: Button = %BackToMenuButton
@onready var play_again_button: Button = %PlayAgainButton

@onready var fanfare_sfx: AudioStreamPlayer = %FanfareSfx
@onready var fail_sfx: AudioStreamPlayer = %FailSfx


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)

	title_label.text = "Game Over"
	result_label.text = ""
	summary_label.text = ""
	visible = false


func show_results(data: Dictionary) -> void:
	visible = true

	var did_win: bool = bool(data.get("did_win", false))
	var wave_reached: int = int(data.get("wave_reached", 0))
	var total_waves: int = int(data.get("total_waves", 0))

	if did_win:
		result_label.text = "Victory!"
		if fanfare_sfx != null:
			fanfare_sfx.play()
	else:
		result_label.text = "Defeat"
		if fail_sfx != null:
			fail_sfx.play()

	summary_label.text = "Wave Reached: %d / %d" % [wave_reached, total_waves]
	play_again_button.disabled = false


func hide_overlay() -> void:
	visible = false
	play_again_button.disabled = false
	result_label.text = ""
	summary_label.text = ""


func _on_back_to_menu_pressed() -> void:
	back_to_menu_requested.emit()


func _on_play_again_pressed() -> void:
	play_again_requested.emit()
