extends Node

signal connected_to_server
signal disconnected_from_server
signal connection_failed
signal connection_state_changed(state: String)
signal message_received(message: Dictionary)

var socket: WebSocketPeer = WebSocketPeer.new()

var last_state: int = WebSocketPeer.STATE_CLOSED
var retry_pending: bool = false
var retry_delay: float = 2.5

var queued_messages: Array[String] = []

const LOCAL_URL := "ws://localhost:8080"
const PROD_URL := "wss://eitake-typing-battle-game.onrender.com"

# Set to 'false' to use the above prod_url and play online
# set tp 'true' if spinning up the server on your own computer
## If you change the port here you must also change the port in the server files
var use_local := false


func get_server_url() -> String:
	return LOCAL_URL if use_local else PROD_URL


func connect_to_server() -> void:
	socket = WebSocketPeer.new()
	last_state = WebSocketPeer.STATE_CLOSED

	var url := get_server_url()
	var err := socket.connect_to_url(url)

	if err != OK:
		push_error("WebSocket connect failed: %s" % err)
		connection_failed.emit()
		connection_state_changed.emit("failed")
		_schedule_retry()
	else:
		connection_state_changed.emit("connecting")


func _process(_delta: float) -> void:
	socket.poll()

	var state := socket.get_ready_state()

	if state != last_state:
		_handle_state_change(last_state, state)
		last_state = state

	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			var text := packet.get_string_from_utf8()
			var data = JSON.parse_string(text)

			if typeof(data) == TYPE_DICTIONARY:
				message_received.emit(data)


func _handle_state_change(old_state: int, new_state: int) -> void:
	match new_state:
		WebSocketPeer.STATE_CONNECTING:
			connection_state_changed.emit("connecting")

		WebSocketPeer.STATE_OPEN:
			retry_pending = false
			connection_state_changed.emit("open")
			_flush_queued_messages()
			connected_to_server.emit()

		WebSocketPeer.STATE_CLOSING:
			connection_state_changed.emit("closing")

		WebSocketPeer.STATE_CLOSED:
			if old_state == WebSocketPeer.STATE_CONNECTING:
				connection_failed.emit()
				connection_state_changed.emit("failed")
			elif old_state == WebSocketPeer.STATE_OPEN:
				disconnected_from_server.emit()
				connection_state_changed.emit("closed")
			else:
				connection_state_changed.emit("closed")

			_schedule_retry()


func _schedule_retry() -> void:
	if retry_pending:
		return

	retry_pending = true
	_retry_connect()


func _retry_connect() -> void:
	await get_tree().create_timer(retry_delay).timeout

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		retry_pending = false
		return

	retry_pending = false
	connect_to_server()


func send_json(payload: Dictionary) -> void:
	var serialized: String = JSON.stringify(payload)

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(serialized)
		return

	queued_messages.append(serialized)


func _flush_queued_messages() -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	for message: String in queued_messages:
		socket.send_text(message)

	queued_messages.clear()


func is_server_connected() -> bool:
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN


func get_connection_state_name() -> String:
	match socket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			return "connecting"
		WebSocketPeer.STATE_OPEN:
			return "open"
		WebSocketPeer.STATE_CLOSING:
			return "closing"
		WebSocketPeer.STATE_CLOSED:
			return "closed"
		_:
			return "unknown"
