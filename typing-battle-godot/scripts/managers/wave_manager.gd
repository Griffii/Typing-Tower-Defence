extends Node

signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal all_waves_cleared
signal spawn_enemy_requested(enemy_data: Dictionary)

var wave_definitions: Array = []
var current_wave_index: int = -1
var current_wave_queue: Array = []
var current_spawn_cursor: int = 0

var alive_enemy_count: int = 0
var pending_spawn_count: int = 0
var wave_active: bool = false
var wave_finished: bool = false


func set_wave_definitions(waves: Array) -> void:
	wave_definitions = waves.duplicate(true)


func reset_for_new_run() -> void:
	current_wave_index = -1
	current_wave_queue.clear()
	current_spawn_cursor = 0
	alive_enemy_count = 0
	pending_spawn_count = 0
	wave_active = false
	wave_finished = false


func start_wave(wave_index: int) -> void:
	if wave_index < 0:
		return

	if wave_index >= wave_definitions.size():
		all_waves_cleared.emit()
		return

	current_wave_index = wave_index
	alive_enemy_count = 0
	current_spawn_cursor = 0
	wave_finished = false
	wave_active = true

	var wave_data_variant: Variant = wave_definitions[wave_index]
	if typeof(wave_data_variant) != TYPE_DICTIONARY:
		push_warning("WaveManager: wave %d is not a Dictionary." % wave_index)
		current_wave_queue.clear()
		pending_spawn_count = 0
		_try_finish_wave()
		return

	var wave_data: Dictionary = wave_data_variant as Dictionary
	var enemies_variant: Variant = wave_data.get("enemies", [])

	if typeof(enemies_variant) == TYPE_ARRAY:
		current_wave_queue = (enemies_variant as Array).duplicate(true)
	else:
		current_wave_queue = []

	pending_spawn_count = current_wave_queue.size()

	wave_started.emit(current_wave_index)

	if pending_spawn_count == 0:
		_try_finish_wave()


func get_current_wave_data() -> Dictionary:
	if current_wave_index < 0 or current_wave_index >= wave_definitions.size():
		return {}

	var wave_data_variant: Variant = wave_definitions[current_wave_index]
	if typeof(wave_data_variant) != TYPE_DICTIONARY:
		return {}

	return wave_data_variant as Dictionary


func has_more_enemies_to_spawn() -> bool:
	return current_spawn_cursor < current_wave_queue.size()


func get_next_enemy_data() -> Dictionary:
	if not has_more_enemies_to_spawn():
		return {}

	var enemy_variant: Variant = current_wave_queue[current_spawn_cursor]
	current_spawn_cursor += 1

	if typeof(enemy_variant) != TYPE_DICTIONARY:
		push_warning("WaveManager: enemy entry %d in wave %d is not a Dictionary." % [current_spawn_cursor - 1, current_wave_index])
		pending_spawn_count = max(0, pending_spawn_count - 1)
		_try_finish_wave()
		return {}

	return enemy_variant as Dictionary


func request_next_enemy_spawn() -> void:
	if not wave_active:
		return

	var enemy_data: Dictionary = get_next_enemy_data()
	if enemy_data.is_empty():
		return

	spawn_enemy_requested.emit(enemy_data)


func notify_enemy_spawned(_enemy: Node) -> void:
	if not wave_active:
		return

	alive_enemy_count += 1
	pending_spawn_count = max(0, pending_spawn_count - 1)


func notify_enemy_died(_enemy: Node) -> void:
	if alive_enemy_count > 0:
		alive_enemy_count -= 1

	_try_finish_wave()


func notify_spawn_queue_exhausted() -> void:
	_try_finish_wave()


func is_wave_active() -> bool:
	return wave_active


func get_alive_enemy_count() -> int:
	return alive_enemy_count


func get_pending_spawn_count() -> int:
	return pending_spawn_count


func _try_finish_wave() -> void:
	if not wave_active:
		return

	if has_more_enemies_to_spawn():
		return

	if pending_spawn_count > 0:
		return

	if alive_enemy_count > 0:
		return

	if wave_finished:
		return

	wave_finished = true
	wave_active = false

	wave_cleared.emit(current_wave_index)

	if current_wave_index >= wave_definitions.size() - 1:
		all_waves_cleared.emit()
