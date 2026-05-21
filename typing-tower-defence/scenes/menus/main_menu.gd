extends Control

signal play_requested
signal levelselectmenu_requested
signal endless_mode_requested
signal training_room_requested
signal settingsmenu_requested
signal wordlistsmenu_requested
signal customizecharactermenu_requested
signal main_menu_closed

const TITLE_TEXT: String = "Leximancer"
const BUTTON_ANIMATE_DELAY: float = 0.07

@onready var story_button: MainMenuButton = %StoryButton
@onready var tutorial_button: MainMenuButton = %TutorialButton
@onready var endless_button: MainMenuButton = %EndlessButton
@onready var word_lists_button: MainMenuButton = %WordListsButton
@onready var character_button: MainMenuButton = %CharacterButton
@onready var settings_button: MainMenuButton = %SettingsButton


@onready var animation_player: AnimationPlayer = %AnimationPlayer

var menu_buttons: Array[MainMenuButton] = []
var is_closing: bool = false
var is_animating_buttons: bool = false


func _ready() -> void:
	visible = true

	menu_buttons = [
		story_button,
		tutorial_button,
		endless_button,
		word_lists_button,
		character_button,
		settings_button,
	]

	_setup_menu_button(story_button, _on_story_mode_pressed)
	_setup_menu_button(tutorial_button, _on_training_room_pressed)
	_setup_menu_button(endless_button, _on_endless_mode_pressed)
	_setup_menu_button(word_lists_button, _on_wordlists_pressed)
	_setup_menu_button(character_button, _on_customize_pressed)
	_setup_menu_button(settings_button, _on_settings_pressed)

	_snap_buttons_hidden_left()

	if animation_player != null and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

	call_deferred("_open_menu_after_layout")


func _open_menu_after_layout() -> void:
	await get_tree().process_frame
	open_menu()


func open_menu() -> void:
	is_closing = false
	visible = true

	if animation_player != null and animation_player.has_animation("open_main_menu"):
		animation_player.play("open_main_menu")
	else:
		_animate_buttons_in()


func close_menu() -> void:
	if is_closing:
		return

	is_closing = true

	await _animate_buttons_out()

	if animation_player != null and animation_player.has_animation("close_main_menu"):
		animation_player.play("close_main_menu")
		await animation_player.animation_finished

	visible = false
	is_closing = false
	main_menu_closed.emit()



func _setup_menu_button(button: MainMenuButton, pressed_callable: Callable) -> void:
	if button == null:
		return

	if not button.pressed.is_connected(pressed_callable):
		button.pressed.connect(pressed_callable)


func _snap_buttons_hidden_left() -> void:
	for button in menu_buttons:
		if button == null:
			continue

		button.snap_in_hidden_left()


func _set_all_buttons_interactable(enabled: bool) -> void:
	for button in menu_buttons:
		if button == null:
			continue

		button.set_interactable(enabled)


func _animate_buttons_in() -> void:
	if is_animating_buttons:
		return

	is_animating_buttons = true
	_set_all_buttons_interactable(false)

	var last_button: MainMenuButton = null

	for button in menu_buttons:
		if button == null:
			continue

		button.animate_in_button()
		last_button = button

		await get_tree().create_timer(BUTTON_ANIMATE_DELAY).timeout

	if last_button != null:
		await last_button.button_animation_finished

	_set_all_buttons_interactable(true)
	is_animating_buttons = false


func _animate_buttons_out() -> void:
	if is_animating_buttons:
		return

	is_animating_buttons = true
	_set_all_buttons_interactable(false)

	var last_button: MainMenuButton = null

	for i in range(menu_buttons.size() - 1, -1, -1):
		var button: MainMenuButton = menu_buttons[i]

		if button == null:
			continue

		button.animate_out_button()
		last_button = button

		await get_tree().create_timer(BUTTON_ANIMATE_DELAY).timeout

	if last_button != null:
		await last_button.button_animation_finished

	is_animating_buttons = false


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "open_main_menu":
		_animate_buttons_in()


func _on_play_pressed() -> void:
	play_requested.emit()


func _on_story_mode_pressed() -> void:
	levelselectmenu_requested.emit()


func _on_endless_mode_pressed() -> void:
	endless_mode_requested.emit()


func _on_training_room_pressed() -> void:
	training_room_requested.emit()


func _on_settings_pressed() -> void:
	settingsmenu_requested.emit()


func _on_wordlists_pressed() -> void:
	wordlistsmenu_requested.emit()


func _on_customize_pressed() -> void:
	customizecharactermenu_requested.emit()
