extends Node

signal connected_to_server
signal disconnected_from_server
signal message_received(message: Dictionary)

var socket := WebSocketPeer.new()
var was_open_last_frame: bool = false

func connect_to_server(target_url: String) -> void:
	var err := socket.connect_to_url(target_url)
	if err != OK:
		push_error("WebSocket connect failed: %s" % err)

func _process(_delta: float) -> void:
	socket.poll()

	var state := socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not was_open_last_frame:
			was_open_last_frame = true
			connected_to_server.emit()

		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			var text := packet.get_string_from_utf8()
			var data = JSON.parse_string(text)

			if typeof(data) == TYPE_DICTIONARY:
				message_received.emit(data)

	elif state == WebSocketPeer.STATE_CLOSED:
		if was_open_last_frame:
			was_open_last_frame = false
			disconnected_from_server.emit()

func send_json(payload: Dictionary) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	socket.send_text(JSON.stringify(payload))
