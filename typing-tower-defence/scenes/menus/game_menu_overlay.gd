extends CanvasLayer

signal resume_requested
signal back_to_menu_requested
signal word_lists_requested
signal settingsmenu_requested

enum MenuState {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING,
}

const BUTTON_HOVER_SCALE: Vector2 = Vector2(1.06, 1.06)
const BUTTON_NORMAL_SCALE: Vector2 = Vector2.ONE
const BUTTON_HOVER_TWEEN_DURATION: float = 0.08

const BUTTON_SHOW_START_SCALE: Vector2 = Vector2.ZERO
const BUTTON_SHOW_OVERSHOOT_SCALE: Vector2 = Vector2(1.14, 1.14)
const BUTTON_SHOW_TIME: float = 0.16
const BUTTON_SETTLE_TIME: float = 0.10
const BUTTON_HIDE_TIME: float = 0.12
const BUTTON_SEQUENCE_DELAY: float = 0.06

@onready var dimmer: Button = %Dimmer
@onready var panel: PanelContainer = %Panel
@onready var back_button: Button = %BackButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var wordlists_button: Button = %WordlistsButton
@onready var settings_button: Button = %SettingsButton
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var button_tweens: Dictionary = {}
var menu_buttons: Array[Button] = []

var menu_state: MenuState = MenuState.CLOSED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	menu_buttons = [
		main_menu_button,
		wordlists_button,
		settings_button,
	]

	if dimmer != null:
		dimmer.focus_mode = Control.FOCUS_NONE

		if not dimmer.pressed.is_connected(_on_dimmer_pressed):
			dimmer.pressed.connect(_on_dimmer_pressed)

	if back_button != null:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)

		_setup_button_hover(back_button)

	if main_menu_button != null:
		if not main_menu_button.pressed.is_connected(_on_main_menu_pressed):
			main_menu_button.pressed.connect(_on_main_menu_pressed)

		_setup_menu_button(main_menu_button)

	if wordlists_button != null:
		if not wordlists_button.pressed.is_connected(_on_wordlists_pressed):
			wordlists_button.pressed.connect(_on_wordlists_pressed)

		_setup_menu_button(wordlists_button)

	if settings_button != null:
		if not settings_button.pressed.is_connected(_on_settings_pressed):
			settings_button.pressed.connect(_on_settings_pressed)

		_setup_menu_button(settings_button)

	_set_menu_buttons_input_enabled(false)
	_reset_menu_buttons_hidden()


func show_overlay() -> void:
	if menu_state == MenuState.OPENING or menu_state == MenuState.OPEN:
		return

	menu_state = MenuState.OPENING
	visible = true

	_set_menu_buttons_input_enabled(false)
	_reset_menu_buttons_hidden()

	if animation_player != null and animation_player.has_animation("open_menu"):
		animation_player.play("open_menu")
	else:
		_on_open_menu_finished()


func hide_overlay() -> void:
	if menu_state == MenuState.CLOSING or menu_state == MenuState.CLOSED:
		return

	menu_state = MenuState.CLOSING
	_set_menu_buttons_input_enabled(false)

	if animation_player != null and animation_player.has_animation("close_menu"):
		animation_player.play("close_menu")
		await animation_player.animation_finished

	visible = false
	menu_state = MenuState.CLOSED


func toggle_overlay() -> void:
	if menu_state == MenuState.OPEN:
		_on_back_pressed()
	elif menu_state == MenuState.CLOSED:
		show_overlay()


# Call from the end of open_menu animation.
func enable_menu_buttons() -> void:
	_on_open_menu_finished()


func _on_open_menu_finished() -> void:
	if menu_state != MenuState.OPENING:
		return

	menu_state = MenuState.OPEN
	visible = true
	_set_menu_buttons_input_enabled(true)


# Call from open_menu animation.
func show_buttons() -> void:
	for button in menu_buttons:
		if button == null:
			continue

		_kill_button_tween(button)
		button.visible = true
		button.scale = BUTTON_SHOW_START_SCALE
		button.modulate.a = 0.0
		button.rotation = 0.0

	for button in menu_buttons:
		if button == null:
			continue

		_tween_button_show(button)
		await get_tree().create_timer(BUTTON_SEQUENCE_DELAY).timeout


# Call from close_menu animation.
func hide_buttons() -> void:
	_set_menu_buttons_input_enabled(false)

	for button in menu_buttons:
		if button == null:
			continue

		_tween_button_hide(button)
		await get_tree().create_timer(BUTTON_SEQUENCE_DELAY).timeout


func _setup_menu_button(button: Button) -> void:
	if button == null:
		return

	button.pivot_offset = button.size * 0.5
	button.scale = BUTTON_SHOW_START_SCALE
	button.modulate.a = 0.0
	button.rotation = 0.0

	_setup_button_hover(button)


func _reset_menu_buttons_hidden() -> void:
	for button in menu_buttons:
		if button == null:
			continue

		_kill_button_tween(button)
		button.visible = true
		button.scale = BUTTON_SHOW_START_SCALE
		button.modulate.a = 0.0
		button.rotation = 0.0


func _set_menu_buttons_input_enabled(enabled: bool) -> void:
	var mouse_filter_value := Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

	if dimmer != null:
		dimmer.mouse_filter = mouse_filter_value

	if back_button != null:
		back_button.mouse_filter = mouse_filter_value

	for button in menu_buttons:
		if button == null:
			continue

		button.mouse_filter = mouse_filter_value


func _tween_button_show(button: Button) -> void:
	_kill_button_tween(button)

	var tween: Tween = create_tween()

	tween.parallel().tween_property(
		button,
		"modulate:a",
		1.0,
		BUTTON_SHOW_TIME
	)

	tween.parallel().tween_property(
		button,
		"scale",
		BUTTON_SHOW_OVERSHOOT_SCALE,
		BUTTON_SHOW_TIME
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"scale",
		BUTTON_NORMAL_SCALE,
		BUTTON_SETTLE_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	button_tweens[button] = tween

	tween.finished.connect(func() -> void:
		if button_tweens.get(button, null) == tween:
			button_tweens.erase(button)
	)


func _tween_button_hide(button: Button) -> void:
	_kill_button_tween(button)

	var tween: Tween = create_tween()

	tween.parallel().tween_property(
		button,
		"modulate:a",
		0.0,
		BUTTON_HIDE_TIME
	)

	tween.parallel().tween_property(
		button,
		"scale",
		BUTTON_SHOW_START_SCALE,
		BUTTON_HIDE_TIME
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	button_tweens[button] = tween

	tween.finished.connect(func() -> void:
		if button_tweens.get(button, null) == tween:
			button_tweens.erase(button)
	)


func _kill_button_tween(button: Button) -> void:
	if button == null:
		return

	if not button_tweens.has(button):
		return

	var old_tween: Tween = button_tweens[button]

	if old_tween != null and old_tween.is_valid():
		old_tween.kill()

	button_tweens.erase(button)


func _on_dimmer_pressed() -> void:
	if menu_state != MenuState.OPEN:
		return

	_request_resume_after_close()


func _on_back_pressed() -> void:
	if menu_state != MenuState.OPEN:
		return

	_request_resume_after_close()


func _request_resume_after_close() -> void:
	if menu_state != MenuState.OPEN:
		return

	await hide_overlay()
	resume_requested.emit()


func _on_main_menu_pressed() -> void:
	if menu_state != MenuState.OPEN:
		return

	back_to_menu_requested.emit()


func _on_wordlists_pressed() -> void:
	if menu_state != MenuState.OPEN:
		return

	word_lists_requested.emit()


func _on_settings_pressed() -> void:
	if menu_state != MenuState.OPEN:
		return

	settingsmenu_requested.emit()


func _setup_button_hover(button: Button) -> void:
	if button == null:
		return

	button.pivot_offset = button.size * 0.5

	if not button.mouse_entered.is_connected(_on_button_mouse_entered.bind(button)):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))

	if not button.mouse_exited.is_connected(_on_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))


func _on_button_mouse_entered(button: Button) -> void:
	if menu_state != MenuState.OPEN:
		return

	_tween_button_scale(button, BUTTON_HOVER_SCALE)


func _on_button_mouse_exited(button: Button) -> void:
	if menu_state != MenuState.OPEN:
		return

	_tween_button_scale(button, BUTTON_NORMAL_SCALE)


func _tween_button_scale(button: Button, target_scale: Vector2) -> void:
	if button == null:
		return

	_kill_button_tween(button)

	var tween: Tween = create_tween()

	tween.tween_property(
		button,
		"scale",
		target_scale,
		BUTTON_HOVER_TWEEN_DURATION
	)

	button_tweens[button] = tween

	tween.finished.connect(func() -> void:
		if button_tweens.get(button, null) == tween:
			button_tweens.erase(button)
	)
