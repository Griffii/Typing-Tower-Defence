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

func _ready() -> void:
	network.connected_to_server.connect(_on_socket_connected)
	network.disconnected_from_server.connect(_on_socket_disconnected)
	network.message_received.connect(_on_server_message)
	
	_show_main_menu()
	
	await get_tree().process_frame
	network.connect_to_server("ws://localhost:8080")


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


func _show_game_screen() -> void:
	var game: Control = _set_screen(GAME_SCENE)
	
	if game.has_method("set_local_player_info"):
		game.set_local_player_info(my_player_id, my_side)
	
	if game.has_signal("local_game_over"):
		game.local_game_over.connect(_on_local_game_over)
	
	if not current_match_state.is_empty() and game.has_method("apply_match_state"):
		game.apply_match_state(current_match_state)


func _on_main_menu_create_requested() -> void:
	_show_lobby_host()
	network.send_json({
		"type": "create_lobby"
	})


func _on_main_menu_join_requested() -> void:
	_show_lobby_join()


func _on_lobby_join_code_submitted(code: String) -> void:
	var normalized_code: String = code.strip_edges().to_upper()
	if normalized_code.is_empty():
		return
	
	current_lobby_code = normalized_code
	
	network.send_json({
		"type": "join_lobby",
		"code": normalized_code
	})
	
	if current_screen != null and current_screen.has_method("set_status_text"):
		current_screen.set_status_text("Joining lobby...")


func _on_lobby_leave_requested() -> void:
	current_lobby_code = ""
	current_lobby_mode = ""
	current_match_state.clear()
	_show_main_menu()


func _on_socket_connected() -> void:
	pass


func _on_socket_disconnected() -> void:
	current_lobby_code = ""
	current_lobby_mode = ""
	current_match_state.clear()
	_show_main_menu()


func _on_server_message(msg: Dictionary) -> void:
	var msg_type: String = String(msg.get("type", ""))
	
	match msg_type:
		"connected":
			my_player_id = String(msg.get("playerId", ""))
		
		"lobby_created":
			my_side = String(msg.get("side", ""))
			current_lobby_code = String(msg.get("code", ""))
			
			if current_screen != null:
				if current_screen.has_method("set_mode"):
					current_screen.set_mode("host")
				if current_screen.has_method("set_lobby_code"):
					current_screen.set_lobby_code(current_lobby_code)
				if current_screen.has_method("set_status_text"):
					current_screen.set_status_text("Waiting for a player to join...")
		
		"lobby_joined":
			my_side = String(msg.get("side", ""))
			current_lobby_code = String(msg.get("code", ""))
			
			if current_screen != null:
				if current_screen.has_method("set_mode"):
					current_screen.set_mode("join")
				if current_screen.has_method("set_lobby_code"):
					current_screen.set_lobby_code(current_lobby_code)
				if current_screen.has_method("set_status_text"):
					current_screen.set_status_text("Joined lobby.")
		
		"lobby_ready":
			if current_screen != null and current_screen.has_method("set_status_text"):
				current_screen.set_status_text("Both players connected. Starting match...")
		
		"match_countdown":
			var countdown_state_raw: Variant = msg.get("state", {})
			if typeof(countdown_state_raw) == TYPE_DICTIONARY:
				current_match_state = countdown_state_raw as Dictionary
			
			_show_game_screen()
			
			if current_screen != null:
				if current_screen.has_method("apply_match_state"):
					current_screen.apply_match_state(current_match_state)
				if current_screen.has_method("show_countdown"):
					current_screen.show_countdown()
		
		"match_started":
			var started_state_raw: Variant = msg.get("state", {})
			if typeof(started_state_raw) == TYPE_DICTIONARY:
				current_match_state = started_state_raw as Dictionary
			
			if current_screen == null or current_screen.scene_file_path != "res://scenes/game/game_screen.tscn":
				_show_game_screen()
			
			if current_screen != null:
				if current_screen.has_method("set_local_player_info"):
					current_screen.set_local_player_info(my_player_id, my_side)
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
			
			if current_screen != null:
				if current_screen.has_method("apply_match_state"):
					current_screen.apply_match_state(current_match_state)
				if current_screen.has_method("handle_word_resolved"):
					current_screen.handle_word_resolved(msg)
		
		"match_ended":
			var ended_state_raw: Variant = msg.get("state", {})
			if typeof(ended_state_raw) == TYPE_DICTIONARY:
				current_match_state = ended_state_raw as Dictionary
			
			if current_screen != null:
				if current_screen.has_method("apply_match_state"):
					current_screen.apply_match_state(current_match_state)
				if current_screen.has_method("handle_match_ended"):
					current_screen.handle_match_ended(msg)
		
		"pong":
			var server_time: int = int(msg.get("serverTime", 0))
			if current_screen != null and current_screen.has_method("set_ping_text"):
				current_screen.set_ping_text("Server: %d" % server_time)
		
		"error":
			if current_screen != null and current_screen.has_method("set_status_text"):
				current_screen.set_status_text(String(msg.get("message", "Unknown error")))



func _on_local_game_over(winner_side: String, _winner_player_id: String) -> void:
	var winner_text: String = "YOU LOSE"
	if winner_side == my_side:
		winner_text = "YOU WIN"
	
	# Temporary: keep using current game screen text lock.
	# Replace this later with a dedicated game_over scene.
	if current_screen != null and current_screen.has_method("set_status_text"):
		current_screen.set_status_text("Game over.")
