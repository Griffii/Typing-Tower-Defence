extends Node

signal target_locked(target_enemy: Node)
signal target_released(target_enemy: Node)
signal target_changed(target_enemy: Node)
signal word_completed(target_enemy: Node)
signal input_cleared

@onready var spawn_manager: Node = %SpawnManager

var is_active: bool = false
var active_target: Node = null
var input_buffer: String = ""


func reset_for_new_run() -> void:
	is_active = false
	_clear_target()
	input_buffer = ""


func begin_wave(_wave_index: int) -> void:
	_clear_target()
	input_buffer = ""


func set_active(active: bool) -> void:
	is_active = active

	if not is_active:
		clear_input_state()


func clear_input_state() -> void:
	input_buffer = ""
	_clear_target()
	input_cleared.emit()


func cancel_current_target() -> void:
	input_buffer = ""
	_clear_target()
	input_cleared.emit()


func process_input_text(text: String) -> void:
	if not is_active:
		return

	input_buffer = text.to_lower()

	if input_buffer.is_empty():
		_clear_target()
		return

	if not is_instance_valid(active_target):
		active_target = null

	if active_target == null:
		var target: Node = _find_target_for_first_letter(input_buffer.left(1))
		if target == null:
			return

		active_target = target

		if active_target.has_method("set_targeted"):
			active_target.set_targeted(true)

		target_locked.emit(active_target)
		target_changed.emit(active_target)

	_update_target_typing_feedback()

	if active_target != null and is_instance_valid(active_target) and active_target.has_method("get_current_word"):
		var target_word: String = String(active_target.get_current_word()).to_lower()

		if input_buffer == target_word:
			var completed_target: Node = active_target
			word_completed.emit(completed_target)
			input_buffer = ""
			input_cleared.emit()
			_clear_target()


func _find_target_for_first_letter(first_letter: String) -> Node:
	if first_letter.is_empty():
		return null

	if spawn_manager == null or not spawn_manager.has_method("get_active_enemies"):
		return null

	var enemies_variant: Variant = spawn_manager.get_active_enemies()
	if typeof(enemies_variant) != TYPE_ARRAY:
		return null

	var enemies: Array = enemies_variant as Array
	var candidates: Array[Node] = []

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		if not enemy.has_method("get_current_word"):
			continue

		var word: String = String(enemy.get_current_word()).to_lower()
		if word.is_empty():
			continue

		if word.begins_with(first_letter):
			candidates.append(enemy)

	if candidates.is_empty():
		return null

	candidates.sort_custom(_sort_enemy_target_priority)
	return candidates[0]


func _sort_enemy_target_priority(a: Node, b: Node) -> bool:
	if not (a is Node2D) or not (b is Node2D):
		return false

	var a_node: Node2D = a as Node2D
	var b_node: Node2D = b as Node2D

	if a_node.global_position.x == b_node.global_position.x:
		return a_node.get_instance_id() < b_node.get_instance_id()

	return a_node.global_position.x < b_node.global_position.x


func _update_target_typing_feedback() -> void:
	if active_target == null:
		return

	if active_target.has_method("set_typing_progress"):
		active_target.set_typing_progress(input_buffer)


func _clear_target() -> void:
	if active_target != null and is_instance_valid(active_target):
		if active_target.has_method("set_targeted"):
			active_target.set_targeted(false)

		if active_target.has_method("clear_typing_feedback"):
			active_target.clear_typing_feedback()

		target_released.emit(active_target)

	active_target = null
