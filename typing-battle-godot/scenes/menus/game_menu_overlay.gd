extends CanvasLayer

signal resume_requested
signal back_to_menu_requested

@onready var back_button: Button = %BackButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	visible = false

	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

	if main_menu_button != null:
		main_menu_button.pressed.connect(_on_main_menu_pressed)


# --- Public API ---

func show_overlay() -> void:
	visible = true
	get_tree().paused = true

	# Ensure UI still works while paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func hide_overlay() -> void:
	visible = false
	get_tree().paused = false


func toggle_overlay() -> void:
	if visible:
		hide_overlay()
	else:
		show_overlay()


# --- Button handlers ---

func _on_back_pressed() -> void:
	hide_overlay()
	resume_requested.emit()


func _on_main_menu_pressed() -> void:
	back_to_menu_requested.emit()
