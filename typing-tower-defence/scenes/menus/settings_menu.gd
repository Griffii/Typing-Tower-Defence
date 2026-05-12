extends CanvasLayer

signal close_requested

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var close_button: Button = %BackButton
@onready var dev_mode_toggle_button: Button = %DevModeToggleButton

var is_closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if close_button != null and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)

	if dev_mode_toggle_button != null and not dev_mode_toggle_button.pressed.is_connected(_on_dev_mode_toggle_pressed):
		dev_mode_toggle_button.pressed.connect(_on_dev_mode_toggle_pressed)

	if GameFlags != null and not GameFlags.dev_mode_changed.is_connected(_on_dev_mode_changed):
		GameFlags.dev_mode_changed.connect(_on_dev_mode_changed)

	_refresh_dev_mode_button()
	play_open_animation()


func play_open_animation() -> void:
	if animation_player == null:
		return

	if animation_player.has_animation("open_menu"):
		animation_player.play("open_menu")


func request_close() -> void:
	if is_closing:
		return

	is_closing = true

	if animation_player != null and animation_player.has_animation("close_menu"):
		animation_player.play("close_menu")
		await animation_player.animation_finished

	close_requested.emit()


func _refresh_dev_mode_button() -> void:
	if dev_mode_toggle_button == null:
		return

	if GameFlags != null and GameFlags.is_dev_mode_enabled():
		dev_mode_toggle_button.text = "Dev Mode: ON"
	else:
		dev_mode_toggle_button.text = "Dev Mode: OFF"


func _on_dev_mode_toggle_pressed() -> void:
	if GameFlags == null:
		return

	GameFlags.toggle_dev_mode()


func _on_dev_mode_changed(_is_enabled: bool) -> void:
	_refresh_dev_mode_button()


func _on_close_button_pressed() -> void:
	request_close()
