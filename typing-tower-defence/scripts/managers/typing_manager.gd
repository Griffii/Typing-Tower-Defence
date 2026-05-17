# res://scripts/game/managers/typing_manager.gd
extends Node

signal target_locked(target: Node)
signal target_released(target: Node)
signal target_changed(target: Node)
signal word_completed(target: Node)
signal input_cleared

var current_level: Node = null
var typing_target_container: Node = null

var is_active: bool = false
var active_target: Node = null
var input_buffer: String = ""


# ---------------------------
# Setup
# ---------------------------

func set_level(level: Node) -> void:
	current_level = level
	typing_target_container = null

	if current_level != null and current_level.has_method("get_typing_target_container"):
		typing_target_container = current_level.get_typing_target_container()


func reset_for_new_run() -> void:
	is_active = false
	clear_input_state()


func begin_wave(_wave_index: int) -> void:
	clear_input_state()


func set_active(active: bool) -> void:
	is_active = active

	if not is_active:
		clear_input_state()


func clear_input_state() -> void:
	input_buffer = ""
	_clear_active_target()
	input_cleared.emit()


func cancel_current_target() -> void:
	clear_input_state()


# ---------------------------
# Input
# ---------------------------

func process_input_text(text: String) -> void:
	if not is_active:
		return

	input_buffer = text.strip_edges()

	if input_buffer.is_empty():
		_clear_active_target()
		return

	if active_target != null and not is_instance_valid(active_target):
		active_target = null

	var matched_target: Node = _find_best_target_for_input(input_buffer)

	if matched_target != null:
		if matched_target != active_target:
			_set_active_target(matched_target)
	elif active_target == null:
		return

	_update_target_typing_feedback()

	if active_target == null or not is_instance_valid(active_target):
		return

	if not active_target.has_method("get_current_word"):
		return

	var target_word: String = String(active_target.get_current_word())

	if _words_match(input_buffer, target_word):
		var completed_target: Node = active_target

		if completed_target.has_method("complete_current_word"):
			completed_target.complete_current_word()

		word_completed.emit(completed_target)

		input_buffer = ""
		input_cleared.emit()
		_clear_active_target()


# ---------------------------
# Target discovery
# ---------------------------

func _find_best_target_for_input(input_text: String) -> Node:
	if input_text.is_empty():
		return null

	var candidates: Array[Node] = []
	_collect_target_candidates(input_text, candidates)

	if candidates.is_empty():
		return null

	candidates.sort_custom(_sort_target_priority)
	return candidates[0]


func _collect_target_candidates(input_text: String, candidates: Array[Node]) -> void:
	if typing_target_container != null and is_instance_valid(typing_target_container):
		for child in typing_target_container.get_children():
			_try_add_target_candidate(child, input_text, candidates)

	for target in get_tree().get_nodes_in_group("typing_targets"):
		_try_add_target_candidate(target, input_text, candidates)


func _try_add_target_candidate(node: Node, input_text: String, candidates: Array[Node]) -> void:
	if node == null or not is_instance_valid(node):
		return

	if candidates.has(node):
		return

	if not node.has_method("can_accept_word"):
		return

	if not node.can_accept_word():
		return

	if not node.has_method("get_current_word"):
		return

	var word: String = String(node.get_current_word())
	if word.is_empty():
		return

	if _word_starts_with(word, input_text):
		candidates.append(node)


# ---------------------------
# Matching
# ---------------------------

func _word_starts_with(word: String, input_text: String) -> bool:
	return word.to_lower().begins_with(input_text.to_lower())


func _words_match(input_text: String, word: String) -> bool:
	return input_text.to_lower() == word.to_lower()


# ---------------------------
# Priority
# ---------------------------

func _sort_target_priority(a: Node, b: Node) -> bool:
	if a == active_target:
		return true

	if b == active_target:
		return false

	if not (a is Node2D) or not (b is Node2D):
		return a.get_instance_id() < b.get_instance_id()

	var a_node: Node2D = a as Node2D
	var b_node: Node2D = b as Node2D

	if not is_equal_approx(a_node.global_position.y, b_node.global_position.y):
		return a_node.global_position.y < b_node.global_position.y

	if not is_equal_approx(a_node.global_position.x, b_node.global_position.x):
		return a_node.global_position.x < b_node.global_position.x

	return a_node.get_instance_id() < b_node.get_instance_id()


# ---------------------------
# Target state
# ---------------------------

func _set_active_target(new_target: Node) -> void:
	if active_target == new_target:
		return

	if active_target != null and is_instance_valid(active_target):
		if active_target.has_method("set_targeted"):
			active_target.set_targeted(false)

		if active_target.has_method("clear_typing_feedback"):
			active_target.clear_typing_feedback()

		target_released.emit(active_target)

	active_target = new_target

	if active_target != null and is_instance_valid(active_target):
		if active_target.has_method("set_targeted"):
			active_target.set_targeted(true)

		target_locked.emit(active_target)
		target_changed.emit(active_target)


func _update_target_typing_feedback() -> void:
	if active_target == null:
		return

	if active_target.has_method("set_typing_progress"):
		active_target.set_typing_progress(input_buffer)


func _clear_active_target() -> void:
	if active_target != null and is_instance_valid(active_target):
		if active_target.has_method("set_targeted"):
			active_target.set_targeted(false)

		if active_target.has_method("clear_typing_feedback"):
			active_target.clear_typing_feedback()

		target_released.emit(active_target)

	active_target = null
