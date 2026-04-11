extends Control

signal join_code_submitted(code: String, player_name: String)
signal leave_requested
signal player_name_changed(player_name: String)
signal ready_pressed(is_ready: bool)

@onready var title_label: Label = %TitleLabel
@onready var info_label: Label = %InfoLabel
@onready var leave_button: Button = %LeaveButton

@onready var setup_container: Control = %SetUpContainer
@onready var lobby_code_label: Label = %LobbyCodeLabel
@onready var copy_code_button: TextureButton = %CopyCodeButton
@onready var join_row: HBoxContainer = %JoinRow
@onready var code_input: LineEdit = %CodeInput
@onready var confirm_join_button: Button = %ConfirmJoinButton

@onready var ready_room_container: Control = %ReadyRoomContainer
@onready var left_player_label: Label = %LeftPlayerLabel
@onready var right_player_label: Label = %RightPlayerLabel
@onready var name_input: LineEdit = %NameInput
@onready var confirm_name_button: Button = %ConfirmNameButton
@onready var ready_up_button: Button = %ReadyUpButton

var current_mode: String = "host"
var current_phase: String = "waiting"
var local_ready: bool = false
var current_lobby_code: String = ""
var local_name_initialized: bool = false

func _ready() -> void:
	confirm_join_button.pressed.connect(_on_confirm_join_pressed)
	code_input.text_submitted.connect(_on_code_input_submitted)
	leave_button.pressed.connect(_on_leave_pressed)

	copy_code_button.pressed.connect(_on_copy_code_pressed)

	name_input.text_submitted.connect(_on_name_input_submitted)
	name_input.text_changed.connect(_on_name_input_changed)
	confirm_name_button.pressed.connect(_on_confirm_name_pressed)
	ready_up_button.pressed.connect(_on_ready_up_pressed)

	left_player_label.text = "Left Player"
	right_player_label.text = "Right Player"

	name_input.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_input.text_direction = Control.TEXT_DIRECTION_LTR

	_ensure_leave_button_active()
	set_mode("host")
	set_phase("waiting")
	_update_buttons()


func set_mode(mode: String) -> void:
	current_mode = mode

	if current_mode == "host":
		info_label.text = "Waiting for a player to join..."
		lobby_code_label.visible = true
		copy_code_button.visible = true
		join_row.visible = false
	elif current_mode == "join":
		info_label.text = "Enter the game code to join"
		lobby_code_label.visible = false
		copy_code_button.visible = false
		join_row.visible = true
		code_input.editable = true
		call_deferred("_focus_code_input")
	else:
		info_label.text = ""
		lobby_code_label.visible = false
		copy_code_button.visible = false
		join_row.visible = false

	_ensure_leave_button_active()


func set_phase(phase: String) -> void:
	current_phase = phase

	if current_phase == "waiting":
		setup_container.visible = true
		ready_room_container.visible = false

		if current_mode == "join":
			call_deferred("_focus_code_input")
	elif current_phase == "ready_room":
		setup_container.visible = false
		ready_room_container.visible = true
		call_deferred("_focus_name_input")
	else:
		setup_container.visible = true
		ready_room_container.visible = false

	_ensure_leave_button_active()
	_update_buttons()


func set_lobby_code(code: String) -> void:
	current_lobby_code = code.strip_edges().to_upper()

	if current_lobby_code.is_empty():
		lobby_code_label.text = "Code: ----"
	else:
		lobby_code_label.text = "Code: %s" % current_lobby_code
		lobby_code_label.visible = true

	_ensure_leave_button_active()


func set_status_text(text: String) -> void:
	info_label.text = text
	_ensure_leave_button_active()


func set_player_labels(left_name: String, right_name: String) -> void:
	left_player_label.text = _fallback_name(left_name, "Left Player")
	right_player_label.text = _fallback_name(right_name, "Right Player")
	_ensure_leave_button_active()


func set_local_name(name: String) -> void:
	if local_name_initialized:
		return

	name_input.text = name.strip_edges()
	local_name_initialized = true
	local_ready = false
	_ensure_leave_button_active()
	_update_buttons()


func get_player_name() -> String:
	return name_input.text.strip_edges()


func set_local_ready(is_ready: bool) -> void:
	local_ready = is_ready
	_ensure_leave_button_active()
	_update_buttons()


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
		_ensure_leave_button_active()
		return

	info_label.text = "Joining lobby..."
	_ensure_leave_button_active()
	join_code_submitted.emit(code, "")


func _on_leave_pressed() -> void:
	leave_requested.emit()


func _on_copy_code_pressed() -> void:
	if current_lobby_code.is_empty():
		return

	DisplayServer.clipboard_set(current_lobby_code)
	info_label.text = "Code copied to clipboard."
	_ensure_leave_button_active()


func _focus_code_input() -> void:
	if current_mode == "join" and current_phase == "waiting":
		code_input.grab_focus()


func _focus_name_input() -> void:
	if current_phase == "ready_room":
		name_input.grab_focus()


func _on_name_input_changed(_new_text: String) -> void:
	local_ready = false
	_ensure_leave_button_active()
	_update_buttons()


func _on_name_input_submitted(_text: String) -> void:
	_confirm_name_only()


func _on_confirm_name_pressed() -> void:
	_confirm_name_only()


func _confirm_name_only() -> void:
	var player_name: String = get_player_name()
	if player_name.is_empty():
		_ensure_leave_button_active()
		_update_buttons()
		return

	local_ready = false
	player_name_changed.emit(player_name)
	info_label.text = "Name updated."
	_ensure_leave_button_active()
	_update_buttons()


func _on_ready_up_pressed() -> void:
	var player_name: String = get_player_name()
	if player_name.is_empty():
		_ensure_leave_button_active()
		_update_buttons()
		return

	local_ready = not local_ready
	player_name_changed.emit(player_name)
	ready_pressed.emit(local_ready)

	if local_ready:
		info_label.text = "Ready!"
	else:
		info_label.text = "Not ready."

	_ensure_leave_button_active()
	_update_buttons()


func _update_buttons() -> void:
	var has_name: bool = not get_player_name().is_empty()

	if current_phase == "ready_room":
		confirm_name_button.disabled = not has_name
		ready_up_button.disabled = not has_name

		if local_ready:
			ready_up_button.text = "Unready"
		else:
			ready_up_button.text = "Ready"
	else:
		confirm_name_button.disabled = true
		ready_up_button.disabled = true
		ready_up_button.text = "Ready"

	_ensure_leave_button_active()


func _ensure_leave_button_active() -> void:
	if leave_button == null:
		return

	leave_button.disabled = false
	leave_button.visible = true
	leave_button.mouse_filter = Control.MOUSE_FILTER_STOP


func _fallback_name(value: String, fallback: String) -> String:
	var trimmed: String = value.strip_edges()
	if trimmed.is_empty():
		return fallback
	return trimmed
