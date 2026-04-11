extends Node

signal target_locked(target_enemy: Node)
signal target_released(target_enemy: Node)
signal target_changed(target_enemy: Node)
signal word_completed(target_enemy: Node)
signal input_cleared

@onready var spawn_manager: Node = %SpawnManager

var current_level: BattlefieldLevel = null
var tower_container: Node = null

var is_active: bool = false
var active_target: Node = null
var input_buffer: String = ""



func set_level(level: BattlefieldLevel) -> void:
	current_level = level
	tower_container = null

	if current_level != null and current_level.has_method("get_tower_container"):
		tower_container = current_level.get_tower_container()


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

	var matched_target: Node = _find_best_target_for_input(input_buffer)

	if matched_target != null:
		if matched_target != active_target:
			_set_active_target(matched_target)
	elif active_target == null:
		return

	_update_target_typing_feedback()

	if active_target != null and is_instance_valid(active_target) and active_target.has_method("get_current_word"):
		var target_word: String = String(active_target.get_current_word()).to_lower()

		if input_buffer == target_word:
			var completed_target: Node = active_target
			word_completed.emit(completed_target)
			input_buffer = ""
			input_cleared.emit()
			_clear_target()


func _find_best_target_for_input(input_text: String) -> Node:
	if input_text.is_empty():
		return null

	var enemy_candidates: Array[Node] = []
	var tower_candidates: Array[Node] = []

	_collect_enemy_candidates(input_text, enemy_candidates)
	_collect_tower_candidates(input_text, tower_candidates)

	if not enemy_candidates.is_empty():
		return enemy_candidates[0]

	if not tower_candidates.is_empty():
		tower_candidates.sort_custom(_sort_tower_priority)
		return tower_candidates[0]

	return null


func _collect_enemy_candidates(input_text: String, candidates: Array[Node]) -> void:
	if spawn_manager == null or not spawn_manager.has_method("get_active_enemies"):
		return

	var enemies_variant: Variant = spawn_manager.get_active_enemies()
	if typeof(enemies_variant) != TYPE_ARRAY:
		return

	var enemies: Array = enemies_variant as Array

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		if not enemy.has_method("get_current_word"):
			continue

		var word: String = String(enemy.get_current_word()).to_lower()
		if word.is_empty():
			continue

		if word.begins_with(input_text):
			candidates.append(enemy)


func _collect_tower_candidates(input_text: String, candidates: Array[Node]) -> void:
	if tower_container == null or not is_instance_valid(tower_container):
		return

	for child in tower_container.get_children():
		if not is_instance_valid(child):
			continue

		if not child.has_method("can_accept_word"):
			continue

		if not child.can_accept_word():
			continue

		if not child.has_method("get_current_word"):
			continue

		var word: String = String(child.get_current_word()).to_lower()
		if word.is_empty():
			continue

		if word.begins_with(input_text):
			candidates.append(child)


func _sort_enemy_priority(a: Node, b: Node) -> bool:
	# First-spawned enemy should win.
	# SpawnManager.get_active_enemies() is assumed to preserve spawn order.
	# Stable fallback: instance id.
	return a.get_instance_id() < b.get_instance_id()


func _sort_tower_priority(a: Node, b: Node) -> bool:
	if not (a is Node2D) or not (b is Node2D):
		return a.get_instance_id() < b.get_instance_id()

	var a_node: Node2D = a as Node2D
	var b_node: Node2D = b as Node2D

	if a_node.global_position.x == b_node.global_position.x:
		return a_node.get_instance_id() < b_node.get_instance_id()

	return a_node.global_position.x < b_node.global_position.x


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


func _clear_target() -> void:
	if active_target != null and is_instance_valid(active_target):
		if active_target.has_method("set_targeted"):
			active_target.set_targeted(false)

		if active_target.has_method("clear_typing_feedback"):
			active_target.clear_typing_feedback()

		target_released.emit(active_target)

	active_target = null
