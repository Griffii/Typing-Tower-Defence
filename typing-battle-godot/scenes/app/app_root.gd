extends Control

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menus/main_menu.tscn")
const LOBBY_SCENE: PackedScene = preload("res://scenes/menus/lobby_screen.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/game/game_screen.tscn")

@onready var screen_container: Control = $ScreenContainer
@onready var network: Node = NetworkManager

var current_screen: Control = null

var my_player_id: String = ""
var my_side: String = ""
var current_lobby_code: String = ""
var current_lobby_mode: String = ""
var current_match_state: Dictionary = {}

var local_player_name: String = "Player"
var left_player_name: String = "Left Player"
var right_player_name: String = "Right Player"

func _ready() -> void:
	network.connected_to_server.connect(_on_socket_connected)
	network.disconnected_from_server.connect(_on_socket_disconnected)
	network.message_received.connect(_on_server_message)
	network.connection_failed.connect(_on_connection_failed)
	
	_show_main_menu()
	
	await get_tree().process_frame
	network.connect_to_server()


func _clear_current_screen() -> void:
	if current_screen != null and is_instance_valid(current_screen):
		current_screen.queue_free()
		current_screen = null


func _set_screen(scene: PackedScene) -> Control:
	_clear_current_screen()

	var instance: Control = scene.instantiate() as Control
	screen_container.add_child(instance)
	current_screen = instance
	return instance


func _show_main_menu() -> void:
	var menu: Control = _set_screen(MAIN_MENU_SCENE)

	if menu.has_signal("create_requested"):
		menu.create_requested.connect(_on_main_menu_create_requested)

	if menu.has_signal("join_requested"):
		menu.join_requested.connect(_on_main_menu_join_requested)


func _show_lobby_host() -> void:
	current_lobby_mode = "host"

	var lobby: Control = _set_screen(LOBBY_SCENE)

	if lobby.has_method("set_mode"):
		lobby.set_mode("host")

	if lobby.has_method("set_status_text"):
		lobby.set_status_text("Creating lobby...")

	if lobby.has_signal("join_code_submitted"):
		lobby.join_code_submitted.connect(_on_lobby_join_code_submitted)

	if lobby.has_signal("leave_requested"):
		lobby.leave_requested.connect(_on_lobby_leave_requested)

	if lobby.has_signal("player_name_changed"):
		lobby.player_name_changed.connect(_on_lobby_player_name_changed)

	if lobby.has_signal("ready_pressed"):
		lobby.ready_pressed.connect(_on_lobby_ready_pressed)


func _show_lobby_join() -> void:
	current_lobby_mode = "join"

	var lobby: Control = _set_screen(LOBBY_SCENE)

	if lobby.has_method("set_mode"):
		lobby.set_mode("join")

	if lobby.has_method("set_status_text"):
		lobby.set_status_text("Enter the game code to join")

	if lobby.has_signal("join_code_submitted"):
		lobby.join_code_submitted.connect(_on_lobby_join_code_submitted)

	if lobby.has_signal("leave_requested"):
		lobby.leave_requested.connect(_on_lobby_leave_requested)

	if lobby.has_signal("player_name_changed"):
		lobby.player_name_changed.connect(_on_lobby_player_name_changed)

	if lobby.has_signal("ready_pressed"):
		lobby.ready_pressed.connect(_on_lobby_ready_pressed)


func _show_game_screen() -> void:
	var game: Control = _set_screen(GAME_SCENE)

	if game.has_method("set_local_player_info"):
		game.set_local_player_info(my_player_id, my_side)

	if game.has_method("set_player_names"):
		game.set_player_names(left_player_name, right_player_name)

	if game.has_signal("local_game_over"):
		game.local_game_over.connect(_on_local_game_over)

	if game.has_signal("back_to_menu_requested"):
		game.back_to_menu_requested.connect(_on_game_back_to_menu_requested)

	if game.has_signal("play_again_requested"):
		game.play_again_requested.connect(_on_game_play_again_requested)

	if not current_match_state.is_empty() and game.has_method("apply_match_state"):
		game.apply_match_state(current_match_state)


func _on_main_menu_create_requested() -> void:
	_show_lobby_host()
	network.send_json({
		"type": "create_lobby",
		"playerName": local_player_name
	})


func _on_main_menu_join_requested() -> void:
	_show_lobby_join()


func _on_lobby_join_code_submitted(code: String, player_name: String) -> void:
	var normalized_name: String = player_name.strip_edges()
	if not normalized_name.is_empty():
		local_player_name = normalized_name

	var normalized_code: String = code.strip_edges().to_upper()
	if normalized_code.is_empty():
		return

	current_lobby_code = normalized_code

	network.send_json({
		"type": "join_lobby",
		"code": normalized_code,
		"playerName": local_player_name
	})

	if current_screen != null and current_screen.has_method("set_status_text"):
		current_screen.set_status_text("Joining lobby...")


func _on_lobby_leave_requested() -> void:
	if current_lobby_code != "":
		network.send_json({
			"type": "leave_lobby"
		})

	current_lobby_code = ""
	current_lobby_mode = ""
	current_match_state.clear()
	_show_main_menu()


func _on_lobby_player_name_changed(player_name: String) -> void:
	var normalized_name: String = player_name.strip_edges()
	local_player_name = normalized_name

	network.send_json({
		"type": "update_lobby_name",
		"playerName": local_player_name
	})


func _on_lobby_ready_pressed(is_ready: bool) -> void:
	network.send_json({
		"type": "set_lobby_ready",
		"isReady": is_ready
	})


func _on_socket_connected() -> void:
	pass


func _on_socket_disconnected() -> void:
	current_lobby_code = ""
	current_lobby_mode = ""
	current_match_state.clear()
	_show_main_menu()


func _on_connection_failed() -> void:
	print("Connection failed")

func _on_server_message(msg: Dictionary) -> void:
	var msg_type: String = String(msg.get("type", ""))

	match msg_type:
		"connected":
			my_player_id = String(msg.get("playerId", ""))

		"lobby_state":
			_handle_lobby_state(msg)

		"match_countdown":
			var countdown_state_raw: Variant = msg.get("state", {})
			if typeof(countdown_state_raw) == TYPE_DICTIONARY:
				current_match_state = countdown_state_raw as Dictionary
				_extract_player_names_from_match_state(current_match_state)

			if current_screen == null or current_screen.scene_file_path != "res://scenes/game/game_screen.tscn":
				_show_game_screen()

			if current_screen != null:
				if current_screen.has_method("reset_for_rematch"):
					current_screen.reset_for_rematch()
				if current_screen.has_method("set_local_player_info"):
					current_screen.set_local_player_info(my_player_id, my_side)
				if current_screen.has_method("set_player_names"):
					current_screen.set_player_names(left_player_name, right_player_name)
				if current_screen.has_method("apply_match_state"):
					current_screen.apply_match_state(current_match_state)
				if current_screen.has_method("show_countdown"):
					current_screen.show_countdown()

		"match_started":
			var started_state_raw: Variant = msg.get("state", {})
			if typeof(started_state_raw) == TYPE_DICTIONARY:
				current_match_state = started_state_raw as Dictionary
				_extract_player_names_from_match_state(current_match_state)

			if current_screen == null or current_screen.scene_file_path != "res://scenes/game/game_screen.tscn":
				_show_game_screen()

			if current_screen != null:
				if current_screen.has_method("set_local_player_info"):
					current_screen.set_local_player_info(my_player_id, my_side)
				if current_screen.has_method("set_player_names"):
					current_screen.set_player_names(left_player_name, right_player_name)
				if current_screen.has_method("apply_match_state"):
					current_screen.apply_match_state(current_match_state)
				if current_screen.has_method("start_match"):
					current_screen.start_match()

		"word_rejected":
			if current_screen != null and current_screen.has_method("handle_word_rejected"):
				current_screen.handle_word_rejected(msg)

		"word_resolved":
			var resolved_state_raw: Variant = msg.get("state", {})
			if typeof(resolved_state_raw) == TYPE_DICTIONARY:
				current_match_state = resolved_state_raw as Dictionary
				_extract_player_names_from_match_state(current_match_state)

			if current_screen != null:
				if current_screen.has_method("apply_match_state"):
					current_screen.apply_match_state(current_match_state)
				if current_screen.has_method("handle_word_resolved"):
					current_screen.handle_word_resolved(msg)
		
		"soldier_spawned":
			if current_screen != null and current_screen.has_method("handle_soldier_spawned"):
				current_screen.handle_soldier_spawned(msg)

		"soldier_state":
			if current_screen != null and current_screen.has_method("handle_soldier_state"):
				current_screen.handle_soldier_state(msg)

		"soldier_attack":
			if current_screen != null and current_screen.has_method("handle_soldier_attack"):
				current_screen.handle_soldier_attack(msg)

		"soldier_damaged":
			if current_screen != null and current_screen.has_method("handle_soldier_damaged"):
				current_screen.handle_soldier_damaged(msg)

		"soldier_died":
			if current_screen != null and current_screen.has_method("handle_soldier_died"):
				current_screen.handle_soldier_died(msg)

		"castle_hp_updated":
			if current_screen != null and current_screen.has_method("handle_castle_hp_updated"):
				current_screen.handle_castle_hp_updated(msg)

		"match_ended":
			var ended_state_raw: Variant = msg.get("state", {})
			if typeof(ended_state_raw) == TYPE_DICTIONARY:
				current_match_state = ended_state_raw as Dictionary
				_extract_player_names_from_match_state(current_match_state)

			if current_screen != null:
				if current_screen.has_method("apply_match_state"):
					current_screen.apply_match_state(current_match_state)
				if current_screen.has_method("handle_match_ended"):
					current_screen.handle_match_ended(msg)

		"opponent_left_session":
			if current_screen != null and current_screen.has_method("set_opponent_left_session"):
				current_screen.set_opponent_left_session()

		"rematch_waiting":
			var waiting_state_raw: Variant = msg.get("state", {})
			if typeof(waiting_state_raw) == TYPE_DICTIONARY:
				current_match_state = waiting_state_raw as Dictionary
				_extract_player_names_from_match_state(current_match_state)

			if current_screen != null and current_screen.has_method("set_waiting_for_rematch"):
				current_screen.set_waiting_for_rematch(true)

		"rematch_ready":
			var ready_state_raw: Variant = msg.get("state", {})
			if typeof(ready_state_raw) == TYPE_DICTIONARY:
				current_match_state = ready_state_raw as Dictionary
				_extract_player_names_from_match_state(current_match_state)

			if current_screen != null and current_screen.has_method("set_both_players_ready"):
				current_screen.set_both_players_ready()

		"pong":
			var server_time: int = int(msg.get("serverTime", 0))
			if current_screen != null and current_screen.has_method("set_ping_text"):
				current_screen.set_ping_text("Server: %d" % server_time)

		"error":
			if current_screen != null and current_screen.has_method("set_status_text"):
				current_screen.set_status_text(String(msg.get("message", "Unknown error")))


func _handle_lobby_state(msg: Dictionary) -> void:
	current_lobby_code = String(msg.get("code", current_lobby_code))
	var phase: String = String(msg.get("phase", "waiting"))

	var players_raw: Variant = msg.get("players", [])
	var players: Array = []
	if typeof(players_raw) == TYPE_ARRAY:
		players = players_raw as Array

	left_player_name = "Left Player"
	right_player_name = "Right Player"

	for player_raw in players:
		if typeof(player_raw) != TYPE_DICTIONARY:
			continue

		var player: Dictionary = player_raw as Dictionary
		var player_id: String = String(player.get("playerId", ""))
		var player_name: String = String(player.get("playerName", ""))
		var player_side: String = String(player.get("side", ""))
		var is_ready: bool = bool(player.get("isReady", false))

		if player_side == "left":
			left_player_name = player_name if not player_name.is_empty() else "Left Player"
		elif player_side == "right":
			right_player_name = player_name if not player_name.is_empty() else "Right Player"

		if player_id == my_player_id:
			my_side = player_side

	if current_screen == null or current_screen.scene_file_path != "res://scenes/menus/lobby_screen.tscn":
		return

	if current_screen.has_method("set_lobby_code"):
		current_screen.set_lobby_code(current_lobby_code)

	if current_screen.has_method("set_player_labels"):
		current_screen.set_player_labels(left_player_name, right_player_name)

	if current_screen.has_method("set_phase"):
		current_screen.set_phase(phase)

	if current_screen.has_method("set_status_text"):
		if phase == "waiting":
			current_screen.set_status_text("Waiting for a player to join...")
		else:
			current_screen.set_status_text("Both players connected. Enter your name and press Ready.")


func _extract_player_names_from_match_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	var players_raw: Variant = state.get("players", {})
	if typeof(players_raw) != TYPE_DICTIONARY:
		return
	var players: Dictionary = players_raw as Dictionary

	var left_raw: Variant = players.get("left", {})
	var right_raw: Variant = players.get("right", {})

	if typeof(left_raw) == TYPE_DICTIONARY:
		var left: Dictionary = left_raw as Dictionary
		left_player_name = String(left.get("name", "Left Player"))

	if typeof(right_raw) == TYPE_DICTIONARY:
		var right: Dictionary = right_raw as Dictionary
		right_player_name = String(right.get("name", "Right Player"))


func _on_local_game_over(_winner_side: String, _winner_player_id: String) -> void:
	pass


func _on_game_back_to_menu_requested() -> void:
	if current_screen != null and current_screen.scene_file_path == "res://scenes/game/game_screen.tscn":
		network.send_json({
			"type": "leave_match"
		})
	elif current_lobby_code != "":
		network.send_json({
			"type": "leave_lobby"
		})

	current_lobby_code = ""
	current_lobby_mode = ""
	current_match_state.clear()
	_show_main_menu()


func _on_game_play_again_requested() -> void:
	network.send_json({
		"type": "play_again"
	})
