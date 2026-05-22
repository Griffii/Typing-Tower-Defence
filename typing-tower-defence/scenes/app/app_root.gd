extends Control

const MAIN_MENU_SCENE: PackedScene = preload("uid://dlouqnp58v4nl")
const ENDLESS_SETUP_SCENE: PackedScene = preload("uid://dk55vhpecvo3w")
const LEVEL_SELECT_SCENE: PackedScene = preload("uid://0xlvdjakqgnq")
const CHARACTER_CUSTOMIZE_SCENE: PackedScene = preload("uid://defo7xtrxfi6s")
const ENDLESS_GAME_SCENE: PackedScene = preload("uid://160u44o703f8")
const CAMPAIGN_GAME_SCENE: PackedScene = preload("uid://ds243ews64l1a")
const TRAINING_ROOM_GAME_SCENE: PackedScene = preload("uid://dly0hhr52vbhj")

const WORD_LISTS_SCENE: PackedScene = preload("uid://b3dwhhkipwc5c")
const SETTINGS_MENU_SCENE: PackedScene = preload("uid://gx0317qb6t87")

@onready var screen_container: Control = %ScreenContainer
@onready var scene_transition: CanvasLayer = %Scene_Transition
@onready var modal_container: Control = %ModalContainer

var current_modal: CanvasLayer = null
var current_screen: Control = null
var is_transitioning: bool = false

var screen_container_base_position: Vector2 = Vector2.ZERO
var screen_shake_tween: Tween = null


func _ready() -> void:
	screen_container_base_position = screen_container.position

	if ScreenEffects != null and not ScreenEffects.screen_shake_requested.is_connected(_on_screen_shake_requested):
		ScreenEffects.screen_shake_requested.connect(_on_screen_shake_requested)

	_set_main_menu()


func _on_screen_shake_requested(intensity: float = 8.0, duration: float = 0.18) -> void:
	shake_screen_container(intensity, duration)


func shake_screen_container(intensity: float = 8.0, duration: float = 0.18) -> void:
	if screen_container == null:
		return

	if screen_shake_tween != null and screen_shake_tween.is_valid():
		screen_shake_tween.kill()

	screen_container.position = screen_container_base_position

	var step_time: float = 0.025
	var elapsed: float = 0.0

	screen_shake_tween = create_tween()

	while elapsed < duration:
		var progress: float = elapsed / max(duration, 0.001)
		var current_intensity: float = lerpf(intensity, 0.0, progress)

		var offset := Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)

		screen_shake_tween.tween_property(
			screen_container,
			"position",
			screen_container_base_position + offset,
			step_time
		)

		elapsed += step_time

	screen_shake_tween.tween_property(
		screen_container,
		"position",
		screen_container_base_position,
		step_time
	)


func clear_current_screen() -> void:
	if current_screen != null and is_instance_valid(current_screen):
		current_screen.queue_free()
		current_screen = null


func set_screen(scene: PackedScene) -> Control:
	clear_current_screen()

	var instance: Control = scene.instantiate() as Control
	screen_container.add_child(instance)
	current_screen = instance
	
	_apply_scene_bgm(instance)
	
	return instance


func transition_to_screen(scene: PackedScene, transition_name: String = "black_swipe") -> void:
	if is_transitioning:
		return

	is_transitioning = true

	if scene_transition == null or transition_name.is_empty():
		_set_and_wire_screen(scene)
		is_transitioning = false
		return

	scene_transition.play_transition(transition_name)

	await scene_transition.transition_midpoint_reached

	_set_and_wire_screen(scene)

	await scene_transition.transition_finished

	is_transitioning = false


func transition_to_current_game_screen(transition_name: String = "black_swipe_LtoR") -> void:
	match GameSession.run_mode:
		GameSession.RunMode.ENDLESS:
			transition_to_screen(ENDLESS_GAME_SCENE, transition_name)

		GameSession.RunMode.CAMPAIGN:
			transition_to_screen(CAMPAIGN_GAME_SCENE, transition_name)

		_:
			push_warning("AppRoot: No valid run mode selected. Falling back to endless game screen.")
			transition_to_screen(ENDLESS_GAME_SCENE, transition_name)


func _set_and_wire_screen(scene: PackedScene) -> void:
	if scene == MAIN_MENU_SCENE:
		_set_main_menu()
	elif scene == ENDLESS_SETUP_SCENE:
		_set_endless_setup_menu()
	elif scene == LEVEL_SELECT_SCENE:
		_set_level_select()
	elif scene == CHARACTER_CUSTOMIZE_SCENE:
		_set_character_customize_menu()
	elif scene == ENDLESS_GAME_SCENE:
		_set_endless_game_screen()
	elif scene == CAMPAIGN_GAME_SCENE:
		_set_campaign_game_screen()
	elif scene == TRAINING_ROOM_GAME_SCENE:
		_set_training_room_game_screen()
	else:
		set_screen(scene)


func _set_main_menu() -> void:
	var menu: Control = set_screen(MAIN_MENU_SCENE)

	if menu.has_signal("levelselectmenu_requested"):
		menu.levelselectmenu_requested.connect(_on_level_select_menu_requested)

	if menu.has_signal("endless_mode_requested"):
		menu.endless_mode_requested.connect(_on_endless_mode_requested)

	if menu.has_signal("wordlistsmenu_requested"):
		menu.wordlistsmenu_requested.connect(_on_word_lists_menu_requested)

	if menu.has_signal("settingsmenu_requested"):
		menu.settingsmenu_requested.connect(_on_settings_menu_requested)

	if menu.has_signal("customizecharactermenu_requested"):
		menu.customizecharactermenu_requested.connect(_on_customize_menu_requested)

	if menu.has_signal("training_room_requested"):
		menu.training_room_requested.connect(_on_training_room_requested)


func _set_endless_setup_menu() -> void:
	var menu: Control = set_screen(ENDLESS_SETUP_SCENE)

	if menu.has_signal("back_requested"):
		menu.back_requested.connect(_on_back_to_menu_requested)

	if menu.has_signal("start_requested"):
		menu.start_requested.connect(_on_selection_finished)

	if menu.has_signal("settingsmenu_requested"):
		menu.settingsmenu_requested.connect(_on_settings_menu_requested)


func _set_wordlists_menu() -> void:
	var menu: CanvasLayer = show_modal(WORD_LISTS_SCENE)

	if menu == null:
		return

	if menu.has_signal("back_requested"):
		menu.back_requested.connect(_on_word_lists_modal_closed)


func _set_settings_menu() -> void:
	var menu: CanvasLayer = show_modal(SETTINGS_MENU_SCENE)

	if menu == null:
		return

	if menu.has_signal("close_requested"):
		menu.close_requested.connect(_on_settings_modal_closed)

	if menu.has_signal("back_requested"):
		menu.back_requested.connect(_on_settings_modal_closed)


func _set_level_select() -> void:
	var level_select: Control = set_screen(LEVEL_SELECT_SCENE)

	if level_select.has_signal("selection_finished"):
		level_select.selection_finished.connect(_on_selection_finished)

	if level_select.has_signal("back_requested"):
		level_select.back_requested.connect(_on_back_to_menu_requested)

	if level_select.has_signal("settingsmenu_requested"):
		level_select.settingsmenu_requested.connect(_on_settings_menu_requested)


func _set_character_customize_menu() -> void:
	var menu: Control = set_screen(CHARACTER_CUSTOMIZE_SCENE)

	if menu.has_signal("back_requested"):
		menu.back_requested.connect(_on_back_to_menu_requested)

	if menu.has_signal("settingsmenu_requested"):
		menu.settingsmenu_requested.connect(_on_settings_menu_requested)


func _set_endless_game_screen() -> void:
	var game: Control = set_screen(ENDLESS_GAME_SCENE)

	if game.has_signal("back_to_menu_requested"):
		game.back_to_menu_requested.connect(_on_back_to_menu_requested)

	if game.has_signal("word_lists_requested"):
		game.word_lists_requested.connect(_on_word_lists_menu_requested)

	if game.has_signal("settingsmenu_requested"):
		game.settingsmenu_requested.connect(_on_settings_menu_requested)


func _set_campaign_game_screen() -> void:
	var game: Control = set_screen(CAMPAIGN_GAME_SCENE)

	if game.has_signal("back_to_menu_requested"):
		game.back_to_menu_requested.connect(_on_back_to_menu_requested)

	if game.has_signal("return_to_map_requested"):
		game.return_to_map_requested.connect(_on_return_to_map_requested)

	if game.has_signal("word_lists_requested"):
		game.word_lists_requested.connect(_on_word_lists_menu_requested)

	if game.has_signal("settingsmenu_requested"):
		game.settingsmenu_requested.connect(_on_settings_menu_requested)


func _set_training_room_game_screen() -> void:
	var game: Control = set_screen(TRAINING_ROOM_GAME_SCENE)

	if game.has_signal("back_to_menu_requested"):
		game.back_to_menu_requested.connect(_on_back_to_menu_requested)

	if game.has_signal("word_lists_requested"):
		game.word_lists_requested.connect(_on_word_lists_menu_requested)

	if game.has_signal("settingsmenu_requested"):
		game.settingsmenu_requested.connect(_on_settings_menu_requested)


func _on_return_to_map_requested() -> void:
	get_tree().paused = false
	transition_to_screen(LEVEL_SELECT_SCENE, "black_swipe_RtoL")


func _on_level_select_menu_requested() -> void:
	transition_to_screen(LEVEL_SELECT_SCENE, "black_swipe_LtoR")


func _on_endless_mode_requested() -> void:
	transition_to_screen(ENDLESS_SETUP_SCENE, "black_swipe_LtoR")


func _on_training_room_requested() -> void:
	get_tree().paused = false

	if GameSession != null and GameSession.has_method("setup_legacy"):
		GameSession.setup_legacy()

	transition_to_screen(TRAINING_ROOM_GAME_SCENE, "black_swipe_LtoR")


func _on_selection_finished() -> void:
	transition_to_current_game_screen("black_swipe_LtoR")


func _on_word_lists_menu_requested() -> void:
	_set_wordlists_menu()


func _on_word_lists_modal_closed() -> void:
	close_current_modal_immediate()


func _on_settings_menu_requested() -> void:
	_set_settings_menu()


func _on_settings_modal_closed() -> void:
	close_current_modal_immediate()


func _on_customize_menu_requested() -> void:
	transition_to_screen(CHARACTER_CUSTOMIZE_SCENE, "black_swipe_LtoR")


func _on_back_to_menu_requested() -> void:
	get_tree().paused = false

	if GameSession != null and GameSession.has_method("setup_legacy"):
		GameSession.setup_legacy()

	if GameSelection != null and GameSelection.has_method("reset_to_defaults"):
		GameSelection.reset_to_defaults()

	transition_to_screen(MAIN_MENU_SCENE, "black_swipe_RtoL")


func show_modal(scene: PackedScene) -> CanvasLayer:
	close_current_modal_immediate()

	var instance: CanvasLayer = scene.instantiate() as CanvasLayer

	if instance == null:
		push_warning("AppRoot: Modal scene is not a CanvasLayer.")
		return null

	add_child(instance)
	current_modal = instance

	return instance


func close_current_modal_immediate() -> void:
	if current_modal != null and is_instance_valid(current_modal):
		current_modal.queue_free()

	current_modal = null


func _apply_scene_bgm(scene_root: Node) -> void:
	if scene_root == null:
		return

	var scene_bgm: AudioStreamPlayer = scene_root.find_child("Scene_BGM", true, false) as AudioStreamPlayer

	if scene_bgm == null:
		return

	if AudioManager == null:
		push_warning("AppRoot: AudioManager not found.")
		return

	if scene_bgm.stream == null:
		if AudioManager.has_method("stop_music"):
			AudioManager.stop_music()
		return

	if AudioManager.has_method("play_music"):
		AudioManager.play_music(
			scene_bgm.stream,
			1.0,
			scene_bgm.volume_db
		)
