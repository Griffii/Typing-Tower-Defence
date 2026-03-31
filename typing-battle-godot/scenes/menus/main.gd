extends Control

const SoldierScene = preload("res://scenes/environment/soldier.tscn")

@onready var network := NetworkManager

@onready var status_label: Label = %StatusLabel
@onready var ping_label: Label = %PingLabel

@onready var create_button: Button = %CreateButton
@onready var join_button: Button = %JoinButton
@onready var code_input: LineEdit = %CodeInput
@onready var lobby_code_label: Label = %LobbyCodeLabel
@onready var lobby_info_label: Label = %LobbyInfoLabel

@onready var countdown_label: Label = %CountdownLabel
@onready var left_word_label: Label = %LeftWordLabel
@onready var right_word_label: Label = %RightWordLabel
@onready var left_hp_label: Label = %LeftHpLabel
@onready var right_hp_label: Label = %RightHpLabel
@onready var type_input: LineEdit = %TypeInput
@onready var input_info_label: Label = %InputInfoLabel
@onready var soldier_layer: Control = %SoldierLayer
@onready var log_label: RichTextLabel = %LogLabel

var my_player_id: String = ""
var my_side: String = ""
var current_my_word_id: String = ""
var current_my_word_text: String = ""
var word_started_at_ms: int = 0
var match_active: bool = false

func _ready() -> void:
	create_button.pressed.connect(_on_create_pressed)
	join_button.pressed.connect(_on_join_pressed)
	type_input.text_submitted.connect(_on_type_submitted)
	
	network.connected_to_server.connect(_on_socket_connected)
	network.disconnected_from_server.connect(_on_socket_disconnected)
	network.message_received.connect(_on_server_message)
	
	_set_pre_match_ui()
	await get_tree().process_frame
	network.connect_to_server("ws://localhost:8080")


func _set_pre_match_ui() -> void:
	countdown_label.text = "Not in match"
	left_word_label.text = "-"
	right_word_label.text = "-"
	left_hp_label.text = "HP: 100"
	right_hp_label.text = "HP: 100"
	type_input.editable = false
	type_input.text = ""
	input_info_label.text = "Create or join a lobby first."
	match_active = false


func _on_socket_connected() -> void:
	status_label.text = "Connected"


func _on_socket_disconnected() -> void:
	status_label.text = "Disconnected"
	match_active = false
	type_input.editable = false
	_add_log("Disconnected from server.")


func _on_create_pressed() -> void:
	network.send_json({
		"type": "create_lobby"
	})


func _on_join_pressed() -> void:
	var code: String = code_input.text.strip_edges().to_upper()
	if code.is_empty():
		_add_log("Join code is empty.")
		return
	
	network.send_json({
		"type": "join_lobby",
		"code": code
	})


func _on_type_submitted(submitted_text: String) -> void:
	if not match_active:
		return
	
	var typed: String = submitted_text.strip_edges().to_lower()
	if typed != current_my_word_text:
		input_info_label.text = "Incorrect. Try again."
		return
	
	var now_ms: int = Time.get_ticks_msec()
	var duration_ms: int = max(1, now_ms - word_started_at_ms)
	
	network.send_json({
		"type": "submit_word",
		"wordId": current_my_word_id,
		"text": typed,
		"typedDurationMs": duration_ms
	})
	
	type_input.text = ""
	type_input.editable = false
	input_info_label.text = "Submitted..."


func _on_server_message(msg: Dictionary) -> void:
	var msg_type: String = String(msg.get("type", ""))
	
	match msg_type:
		"connected":
			my_player_id = String(msg.get("playerId", ""))
			_add_log("Connected as %s" % my_player_id)
	
		"lobby_created":
			my_side = String(msg.get("side", ""))
			lobby_code_label.text = "Code: %s" % String(msg.get("code", ""))
			lobby_info_label.text = "Waiting for second player..."
			_add_log("Lobby created.")
	
		"lobby_joined":
			my_side = String(msg.get("side", ""))
			lobby_code_label.text = "Joined code: %s" % String(msg.get("code", ""))
			lobby_info_label.text = "Joined lobby."
			_add_log("Joined lobby.")
	
		"lobby_ready":
			lobby_info_label.text = "Two players connected."
			_add_log("Lobby ready.")
	
		"match_countdown":
			var countdown_state_raw: Variant = msg.get("state", {})
			if typeof(countdown_state_raw) == TYPE_DICTIONARY:
				_apply_state(countdown_state_raw as Dictionary)
			countdown_label.text = "Match starting..."
			input_info_label.text = "Get ready."
			_add_log("Countdown started.")
	
		"match_started":
			var started_state_raw: Variant = msg.get("state", {})
			if typeof(started_state_raw) == TYPE_DICTIONARY:
				_apply_state(started_state_raw as Dictionary)
			countdown_label.text = "GO"
			input_info_label.text = "Type your word and press Enter."
			match_active = true
			type_input.editable = true
			type_input.grab_focus()
			_add_log("Match started.")
	
		"word_rejected":
			type_input.editable = true
			type_input.grab_focus()
			input_info_label.text = "Rejected: %s" % String(msg.get("reason", "Unknown"))
			if msg.has("state"):
				var rejected_state_raw: Variant = msg.get("state", {})
				if typeof(rejected_state_raw) == TYPE_DICTIONARY:
					_apply_state(rejected_state_raw as Dictionary)
			_add_log("Word rejected.")
	
		"word_resolved":
			var attacker_side: String = String(msg.get("attackerSide", ""))
			var damage: int = int(msg.get("damage", 0))
			
			var resolved_state_raw: Variant = msg.get("state", {})
			if typeof(resolved_state_raw) == TYPE_DICTIONARY:
				_apply_state(resolved_state_raw as Dictionary)
			
			_spawn_soldiers(attacker_side, 1)
			
			if attacker_side == my_side:
				type_input.editable = true
				type_input.grab_focus()
				input_info_label.text = "Hit for %d damage. Type the next word." % damage
			
			_add_log("Resolved: %s sent 1 soldiers." % [attacker_side])
	
		"match_ended":
			var ended_state_raw: Variant = msg.get("state", {})
			if typeof(ended_state_raw) == TYPE_DICTIONARY:
				_apply_state(ended_state_raw as Dictionary)
			match_active = false
			type_input.editable = false
	
			var winner_id: String = String(msg.get("winnerPlayerId", ""))
			if winner_id == my_player_id:
				countdown_label.text = "YOU WIN"
			else:
				countdown_label.text = "YOU LOSE"
	
			_add_log("Match ended.")
	
		"pong":
			var server_time: int = int(msg.get("serverTime", 0))
			ping_label.text = "Server: %d" % server_time
	
		"error":
			_add_log("Server error: %s" % String(msg.get("message", "Unknown error")))
	
		_:
			_add_log("Unhandled message: %s" % msg_type)


func _apply_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	
	var players_raw: Variant = state.get("players", {})
	if typeof(players_raw) != TYPE_DICTIONARY:
		return
	var players: Dictionary = players_raw as Dictionary
	
	var left_raw: Variant = players.get("left", {})
	var right_raw: Variant = players.get("right", {})
	
	if typeof(left_raw) != TYPE_DICTIONARY or typeof(right_raw) != TYPE_DICTIONARY:
		return
	
	var left: Dictionary = left_raw as Dictionary
	var right: Dictionary = right_raw as Dictionary
	
	left_hp_label.text = "HP: %d" % int(left.get("castleHp", 100))
	right_hp_label.text = "HP: %d" % int(right.get("castleHp", 100))
	
	var left_word_raw: Variant = left.get("currentWord", {})
	var right_word_raw: Variant = right.get("currentWord", {})

	if typeof(left_word_raw) != TYPE_DICTIONARY or typeof(right_word_raw) != TYPE_DICTIONARY:
		return
	
	var left_word: Dictionary = left_word_raw as Dictionary
	var right_word: Dictionary = right_word_raw as Dictionary
	
	left_word_label.text = String(left_word.get("text", "-"))
	right_word_label.text = String(right_word.get("text", "-"))
	
	if my_side == "left":
		current_my_word_id = String(left_word.get("wordId", ""))
		current_my_word_text = String(left_word.get("text", ""))
	elif my_side == "right":
		current_my_word_id = String(right_word.get("wordId", ""))
		current_my_word_text = String(right_word.get("text", ""))
	
	if not current_my_word_id.is_empty():
		word_started_at_ms = Time.get_ticks_msec()


func _spawn_soldiers(attacker_side: String, count: int) -> void:
	var lane_size: Vector2 = soldier_layer.size
	var start_x: float
	var end_x: float
	var y: float = lane_size.y * 0.5
	
	if attacker_side == "left":
		start_x = 40.0
		end_x = max(60.0, lane_size.x - 40.0)
	else:
		start_x = max(60.0, lane_size.x - 40.0)
		end_x = 40.0
	
	for i: int in range(count):
		var soldier: SoldierUnit = SoldierScene.instantiate() as SoldierUnit
		soldier_layer.add_child(soldier)
	
		soldier.start_position = Vector2(start_x, y)
		soldier.end_position = Vector2(end_x, y)
		soldier.castle_hit_callback = Callable(self, "_on_castle_hit")
		soldier.castle_alive_callback = Callable(self, "_is_enemy_castle_alive")
		soldier.setup(attacker_side)


func _add_log(text: String) -> void:
	log_label.append_text("%s\n" % text)
