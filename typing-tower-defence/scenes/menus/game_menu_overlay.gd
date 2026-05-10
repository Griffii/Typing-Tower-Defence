extends CanvasLayer

signal resume_requested
signal back_to_menu_requested
signal word_lists_requested

const BUTTON_HOVER_SCALE: Vector2 = Vector2(1.06, 1.06)
const BUTTON_NORMAL_SCALE: Vector2 = Vector2.ONE
const BUTTON_HOVER_TWEEN_DURATION: float = 0.08

@onready var back_button: Button = %BackButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var wordlists_button: Button = %WordlistsButton

var button_tweens: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if back_button != null:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)

		_setup_button_hover(back_button)

	if main_menu_button != null:
		if not main_menu_button.pressed.is_connected(_on_main_menu_pressed):
			main_menu_button.pressed.connect(_on_main_menu_pressed)

		_setup_button_hover(main_menu_button)

	if wordlists_button != null:
		if not wordlists_button.pressed.is_connected(_on_wordlists_pressed):
			wordlists_button.pressed.connect(_on_wordlists_pressed)

		_setup_button_hover(wordlists_button)


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func toggle_overlay() -> void:
	if visible:
		_on_back_pressed()
	else:
		show_overlay()


func _on_back_pressed() -> void:
	resume_requested.emit()


func _on_main_menu_pressed() -> void:
	back_to_menu_requested.emit()


func _on_wordlists_pressed() -> void:
	word_lists_requested.emit()


func _setup_button_hover(button: Button) -> void:
	if button == null:
		return

	button.pivot_offset = button.size * 0.5

	if not button.mouse_entered.is_connected(_on_button_mouse_entered.bind(button)):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))

	if not button.mouse_exited.is_connected(_on_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))


func _on_button_mouse_entered(button: Button) -> void:
	_tween_button_scale(button, BUTTON_HOVER_SCALE)


func _on_button_mouse_exited(button: Button) -> void:
	_tween_button_scale(button, BUTTON_NORMAL_SCALE)


func _tween_button_scale(button: Button, target_scale: Vector2) -> void:
	if button == null:
		return

	if button_tweens.has(button):
		var old_tween: Tween = button_tweens[button]
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	var tween: Tween = create_tween()
	tween.tween_property(
		button,
		"scale",
		target_scale,
		BUTTON_HOVER_TWEEN_DURATION
	)

	button_tweens[button] = tween
