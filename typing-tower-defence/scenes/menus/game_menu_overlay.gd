extends CanvasLayer

signal resume_requested
signal back_to_menu_requested
signal word_lists_requested

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

const MASTER_BUS_NAME: String = "Master"
const MUSIC_BUS_NAME: String = "Music"
const SFX_BUS_NAME: String = "SFX"
const TYPING_SFX_BUS_NAME: String = "TypingSFX"

@onready var dimmer: Button = %Dimmer
@onready var panel: PanelContainer = %Panel
@onready var back_button: Button = %BackButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var wordlists_button: Button = %WordlistsButton
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@onready var dev_mode_toggle_button: Button = get_node_or_null("%DevModeToggleButton") as Button

@onready var master_slider: Slider = get_node_or_null("%MasterVolumeSlider") as Slider
@onready var music_slider: Slider = get_node_or_null("%MusicVolumeSlider") as Slider
@onready var sfx_slider: Slider = get_node_or_null("%SfxVolumeSlider") as Slider
@onready var typing_sfx_slider: Slider = get_node_or_null("%TypingSfxVolumeSlider") as Slider

@onready var master_value_label: Label = get_node_or_null("%MasterVolumeValueLabel") as Label
@onready var music_value_label: Label = get_node_or_null("%MusicVolumeValueLabel") as Label
@onready var sfx_value_label: Label = get_node_or_null("%SfxVolumeValueLabel") as Label
@onready var typing_sfx_value_label: Label = get_node_or_null("%TypingSfxVolumeValueLabel") as Label

var button_tweens: Dictionary = {}
var menu_buttons: Array[Button] = []
var menu_state: MenuState = MenuState.CLOSED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	menu_buttons = [
		main_menu_button,
		wordlists_button,
	]

	if dev_mode_toggle_button != null:
		menu_buttons.append(dev_mode_toggle_button)

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

	if dev_mode_toggle_button != null:
		if not dev_mode_toggle_button.pressed.is_connected(_on_dev_mode_toggle_pressed):
			dev_mode_toggle_button.pressed.connect(_on_dev_mode_toggle_pressed)
		_setup_menu_button(dev_mode_toggle_button)

	if GameFlags != null and not GameFlags.dev_mode_changed.is_connected(_on_dev_mode_changed):
		GameFlags.dev_mode_changed.connect(_on_dev_mode_changed)

	_setup_audio_controls()
	_refresh_dev_mode_button()

	_set_menu_buttons_input_enabled(false)
	_reset_menu_buttons_hidden()


func _setup_audio_controls() -> void:
	_setup_volume_slider(master_slider, MASTER_BUS_NAME, master_value_label)
	_setup_volume_slider(music_slider, MUSIC_BUS_NAME, music_value_label)
	_setup_volume_slider(sfx_slider, SFX_BUS_NAME, sfx_value_label)
	_setup_volume_slider(typing_sfx_slider, TYPING_SFX_BUS_NAME, typing_sfx_value_label)


func _setup_volume_slider(slider: Slider, bus_name: String, value_label: Label) -> void:
	if slider == null:
		return

	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0

	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("GameMenuOverlay: Audio bus not found: " + bus_name)
		return

	var current_value: float = _get_bus_volume_percent(bus_index)
	slider.set_value_no_signal(current_value)
	_update_volume_label(value_label, current_value)

	if not slider.value_changed.is_connected(_on_volume_slider_changed.bind(bus_name, value_label)):
		slider.value_changed.connect(_on_volume_slider_changed.bind(bus_name, value_label))


func _on_volume_slider_changed(value: float, bus_name: String, value_label: Label) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	_set_bus_volume_percent(bus_index, value)
	_update_volume_label(value_label, value)


func _get_bus_volume_percent(bus_index: int) -> float:
	if AudioServer.is_bus_mute(bus_index):
		return 0.0

	var db: float = AudioServer.get_bus_volume_db(bus_index)
	var linear: float = db_to_linear(db)

	return clampf(linear * 100.0, 0.0, 100.0)


func _set_bus_volume_percent(bus_index: int, value: float) -> void:
	var clamped_value: float = clampf(value, 0.0, 100.0)

	if clamped_value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_value / 100.0))


func _update_volume_label(label: Label, value: float) -> void:
	if label == null:
		return

	label.text = str(roundi(value)) + "%"


func show_overlay() -> void:
	if menu_state == MenuState.OPENING or menu_state == MenuState.OPEN:
		return

	menu_state = MenuState.OPENING
	visible = true

	_set_menu_buttons_input_enabled(false)
	_reset_menu_buttons_hidden()
	_setup_audio_controls()
	_refresh_dev_mode_button()

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


func enable_menu_buttons() -> void:
	_on_open_menu_finished()


func _on_open_menu_finished() -> void:
	if menu_state != MenuState.OPENING:
		return

	menu_state = MenuState.OPEN
	visible = true
	_set_menu_buttons_input_enabled(true)


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

	var slider_mouse_filter := Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

	for slider in [master_slider, music_slider, sfx_slider, typing_sfx_slider]:
		if slider == null:
			continue

		slider.mouse_filter = slider_mouse_filter


func _tween_button_show(button: Button) -> void:
	_kill_button_tween(button)

	var tween: Tween = create_tween()

	tween.parallel().tween_property(button, "modulate:a", 1.0, BUTTON_SHOW_TIME)

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

	tween.parallel().tween_property(button, "modulate:a", 0.0, BUTTON_HIDE_TIME)

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


func _on_dev_mode_toggle_pressed() -> void:
	if GameFlags == null:
		return

	GameFlags.toggle_dev_mode()


func _on_dev_mode_changed(_is_enabled: bool) -> void:
	_refresh_dev_mode_button()


func _refresh_dev_mode_button() -> void:
	if dev_mode_toggle_button == null:
		return

	if GameFlags != null and GameFlags.is_dev_mode_enabled():
		dev_mode_toggle_button.text = "Dev Mode: ON"
	else:
		dev_mode_toggle_button.text = "Dev Mode: OFF"


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
	tween.tween_property(button, "scale", target_scale, BUTTON_HOVER_TWEEN_DURATION)

	button_tweens[button] = tween

	tween.finished.connect(func() -> void:
		if button_tweens.get(button, null) == tween:
			button_tweens.erase(button)
	)
