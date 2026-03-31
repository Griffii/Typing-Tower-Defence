extends Control

signal local_game_over(winner_side: String, winner_player_id: String)

const SoldierScene: PackedScene = preload("res://scenes/environment/soldier.tscn")
const GameOverScene: PackedScene = preload("res://scenes/game/game_over_screen.tscn")

var game_over_overlay: Control = null
var match_start_time_ms: int = 0
var left_word_history: Array = []
var right_word_history: Array = []
var left_soldiers_sent: int = 0
var right_soldiers_sent: int = 0
var left_soldiers_died: int = 0
var right_soldiers_died: int = 0

@onready var countdown_label: Label = %CountdownLabel
@onready var ping_label: Label = %PingLabel

@onready var left_word_label: Label = %LeftWordLabel
@onready var right_word_label: Label = %RightWordLabel
@onready var left_hp_label: Label = %LeftHpLabel
@onready var right_hp_label: Label = %RightHpLabel

@onready var input_info_label: Label = %InputInfoLabel
@onready var type_input: LineEdit = %TypeInput
@onready var soldier_layer: Control = %SoldierLayer
@onready var log_label: RichTextLabel = %LogLabel

var my_player_id: String = ""
var my_side: String = ""

var current_my_word_id: String = ""
var current_my_word_text: String = ""
var word_started_at_ms: int = 0

var match_active: bool = false
var game_over: bool = false
var castle_hp_initialized: bool = false

var left_castle_hp_visual: int = 100
var right_castle_hp_visual: int = 100

func _ready() -> void:
	type_input.text_submitted.connect(_on_type_submitted)
	_set_pre_match_ui()
	
	game_over_overlay = GameOverScene.instantiate()
	add_child(game_over_overlay)
	game_over_overlay.back_to_menu_requested.connect(_on_game_over_back_to_menu_requested)
	game_over_overlay.play_again_requested.connect(_on_game_over_play_again_requested)


func set_local_player_info(player_id: String, side: String) -> void:
	my_player_id = player_id
	my_side = side


func _set_pre_match_ui() -> void:
	countdown_label.text = "Waiting for match"
	left_word_label.text = "-"
	right_word_label.text = "-"
	left_castle_hp_visual = 100
	right_castle_hp_visual = 100
	left_hp_label.text = "HP: 100"
	right_hp_label.text = "HP: 100"
	type_input.text = ""
	type_input.editable = false
	input_info_label.text = "Waiting for match to begin."
	match_active = false
	game_over = false
	castle_hp_initialized = false
	_clear_soldiers()


func apply_match_state(state: Dictionary) -> void:
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
	
	# Only initialize castle HP from server once.
	# Current prototype keeps real combat/castle damage on the client side.
	if not castle_hp_initialized:
		left_castle_hp_visual = int(left.get("castleHp", 100))
		right_castle_hp_visual = int(right.get("castleHp", 100))
		left_hp_label.text = "HP: %d" % left_castle_hp_visual
		right_hp_label.text = "HP: %d" % right_castle_hp_visual
		castle_hp_initialized = true
	
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


func show_countdown() -> void:
	countdown_label.text = "Match starting..."
	input_info_label.text = "Get ready."
	type_input.editable = false
	match_active = false


func start_match() -> void:
	if game_over:
		return
	
	countdown_label.text = "GO"
	input_info_label.text = "Type your word and press Enter."
	type_input.editable = true
	type_input.grab_focus()
	match_active = true


func handle_word_rejected(msg: Dictionary) -> void:
	if game_over:
		return
	
	type_input.editable = true
	type_input.grab_focus()
	input_info_label.text = "Rejected: %s" % String(msg.get("reason", "Unknown"))
	
	var rejected_state_raw: Variant = msg.get("state", {})
	if typeof(rejected_state_raw) == TYPE_DICTIONARY:
		apply_match_state(rejected_state_raw as Dictionary)
	
	_add_log("Word rejected.")


func handle_word_resolved(msg: Dictionary) -> void:
	if game_over:
		return
	
	var attacker_side: String = String(msg.get("attackerSide", ""))
	
	var resolved_state_raw: Variant = msg.get("state", {})
	if typeof(resolved_state_raw) == TYPE_DICTIONARY:
		apply_match_state(resolved_state_raw as Dictionary)
	
	_spawn_soldier(attacker_side)
	
	if attacker_side == my_side:
		type_input.editable = true
		type_input.grab_focus()
		input_info_label.text = "Attack sent. Type the next word."
	
	_add_log("Resolved: %s sent 1 soldier." % attacker_side)


func handle_match_ended(msg: Dictionary) -> void:
	match_active = false
	game_over = true
	type_input.editable = false
	
	var winner_id: String = String(msg.get("winnerPlayerId", ""))
	if winner_id == my_player_id:
		countdown_label.text = "YOU WIN"
	else:
		countdown_label.text = "YOU LOSE"
	
	input_info_label.text = "Game over."
	_clear_soldiers()
	_add_log("Match ended.")


func set_ping_text(text: String) -> void:
	ping_label.text = text


func set_status_text(text: String) -> void:
	input_info_label.text = text


func _on_type_submitted(submitted_text: String) -> void:
	if not match_active:
		return
	
	if game_over:
		return
	
	var typed: String = submitted_text.strip_edges().to_lower()
	if typed != current_my_word_text:
		input_info_label.text = "Incorrect. Try again."
		return
	
	var now_ms: int = Time.get_ticks_msec()
	var duration_ms: int = max(1, now_ms - word_started_at_ms)
	
	NetworkManager.send_json({
		"type": "submit_word",
		"wordId": current_my_word_id,
		"text": typed,
		"typedDurationMs": duration_ms
	})
	
	type_input.text = ""
	type_input.editable = false
	input_info_label.text = "Submitted..."


func _spawn_soldier(attacker_side: String) -> void:
	if game_over:
		return
	
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
	
	var soldier: SoldierUnit = SoldierScene.instantiate() as SoldierUnit
	soldier_layer.add_child(soldier)
	
	soldier.start_position = Vector2(start_x, y)
	soldier.end_position = Vector2(end_x, y)
	soldier.castle_hit_callback = Callable(self, "_on_castle_hit")
	soldier.castle_alive_callback = Callable(self, "_is_enemy_castle_alive")
	soldier.setup(attacker_side)


func _on_castle_hit(attacker_side: String, amount: int) -> void:
	if game_over:
		return
	
	if attacker_side == "left":
		right_castle_hp_visual = max(0, right_castle_hp_visual - amount)
		right_hp_label.text = "HP: %d" % right_castle_hp_visual
	
		if right_castle_hp_visual <= 0:
			_handle_local_game_over("left")
	else:
		left_castle_hp_visual = max(0, left_castle_hp_visual - amount)
		left_hp_label.text = "HP: %d" % left_castle_hp_visual
	
		if left_castle_hp_visual <= 0:
			_handle_local_game_over("right")


func _is_enemy_castle_alive(attacker_side: String) -> bool:
	if attacker_side == "left":
		return right_castle_hp_visual > 0
	return left_castle_hp_visual > 0


func _handle_local_game_over(winner_side: String) -> void:
	if game_over:
		return
	
	game_over = true
	match_active = false
	type_input.editable = false
	type_input.release_focus()
	_clear_soldiers()
	
	if winner_side == my_side:
		countdown_label.text = "YOU WIN"
		input_info_label.text = "Enemy castle destroyed."
	else:
		countdown_label.text = "YOU LOSE"
		input_info_label.text = "Your castle was destroyed."
	
	var winner_player_id: String = ""
	if winner_side == "left":
		winner_player_id = "left"
	else:
		winner_player_id = "right"
	
	local_game_over.emit(winner_side, winner_player_id)
	_add_log("Local game over. Winner side: %s" % winner_side)


func _clear_soldiers() -> void:
	for child: Node in soldier_layer.get_children():
		child.queue_free()


func _add_log(text: String) -> void:
	log_label.append_text("%s\n" % text)
