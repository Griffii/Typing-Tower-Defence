# res://scripts/ui/dialogue/dialogue_overlay.gd
class_name DialogueOverlay
extends CanvasLayer

signal dialogue_finished
signal dialogue_sfx_requested(sfx_id: String)

const AVATAR_BASE_SCALE: Vector2 = Vector2(3.0, 3.0)
const AVATAR_FOCUSED_SCALE: Vector2 = Vector2(3.18, 3.18)
const AVATAR_FOCUS_TIME: float = 0.15
const AVATAR_MOVE_TIME: float = 1.0

const AVATAR_FOCUSED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const AVATAR_UNFOCUSED_MODULATE: Color = Color(0.45, 0.45, 0.45, 1.0)

const TYPE_CHARACTERS_PER_SECOND: float = 45.0

@onready var left_marker_1: Marker2D = %LeftMarker1
@onready var left_marker_2: Marker2D = %LeftMarker2
@onready var center_marker_1: Marker2D = %CenterMarker1
@onready var center_marker_2: Marker2D = %CenterMarker2
@onready var right_marker_1: Marker2D = %RightMarker1
@onready var right_marker_2: Marker2D = %RightMarker2
@onready var offscreen_right_marker: Marker2D = %OffscreenRightMarker
@onready var offscreen_left_marker: Marker2D = %OffscreenLeftMarker


@onready var dialogue_box: PanelContainer = %DialogueBox
@onready var name_label: Label = %NameLabel
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var prompt_label: RichTextLabel = %PromptLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var dialogue_data: DialogueSequenceData = null
var current_index: int = -1

var speaker_instances: Dictionary = {}
var speaker_focus_tweens: Dictionary = {}
var speaker_move_tweens: Dictionary = {}
var speaker_flip_states: Dictionary = {}

var typing_tween: Tween = null
var is_typing: bool = false
var full_line_text: String = ""


func start(sequence_data: DialogueSequenceData) -> void:
	dialogue_data = sequence_data
	current_index = -1

	if dialogue_data == null:
		push_warning("DialogueOverlay: dialogue_data was null.")
		dialogue_finished.emit()
		queue_free()
		return

	_load_speakers()

	if animation_player != null and animation_player.has_animation("open_dialogue"):
		animation_player.play("open_dialogue")
		await animation_player.animation_finished

	_next_line()


func _input(event: InputEvent) -> void:
	if dialogue_data == null:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("mouse_left"):
		get_viewport().set_input_as_handled()

		if is_typing:
			_finish_typing()
		else:
			_next_line()


func _next_line() -> void:
	current_index += 1

	if current_index >= dialogue_data.lines.size():
		await _finish_dialogue()
		return

	var line: DialogueLineData = dialogue_data.lines[current_index]
	await _apply_line(line)


func _apply_line(line: DialogueLineData) -> void:
	if line == null:
		_next_line()
		return

	await _apply_line_stage_directions(line)

	var speaker: DialogueSpeakerData = dialogue_data.get_speaker(line.speaker_id)

	if speaker == null:
		push_warning("DialogueOverlay: Missing speaker for line: " + line.speaker_id)
		name_label.text = ""
		full_line_text = _resolve_dynamic_text(line.text)
		_play_line_sfx(line)
		_start_typing_text(full_line_text)
		return

	var display_name_override: String = str(_get_resource_property_or_default(line, "display_name_override", ""))
	if display_name_override.strip_edges().is_empty():
		name_label.text = _resolve_speaker_name(speaker)
	else:
		name_label.text = display_name_override
	
	full_line_text = _resolve_dynamic_text(line.text)

	_apply_dialogue_style(speaker)

	var focus_id: String = str(_get_resource_property_or_default(line, "focus_speaker_id", ""))
	if focus_id.is_empty():
		focus_id = line.speaker_id

	_focus_speaker(focus_id)
	_play_line_sfx(line)
	_start_typing_text(full_line_text)


func _apply_line_stage_directions(line: DialogueLineData) -> void:
	var remove_speakers: Array = _get_resource_property_or_default(line, "remove_speakers", [])
	var add_speakers: Array = _get_resource_property_or_default(line, "add_speakers", [])
	var move_speakers: Dictionary = _get_resource_property_or_default(line, "move_speakers", {})
	var flip_speakers: Dictionary = _get_resource_property_or_default(line, "flip_speakers", {})

	for speaker_id in remove_speakers:
		_remove_speaker(str(speaker_id))

	for speaker_id in add_speakers:
		var speaker_id_string: String = str(speaker_id)
		var spawn_marker_id: String = "offscreen_left"

		var speaker: DialogueSpeakerData = dialogue_data.get_speaker(speaker_id_string)
		if speaker != null:
			spawn_marker_id = speaker.default_position

		_add_speaker(speaker_id_string, spawn_marker_id)

	for speaker_id in flip_speakers.keys():
		_set_speaker_flip_state(str(speaker_id), bool(flip_speakers[speaker_id]))

	var move_tweens: Array[Tween] = []

	for speaker_id in move_speakers.keys():
		var move_tween: Tween = _move_speaker(str(speaker_id), str(move_speakers[speaker_id]))
		if move_tween != null:
			move_tweens.append(move_tween)

	for move_tween in move_tweens:
		if move_tween != null and move_tween.is_valid():
			await move_tween.finished


func _get_resource_property_or_default(resource: Resource, property_name: String, default_value: Variant) -> Variant:
	if resource == null:
		return default_value
	
	for property_data in resource.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			return resource.get(property_name)
	
	return default_value


func _resolve_speaker_name(speaker: DialogueSpeakerData) -> String:
	if speaker.use_player_name:
		return PlayerLoadout.player_name

	return speaker.display_name


func _resolve_dynamic_text(raw_text: String) -> String:
	var result: String = raw_text
	result = result.replace("{player_name}", PlayerLoadout.player_name)
	return result


func _load_speakers() -> void:
	_clear_speakers()
	speaker_instances.clear()
	speaker_focus_tweens.clear()
	speaker_move_tweens.clear()
	speaker_flip_states.clear()

	for speaker: DialogueSpeakerData in dialogue_data.speakers:
		if speaker == null:
			continue

		if _is_starting_visible_position(speaker.default_position):
			_add_speaker(speaker.speaker_id, speaker.default_position)


func _add_speaker(speaker_id: String, marker_id: String) -> void:
	if speaker_instances.has(speaker_id):
		_move_speaker(speaker_id, marker_id)
		return

	var speaker: DialogueSpeakerData = dialogue_data.get_speaker(speaker_id)
	if speaker == null:
		push_warning("DialogueOverlay: Cannot add missing speaker: " + speaker_id)
		return

	if speaker.avatar_scene == null:
		push_warning("DialogueOverlay: Speaker has no avatar_scene: " + speaker_id)
		return

	var marker: Marker2D = _get_marker_for_position(marker_id)
	if marker == null:
		push_warning("DialogueOverlay: Missing marker for position: " + marker_id)
		return

	var instance: Node = speaker.avatar_scene.instantiate()
	speaker_instances[speaker_id] = instance
	speaker_flip_states[speaker_id] = false
	
	marker.add_child(instance)
	
	if instance.has_method("set_special_meter_visible"):
		instance.set_special_meter_visible(false)
	
	if instance is Node2D:
		var node_2d: Node2D = instance as Node2D
		node_2d.position = Vector2.ZERO
		node_2d.scale = AVATAR_BASE_SCALE

	var canvas_item: CanvasItem = instance as CanvasItem
	if canvas_item != null:
		canvas_item.modulate = AVATAR_UNFOCUSED_MODULATE


func _remove_speaker(speaker_id: String) -> void:
	_kill_speaker_tweens(speaker_id)

	if not speaker_instances.has(speaker_id):
		return

	var instance: Node = speaker_instances[speaker_id] as Node

	speaker_instances.erase(speaker_id)
	speaker_flip_states.erase(speaker_id)

	if instance != null:
		instance.queue_free()


func _move_speaker(speaker_id: String, marker_id: String) -> Tween:
	if not speaker_instances.has(speaker_id):
		_add_speaker(speaker_id, marker_id)
		return null

	var instance: Node2D = speaker_instances[speaker_id] as Node2D
	var marker: Marker2D = _get_marker_for_position(marker_id)

	if instance == null or marker == null:
		return null

	if speaker_move_tweens.has(speaker_id):
		var old_tween: Tween = speaker_move_tweens[speaker_id] as Tween
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	var old_global_position: Vector2 = instance.global_position

	var old_parent: Node = instance.get_parent()
	if old_parent != null:
		old_parent.remove_child(instance)

	marker.add_child(instance)
	instance.global_position = old_global_position

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(
		instance,
		"global_position",
		marker.global_position,
		AVATAR_MOVE_TIME
	)
	speaker_move_tweens[speaker_id] = tween

	return tween


func _set_speaker_flip_state(speaker_id: String, flip_horizontal: bool) -> void:
	speaker_flip_states[speaker_id] = flip_horizontal
	_apply_speaker_scale(speaker_id, false)


func _apply_speaker_scale(speaker_id: String, focused: bool) -> void:
	if not speaker_instances.has(speaker_id):
		return

	var instance: Node2D = speaker_instances[speaker_id] as Node2D
	if instance == null:
		return

	var target_scale: Vector2 = AVATAR_BASE_SCALE
	if focused:
		target_scale = AVATAR_FOCUSED_SCALE

	var is_flipped: bool = bool(speaker_flip_states.get(speaker_id, false))
	if is_flipped:
		target_scale.x = -absf(target_scale.x)
	else:
		target_scale.x = absf(target_scale.x)

	instance.scale = target_scale


func _get_marker_for_position(position_id: String) -> Marker2D:
	match position_id:
		"left", "left_1", "LeftMarker1":
			return left_marker_1
		"left_2", "LeftMarker2":
			return left_marker_2
		"center", "center_1", "CenterMarker1":
			return center_marker_1
		"center_2", "CenterMarker2":
			return center_marker_2
		"right", "right_1", "RightMarker1":
			return right_marker_1
		"right_2", "RightMarker2":
			return right_marker_2
		"offscreen_left", "OffscreenLeftMarker":
			return offscreen_left_marker
		"offscreen_right", "OffscreenRightMarker":
			return offscreen_right_marker
		_:
			push_warning("DialogueOverlay: Unknown marker id: " + position_id)
			return left_marker_1


func _is_starting_visible_position(position_id: String) -> bool:
	match position_id:
		"left", "left_1", "LeftMarker1":
			return true
		"left_2", "LeftMarker2":
			return true
		"center", "center_1", "CenterMarker1":
			return true
		"center_2", "CenterMarker2":
			return true
		"right", "right_1", "RightMarker1":
			return true
		"right_2", "RightMarker2":
			return true
		_:
			return false


func _clear_speakers() -> void:
	for speaker_id in speaker_instances.keys():
		_kill_speaker_tweens(str(speaker_id))

	for marker in [
		left_marker_1,
		left_marker_2,
		center_marker_1,
		center_marker_2,
		right_marker_1,
		right_marker_2
	]:
		if marker == null:
			continue

		for child in marker.get_children():
			child.queue_free()

	speaker_focus_tweens.clear()
	speaker_move_tweens.clear()
	speaker_flip_states.clear()


func _kill_speaker_tweens(speaker_id: String) -> void:
	if speaker_focus_tweens.has(speaker_id):
		var focus_tween: Tween = speaker_focus_tweens[speaker_id] as Tween
		if focus_tween != null and focus_tween.is_valid():
			focus_tween.kill()

		speaker_focus_tweens.erase(speaker_id)

	if speaker_move_tweens.has(speaker_id):
		var move_tween: Tween = speaker_move_tweens[speaker_id] as Tween
		if move_tween != null and move_tween.is_valid():
			move_tween.kill()

		speaker_move_tweens.erase(speaker_id)


func _focus_speaker(active_speaker_id: String) -> void:
	for speaker_id in speaker_instances.keys():
		var instance: CanvasItem = speaker_instances[speaker_id] as CanvasItem
		if instance == null:
			continue

		if speaker_focus_tweens.has(speaker_id):
			var old_tween: Tween = speaker_focus_tweens[speaker_id] as Tween
			if old_tween != null and old_tween.is_valid():
				old_tween.kill()

		var is_focused: bool = str(speaker_id) == active_speaker_id

		var target_modulate: Color = AVATAR_UNFOCUSED_MODULATE
		var target_scale: Vector2 = AVATAR_BASE_SCALE

		if is_focused:
			target_modulate = AVATAR_FOCUSED_MODULATE
			target_scale = AVATAR_FOCUSED_SCALE

		var is_flipped: bool = bool(speaker_flip_states.get(speaker_id, false))
		if is_flipped:
			target_scale.x = -absf(target_scale.x)
		else:
			target_scale.x = absf(target_scale.x)

		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(instance, "modulate", target_modulate, AVATAR_FOCUS_TIME)
		tween.tween_property(instance, "scale", target_scale, AVATAR_FOCUS_TIME)

		speaker_focus_tweens[speaker_id] = tween


func start_from_raw_data(raw_data: Dictionary) -> void:
	var sequence := DialogueSequenceData.new()

	var raw_speakers: Array = raw_data.get("speakers", [])
	var raw_lines: Array = raw_data.get("lines", [])

	for speaker_data in raw_speakers:
		if not (speaker_data is Dictionary):
			continue

		var speaker := DialogueSpeakerData.new()
		speaker.speaker_id = str(speaker_data.get("speaker_id", ""))
		speaker.default_position = str(speaker_data.get("default_position", "left"))
		speaker.use_player_name = bool(speaker_data.get("use_player_name", false))

		if speaker.use_player_name:
			speaker.display_name = PlayerLoadout.player_name
		else:
			speaker.display_name = str(speaker_data.get("display_name", ""))

		var avatar_scene: PackedScene = speaker_data.get("avatar_scene", null)
		if avatar_scene != null:
			speaker.avatar_scene = avatar_scene

		var dialogue_box_style: StyleBox = speaker_data.get("dialogue_box_style", null)
		if dialogue_box_style != null:
			speaker.dialogue_box_style = dialogue_box_style

		var name_color: Color = speaker_data.get("name_color", Color.TRANSPARENT)
		speaker.name_color = name_color

		sequence.speakers.append(speaker)

	for line_data in raw_lines:
		if not (line_data is Dictionary):
			continue

		var line := DialogueLineData.new()
		line.speaker_id = str(line_data.get("speaker_id", ""))
		line.text = str(line_data.get("text", ""))

		_set_resource_property_if_exists(line, "add_speakers", line_data.get("add_speakers", []))
		_set_resource_property_if_exists(line, "remove_speakers", line_data.get("remove_speakers", []))
		_set_resource_property_if_exists(line, "move_speakers", line_data.get("move_speakers", {}))
		_set_resource_property_if_exists(line, "flip_speakers", line_data.get("flip_speakers", {}))
		_set_resource_property_if_exists(line, "focus_speaker_id", str(line_data.get("focus_speaker_id", "")))
		_set_resource_property_if_exists(line, "sfx_id", str(line_data.get("sfx_id", "")))

		sequence.lines.append(line)

	start(sequence)


func _set_resource_property_if_exists(resource: Resource, property_name: String, value: Variant) -> void:
	if resource == null:
		return
	
	for property_data in resource.get_property_list():
		if str(property_data.get("name", "")) == property_name:
			resource.set(property_name, value)
			return


func _start_typing_text(text: String) -> void:
	if typing_tween != null and typing_tween.is_valid():
		typing_tween.kill()

	dialogue_text.text = text
	dialogue_text.visible_characters = 0

	is_typing = true

	var character_count: int = dialogue_text.get_total_character_count()
	if character_count <= 0:
		_finish_typing()
		return

	var duration: float = float(character_count) / TYPE_CHARACTERS_PER_SECOND

	typing_tween = create_tween()
	typing_tween.tween_property(dialogue_text, "visible_characters", character_count, duration)
	typing_tween.finished.connect(_on_typing_finished, CONNECT_ONE_SHOT)


func _on_typing_finished() -> void:
	is_typing = false
	dialogue_text.visible_characters = -1
	typing_tween = null


func _finish_typing() -> void:
	if typing_tween != null and typing_tween.is_valid():
		typing_tween.kill()

	typing_tween = null
	is_typing = false
	dialogue_text.visible_characters = -1


func _apply_dialogue_style(speaker: DialogueSpeakerData) -> void:
	if speaker.dialogue_box_style != null:
		dialogue_box.add_theme_stylebox_override("panel", speaker.dialogue_box_style)

	if speaker.name_color != Color.TRANSPARENT:
		name_label.add_theme_color_override("font_color", speaker.name_color)


func _finish_dialogue() -> void:
	_finish_typing()

	if animation_player != null and animation_player.has_animation("close_dialogue"):
		animation_player.play("close_dialogue")
		await animation_player.animation_finished

	dialogue_finished.emit()
	queue_free()


func _play_line_sfx(line: DialogueLineData) -> void:
	var sfx_id: String = str(_get_resource_property_or_default(line, "sfx_id", ""))

	if sfx_id.strip_edges().is_empty():
		return

	dialogue_sfx_requested.emit(sfx_id)
