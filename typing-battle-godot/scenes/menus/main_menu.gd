extends Control

signal solo_requested
signal create_requested
signal join_requested

@onready var solo_button: Button = %SoloButton
@onready var create_button: Button = %CreateButton
@onready var join_button: Button = %JoinButton

func _ready() -> void:
	solo_button.pressed.connect(_on_solo_pressed)
	create_button.pressed.connect(_on_create_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	# Disabled for now as requested
	solo_button.disabled = true


func _on_solo_pressed() -> void:
	solo_requested.emit()


func _on_create_pressed() -> void:
	create_requested.emit()


func _on_join_pressed() -> void:
	join_requested.emit()
