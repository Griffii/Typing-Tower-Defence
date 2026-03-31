extends Control

signal join_code_submitted(code: String)
signal leave_requested

@onready var title_label: Label = %TitleLabel
@onready var info_label: Label = %InfoLabel
@onready var lobby_code_label: Label = %LobbyCodeLabel
@onready var join_row: HBoxContainer = %JoinRow
@onready var code_input: LineEdit = %CodeInput
@onready var confirm_join_button: Button = %ConfirmJoinButton
@onready var leave_button: Button = %LeaveButton

var current_mode: String = "host"

func _ready() -> void:
	confirm_join_button.pressed.connect(_on_confirm_join_pressed)
	code_input.text_submitted.connect(_on_code_input_submitted)
	leave_button.pressed.connect(_on_leave_pressed)
	
	title_label.text = "Lobby"
	set_mode("host")


func set_mode(mode: String) -> void:
	current_mode = mode

	if current_mode == "host":
		info_label.text = "Waiting for a player to join..."
		lobby_code_label.visible = true
		join_row.visible = false
	elif current_mode == "join":
		info_label.text = "Enter the game code to join"
		lobby_code_label.visible = false
		join_row.visible = true
		code_input.editable = true
		call_deferred("_focus_code_input")
	else:
		info_label.text = ""
		lobby_code_label.visible = false
		join_row.visible = false


func set_lobby_code(code: String) -> void:
	if code.strip_edges().is_empty():
		lobby_code_label.text = "Code: ----"
	else:
		lobby_code_label.text = "Code: %s" % code
		lobby_code_label.visible = true


func set_status_text(text: String) -> void:
	info_label.text = text


func _on_confirm_join_pressed() -> void:
	_submit_code()


func _on_code_input_submitted(_text: String) -> void:
	_submit_code()


func _submit_code() -> void:
	if current_mode != "join":
		return
	
	var code: String = code_input.text.strip_edges().to_upper()
	if code.is_empty():
		info_label.text = "Enter the game code to join"
		return
	
	info_label.text = "Joining lobby..."
	join_code_submitted.emit(code)


func _on_leave_pressed() -> void:
	leave_requested.emit()


func _focus_code_input() -> void:
	if current_mode == "join":
		code_input.grab_focus()
