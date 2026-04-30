extends Control

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menus/main_menu.tscn")
const ENDLESS_SETUP_SCENE: PackedScene = preload("res://scenes/menus/endless_setup_screen.tscn")
const LEVEL_SELECT_SCENE: PackedScene = preload("res://scenes/menus/level_select.tscn")
const WORD_LISTS_SCENE: PackedScene = preload("res://scenes/menus/word_list_menu.tscn")
const CHARACTER_CUSTOMIZE_SCENE: PackedScene = preload("res://scenes/menus/character_customization_menu.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")

@onready var screen_container: Control = %ScreenContainer
@onready var scene_transition: CanvasLayer = %Scene_Transition

var current_screen: Control = null
var is_transitioning: bool = false


func _ready() -> void:
	_set_main_menu()


func clear_current_screen() -> void:
	if current_screen != null and is_instance_valid(current_screen):
		current_screen.queue_free()
		current_screen = null


func set_screen(scene: PackedScene) -> Control:
	clear_current_screen()

	var instance: Control = scene.instantiate() as Control
	screen_container.add_child(instance)
	current_screen = instance
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


func _set_and_wire_screen(scene: PackedScene) -> void:
	if scene == MAIN_MENU_SCENE:
		_set_main_menu()
	elif scene == ENDLESS_SETUP_SCENE:
		_set_endless_setup_menu()
	elif scene == LEVEL_SELECT_SCENE:
		_set_level_select()
	elif scene == WORD_LISTS_SCENE:
		_set_wordlists_menu()
	elif scene == CHARACTER_CUSTOMIZE_SCENE:
		_set_character_customize_menu()
	elif scene == GAME_SCENE:
		_set_game_screen()
	else:
		set_screen(scene)


func _set_main_menu() -> void:
	var menu: Control = set_screen(MAIN_MENU_SCENE)

	if menu.has_signal("play_requested"):
		menu.play_requested.connect(_on_play_requested)

	if menu.has_signal("endless_mode_requested"):
		menu.endless_mode_requested.connect(_on_endless_mode_requested)

	if menu.has_signal("wordlistsmenu_requested"):
		menu.wordlistsmenu_requested.connect(_on_word_lists_menu_requested)
	
	if menu.has_signal("customizecharactermenu_requested"):
		menu.customizecharactermenu_requested.connect(_on_customize_menu_requested)


func _set_endless_setup_menu() -> void:
	var menu: Control = set_screen(ENDLESS_SETUP_SCENE)

	if menu.has_signal("back_requested"):
		menu.back_requested.connect(_on_back_to_menu_requested)

	if menu.has_signal("start_requested"):
		menu.start_requested.connect(_on_selection_finished)


func _set_wordlists_menu() -> void:
	var menu: Control = set_screen(WORD_LISTS_SCENE)

	if menu.has_signal("back_requested"):
		menu.back_requested.connect(_on_back_to_menu_requested)


func _set_level_select() -> void:
	var level_select: Control = set_screen(LEVEL_SELECT_SCENE)

	if level_select.has_signal("selection_finished"):
		level_select.selection_finished.connect(_on_selection_finished)

	if level_select.has_signal("back_requested"):
		level_select.back_requested.connect(_on_back_to_menu_requested)


func _set_character_customize_menu() -> void:
	var menu: Control = set_screen(CHARACTER_CUSTOMIZE_SCENE)
	
	if menu.has_signal("back_requested"):
		menu.back_requested.connect(_on_back_to_menu_requested)



func _set_game_screen() -> void:
	var game: Control = set_screen(GAME_SCENE)

	if game.has_signal("back_to_menu_requested"):
		game.back_to_menu_requested.connect(_on_back_to_menu_requested)


func _on_play_requested() -> void:
	transition_to_screen(LEVEL_SELECT_SCENE, "black_swipe_LtoR")


func _on_endless_mode_requested() -> void:
	transition_to_screen(ENDLESS_SETUP_SCENE, "black_swipe_LtoR")


func _on_selection_finished() -> void:
	transition_to_screen(GAME_SCENE, "black_swipe_LtoR")


func _on_word_lists_menu_requested() -> void:
	transition_to_screen(WORD_LISTS_SCENE, "black_swipe_LtoR")


func _on_customize_menu_requested() -> void:
	transition_to_screen(CHARACTER_CUSTOMIZE_SCENE, "black_swipe_LtoR")


func _on_back_to_menu_requested() -> void:
	get_tree().paused = false

	if GameSession != null and GameSession.has_method("setup_legacy"):
		GameSession.setup_legacy()

	if GameSelection != null and GameSelection.has_method("reset_to_defaults"):
		GameSelection.reset_to_defaults()

	transition_to_screen(MAIN_MENU_SCENE, "black_swipe_RtoL")
