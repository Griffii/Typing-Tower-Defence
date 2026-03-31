extends Control

signal back_to_menu_requested
signal play_again_requested

const SoldierScene: PackedScene = preload("res://scenes/environment/soldier/soldier.tscn")
const GameOverScene: PackedScene = preload("res://scenes/game/game_over_screen.tscn")
const CountDownScene: PackedScene = preload("res://scenes/menus/round_countdown.tscn")

var game_over_overlay: Control = null
var countdown_overlay: Control = null

var match_start_time_ms: int = 0

var left_word_history: Array[String] = []
var right_word_history: Array[String] = []

var left_player_name: String = "Left Player"
var right_player_name: String = "Right Player"

var soldier_nodes: Dictionary = {}


@onready var left_word_label: Label = %LeftWordLabel
@onready var right_word_label: Label = %RightWordLabel
@onready var left_hp_label: Label = %LeftHpLabel
@onready var right_hp_label: Label = %RightHpLabel

@onready var word_to_type_label: Label = %WordToTypeLabel
@onready var type_input: LineEdit = %TypeInput

@onready var soldier_layer: Node = %SoldierLayer
@onready var left_spawn_marker: Marker2D = %LeftSpawnMarker
@onready var right_spawn_marker: Marker2D = %RightSpawnMarker

@onready var log_label: RichTextLabel = %LogLabel

var my_player_id: String = ""
var my_side: String = ""

var current_my_word_id: String = ""
var current_my_word_text: String = ""
var word_started_at_ms: int = 0

var opponent_left_session: bool = false
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

	countdown_overlay = CountDownScene.instantiate()
	add_child(countdown_overlay)

	if countdown_overlay.has_signal("countdown_finished"):
		countdown_overlay.countdown_finished.connect(_on_countdown_finished)


func set_local_player_info(player_id: String, side: String) -> void:
	my_player_id = player_id
	my_side = side
	_update_word_to_type_label()


func set_player_names(left_name: String, right_name: String) -> void:
	left_player_name = left_name
	right_player_name = right_name


func _set_pre_match_ui() -> void:
	left_word_label.text = ""
	right_word_label.text = ""
	left_word_label.visible = false
	right_word_label.visible = false

	left_castle_hp_visual = 100
	right_castle_hp_visual = 100
	left_hp_label.text = "HP: 100"
	right_hp_label.text = "HP: 100"

	type_input.text = ""
	type_input.editable = false
	word_to_type_label.text = "Waiting for match to begin."
	type_input.placeholder_text = ""

	opponent_left_session = false
	match_active = false
	game_over = false
	castle_hp_initialized = false
	match_start_time_ms = 0

	left_word_history.clear()
	right_word_history.clear()

	_clear_soldiers()

	if game_over_overlay != null and game_over_overlay.has_method("hide_overlay"):
		game_over_overlay.hide_overlay()


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

	left_castle_hp_visual = int(left.get("castleHp", left_castle_hp_visual))
	right_castle_hp_visual = int(right.get("castleHp", right_castle_hp_visual))
	left_hp_label.text = "HP: %d" % left_castle_hp_visual
	right_hp_label.text = "HP: %d" % right_castle_hp_visual
	castle_hp_initialized = true

	left_player_name = str(left.get("name", left_player_name))
	right_player_name = str(right.get("name", right_player_name))

	var left_word_raw: Variant = left.get("currentWord", {})
	var right_word_raw: Variant = right.get("currentWord", {})

	if typeof(left_word_raw) != TYPE_DICTIONARY or typeof(right_word_raw) != TYPE_DICTIONARY:
		return

	var left_word: Dictionary = left_word_raw as Dictionary
	var right_word: Dictionary = right_word_raw as Dictionary

	if my_side == "left":
		current_my_word_id = str(left_word.get("wordId", ""))
		current_my_word_text = str(left_word.get("text", ""))
	elif my_side == "right":
		current_my_word_id = str(right_word.get("wordId", ""))
		current_my_word_text = str(right_word.get("text", ""))

	_update_word_to_type_label()

	var soldiers_raw: Variant = state.get("soldiers", [])
	if typeof(soldiers_raw) == TYPE_ARRAY:
		_sync_soldiers_from_snapshot(soldiers_raw as Array)


func show_countdown() -> void:
	match_active = false
	type_input.editable = false
	type_input.placeholder_text = ""
	word_to_type_label.text = "Get ready..."
	left_word_label.visible = false
	right_word_label.visible = false

	if countdown_overlay != null and countdown_overlay.has_method("play_countdown"):
		countdown_overlay.play_countdown(3, 1.0)


func _on_countdown_finished() -> void:
	if game_over:
		return

	_update_word_to_type_label()
	type_input.editable = true
	type_input.grab_focus()
	match_active = true

	if match_start_time_ms <= 0:
		match_start_time_ms = Time.get_ticks_msec()


func start_match() -> void:
	if game_over:
		return

	if match_start_time_ms <= 0:
		match_start_time_ms = Time.get_ticks_msec()

	_update_word_to_type_label()
	type_input.editable = true
	type_input.grab_focus()
	match_active = true


func handle_word_rejected(msg: Dictionary) -> void:
	if game_over:
		return

	type_input.editable = true
	type_input.grab_focus()
	type_input.placeholder_text = "Try again"

	var rejected_state_raw: Variant = msg.get("state", {})
	if typeof(rejected_state_raw) == TYPE_DICTIONARY:
		apply_match_state(rejected_state_raw as Dictionary)

	_add_log("Word rejected: %s" % str(msg.get("reason", "Unknown")))


func handle_word_resolved(msg: Dictionary) -> void:
	if game_over:
		return

	var attacker_side: String = str(msg.get("attackerSide", ""))
	var typed_text: String = str(msg.get("typedText", ""))

	var resolved_state_raw: Variant = msg.get("state", {})
	if typeof(resolved_state_raw) == TYPE_DICTIONARY:
		apply_match_state(resolved_state_raw as Dictionary)

	_record_word_entry(attacker_side, typed_text)
	_play_castle_word_flash(attacker_side, typed_text)

	if attacker_side == my_side:
		type_input.editable = true
		type_input.grab_focus()
		type_input.placeholder_text = ""
		_update_word_to_type_label()

	_add_log("Resolved: %s sent 1 soldier." % attacker_side)


func handle_soldier_spawned(msg: Dictionary) -> void:
	var soldier_raw: Variant = msg.get("soldier", {})
	if typeof(soldier_raw) != TYPE_DICTIONARY:
		return

	var soldier_data: Dictionary = soldier_raw as Dictionary
	var soldier_id: String = str(soldier_data.get("id", ""))

	if soldier_id.is_empty():
		return

	if soldier_nodes.has(soldier_id):
		return

	var soldier_side: String = str(soldier_data.get("side", "left"))
	var spawn_marker: Marker2D = left_spawn_marker
	if soldier_side == "right":
		spawn_marker = right_spawn_marker

	var soldier: SoldierUnit = SoldierScene.instantiate() as SoldierUnit
	soldier_layer.add_child(soldier)
	soldier.setup(
		soldier_id,
		soldier_side,
		spawn_marker.position.x,
		spawn_marker.position.y
	)
	soldier.apply_server_state(soldier_data)

	soldier_nodes[soldier_id] = soldier


func handle_soldier_state(msg: Dictionary) -> void:
	var soldiers_raw: Variant = msg.get("soldiers", [])
	if typeof(soldiers_raw) == TYPE_ARRAY:
		_sync_soldiers_from_snapshot(soldiers_raw as Array)

	var castles_raw: Variant = msg.get("castles", {})
	if typeof(castles_raw) == TYPE_DICTIONARY:
		var castles: Dictionary = castles_raw as Dictionary

		var left_castle_raw: Variant = castles.get("left", {})
		var right_castle_raw: Variant = castles.get("right", {})

		if typeof(left_castle_raw) == TYPE_DICTIONARY:
			var left_castle: Dictionary = left_castle_raw as Dictionary
			left_castle_hp_visual = int(left_castle.get("hp", left_castle_hp_visual))
			left_hp_label.text = "HP: %d" % left_castle_hp_visual

		if typeof(right_castle_raw) == TYPE_DICTIONARY:
			var right_castle: Dictionary = right_castle_raw as Dictionary
			right_castle_hp_visual = int(right_castle.get("hp", right_castle_hp_visual))
			right_hp_label.text = "HP: %d" % right_castle_hp_visual


func handle_soldier_attack(msg: Dictionary) -> void:
	var attacker_id: String = str(msg.get("attackerId", ""))
	if attacker_id.is_empty():
		return

	if soldier_nodes.has(attacker_id):
		var soldier: SoldierUnit = soldier_nodes[attacker_id] as SoldierUnit
		if is_instance_valid(soldier):
			soldier.play_attack_animation()


func handle_soldier_damaged(msg: Dictionary) -> void:
	var soldier_id: String = str(msg.get("soldierId", ""))
	if soldier_id.is_empty():
		return

	if soldier_nodes.has(soldier_id):
		var soldier: SoldierUnit = soldier_nodes[soldier_id] as SoldierUnit
		if is_instance_valid(soldier):
			soldier.play_damage_flash()


func handle_soldier_died(msg: Dictionary) -> void:
	var soldier_id: String = str(msg.get("soldierId", ""))
	if soldier_id.is_empty():
		return

	if soldier_nodes.has(soldier_id):
		var soldier: SoldierUnit = soldier_nodes[soldier_id] as SoldierUnit
		soldier_nodes.erase(soldier_id)

		if is_instance_valid(soldier):
			soldier.play_death_and_remove()


func handle_castle_hp_updated(msg: Dictionary) -> void:
	var side: String = str(msg.get("side", ""))
	var hp: int = int(msg.get("hp", 0))

	if side == "left":
		left_castle_hp_visual = hp
		left_hp_label.text = "HP: %d" % left_castle_hp_visual
	elif side == "right":
		right_castle_hp_visual = hp
		right_hp_label.text = "HP: %d" % right_castle_hp_visual


func handle_match_ended(msg: Dictionary) -> void:
	if game_over:
		return

	match_active = false
	game_over = true
	type_input.editable = false
	type_input.release_focus()
	type_input.placeholder_text = ""

	var ended_state_raw: Variant = msg.get("state", {})
	if typeof(ended_state_raw) == TYPE_DICTIONARY:
		apply_match_state(ended_state_raw as Dictionary)

	var winner_id: String = str(msg.get("winnerPlayerId", ""))
	var did_win: bool = winner_id == my_player_id

	word_to_type_label.text = "Game over."
	_show_game_over_overlay(did_win)
	_add_log("Match ended.")



func set_status_text(text: String) -> void:
	_add_log(text)


func _on_type_submitted(submitted_text: String) -> void:
	if not match_active:
		return

	if game_over:
		return

	var typed: String = submitted_text.strip_edges().to_lower()
	if typed != current_my_word_text:
		type_input.placeholder_text = "Try again"
		type_input.text = ""
		_add_log("Incorrect word entered.")
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
	type_input.placeholder_text = ""


func _show_game_over_overlay(did_win: bool) -> void:
	if game_over_overlay == null:
		return

	var game_length_seconds: float = 0.0
	if match_start_time_ms > 0:
		game_length_seconds = float(Time.get_ticks_msec() - match_start_time_ms) / 1000.0

	var overlay_data: Dictionary = {
		"did_win": did_win,
		"game_length_seconds": game_length_seconds,
		"left_player": {
			"title": left_player_name,
			"entries": left_word_history,
		},
		"right_player": {
			"title": right_player_name,
			"entries": right_word_history,
		},
	}

	if game_over_overlay.has_method("show_results"):
		game_over_overlay.show_results(overlay_data)

	if opponent_left_session:
		if game_over_overlay.has_method("set_opponent_left"):
			game_over_overlay.set_opponent_left()


func _record_word_entry(attacker_side: String, word: String) -> void:
	var clean_word: String = word.strip_edges()
	if clean_word.is_empty():
		clean_word = "(unknown)"

	if attacker_side == "left":
		left_word_history.append(clean_word)
	else:
		right_word_history.append(clean_word)


func set_waiting_for_rematch(is_waiting: bool) -> void:
	if game_over_overlay != null and game_over_overlay.has_method("set_waiting_for_rematch"):
		game_over_overlay.set_waiting_for_rematch(is_waiting)


func set_opponent_left_session() -> void:
	opponent_left_session = true
	match_active = false
	type_input.editable = false

	if game_over_overlay != null and game_over_overlay.has_method("set_opponent_left"):
		game_over_overlay.set_opponent_left()


func set_both_players_ready() -> void:
	if game_over_overlay != null and game_over_overlay.has_method("set_both_players_ready"):
		game_over_overlay.set_both_players_ready()


func reset_for_rematch() -> void:
	_set_pre_match_ui()


func _on_game_over_back_to_menu_requested() -> void:
	back_to_menu_requested.emit()


func _on_game_over_play_again_requested() -> void:
	if game_over_overlay != null and game_over_overlay.has_method("set_waiting_for_rematch"):
		game_over_overlay.set_waiting_for_rematch(true)
	play_again_requested.emit()


func _update_word_to_type_label() -> void:
	if game_over:
		return

	if current_my_word_text.strip_edges().is_empty():
		word_to_type_label.text = "Waiting for word..."
	else:
		word_to_type_label.text = current_my_word_text


func _play_castle_word_flash(attacker_side: String, word: String) -> void:
	var target_label: Label = left_word_label
	if attacker_side == "right":
		target_label = right_word_label
	
	target_label.text = word
	target_label.visible = true
	
	var base_position: Vector2 = target_label.position
	target_label.modulate.a = 1.0
	target_label.position = base_position + Vector2(0.0, 8.0)
	
	var tween: Tween = create_tween()
	tween.parallel().tween_property(target_label, "modulate:a", 0.0, 0.8)
	tween.parallel().tween_property(target_label, "position", base_position + Vector2(0.0, -10.0), 0.8)
	await tween.finished
	
	target_label.visible = false
	target_label.text = ""
	target_label.modulate.a = 1.0
	target_label.position = base_position


func _sync_soldiers_from_snapshot(soldiers: Array) -> void:
	var seen_ids: Dictionary = {}

	for soldier_raw in soldiers:
		if typeof(soldier_raw) != TYPE_DICTIONARY:
			continue

		var soldier_data: Dictionary = soldier_raw as Dictionary
		var soldier_id: String = str(soldier_data.get("id", ""))
		if soldier_id.is_empty():
			continue

		seen_ids[soldier_id] = true

		if not soldier_nodes.has(soldier_id):
			handle_soldier_spawned({
				"soldier": soldier_data
			})

		if soldier_nodes.has(soldier_id):
			var soldier: SoldierUnit = soldier_nodes[soldier_id] as SoldierUnit
			if is_instance_valid(soldier):
				soldier.apply_server_state(soldier_data)

	var existing_ids: Array = soldier_nodes.keys().duplicate()
	for existing_id in existing_ids:
		if not seen_ids.has(existing_id):
			var old_soldier: SoldierUnit = soldier_nodes[existing_id] as SoldierUnit
			if is_instance_valid(old_soldier):
				old_soldier.play_death_and_remove()
			soldier_nodes.erase(existing_id)


func _clear_soldiers() -> void:
	for soldier_id in soldier_nodes.keys():
		var soldier: SoldierUnit = soldier_nodes[soldier_id] as SoldierUnit
		if is_instance_valid(soldier):
			soldier.queue_free()

	soldier_nodes.clear()

	for child: Node in soldier_layer.get_children():
		if child is SoldierUnit:
			child.queue_free()


func _add_log(text: String) -> void:
	if log_label != null:
		log_label.append_text("%s\n" % text)
