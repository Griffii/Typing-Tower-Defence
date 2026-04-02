extends Control

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menus/main_menu.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")

@onready var screen_container: Control = $ScreenContainer
@onready var scene_transition: CanvasLayer = $SceneTransition

var current_screen: Control = null


func _ready() -> void:
	show_main_menu()


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


func show_main_menu() -> void:
	var menu: Control = set_screen(MAIN_MENU_SCENE)

	if menu.has_signal("play_requested"):
		menu.play_requested.connect(_on_play_requested)


func show_game_screen() -> void:
	var game: Control = set_screen(GAME_SCENE)

	if game.has_signal("back_to_menu_requested"):
		game.back_to_menu_requested.connect(_on_back_to_menu_requested)


func _on_play_requested() -> void:
	show_game_screen()


func _on_back_to_menu_requested() -> void:
	show_main_menu()
