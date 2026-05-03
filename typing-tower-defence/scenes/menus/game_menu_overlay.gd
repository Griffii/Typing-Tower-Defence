extends CanvasLayer

signal resume_requested
signal back_to_menu_requested
signal word_lists_requested

@onready var back_button: Button = %BackButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var wordlists_button: Button = %WordlistsButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	if main_menu_button != null and not main_menu_button.pressed.is_connected(_on_main_menu_pressed):
		main_menu_button.pressed.connect(_on_main_menu_pressed)

	if wordlists_button != null and not wordlists_button.pressed.is_connected(_on_wordlists_pressed):
		wordlists_button.pressed.connect(_on_wordlists_pressed)


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
