extends Node

signal connected_to_server
signal disconnected_from_server
signal connection_failed
signal message_received(message: Dictionary)

var socket: WebSocketPeer = WebSocketPeer.new()

var last_state: int = WebSocketPeer.STATE_CLOSED
var retry_pending: bool = false
var retry_delay: float = 2.5

const LOCAL_URL := "ws://localhost:8080"
const PROD_URL := "wss://eitake-typing-battle-game.onrender.com"

var use_local := false


func get_server_url() -> String:
	return LOCAL_URL if use_local else PROD_URL


func connect_to_server() -> void:
	# Reset socket to avoid stale connections
	socket = WebSocketPeer.new()
	last_state = WebSocketPeer.STATE_CLOSED

	var url := get_server_url()
	var err := socket.connect_to_url(url)

	if err != OK:
		push_error("WebSocket connect failed: %s" % err)
		connection_failed.emit()
		_schedule_retry()


func _process(_delta: float) -> void:
	socket.poll()

	var state := socket.get_ready_state()

	# Detect state changes
	if state != last_state:
		_handle_state_change(last_state, state)
		last_state = state

	# Handle incoming messages
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			var text := packet.get_string_from_utf8()
			var data = JSON.parse_string(text)

			if typeof(data) == TYPE_DICTIONARY:
				message_received.emit(data)


func _handle_state_change(old_state: int, new_state: int) -> void:
	match new_state:

		WebSocketPeer.STATE_OPEN:
			retry_pending = false
			connected_to_server.emit()

		WebSocketPeer.STATE_CLOSED:
			# Determine why we closed
			if old_state == WebSocketPeer.STATE_CONNECTING:
				connection_failed.emit()
			elif old_state == WebSocketPeer.STATE_OPEN:
				disconnected_from_server.emit()

			_schedule_retry()


func _schedule_retry() -> void:
	if retry_pending:
		return

	retry_pending = true
	_retry_connect()


func _retry_connect() -> void:
	await get_tree().create_timer(retry_delay).timeout

	# If somehow already connected, abort retry
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		retry_pending = false
		return

	retry_pending = false
	connect_to_server()


func send_json(payload: Dictionary) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	socket.send_text(JSON.stringify(payload))
