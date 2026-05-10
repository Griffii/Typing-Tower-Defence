# res://scripts/ui/dialogue/dialogue_overlay.gd
class_name DialogueOverlay
extends CanvasLayer

signal dialogue_finished

const AVATAR_BASE_SCALE: Vector2 = Vector2(3.0, 3.0)
const AVATAR_FOCUSED_SCALE: Vector2 = Vector2(3.18, 3.18)
const AVATAR_FOCUS_TIME: float = 0.15

const AVATAR_FOCUSED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const AVATAR_UNFOCUSED_MODULATE: Color = Color(0.45, 0.45, 0.45, 1.0)

const TYPE_CHARACTERS_PER_SECOND: float = 45.0

@onready var left_avatar_marker: Marker2D = %LeftAvatarMarker
@onready var right_avatar_marker: Marker2D = %RightAvatarMarker

@onready var dialogue_box: PanelContainer = %DialogueBox
@onready var name_label: Label = %NameLabel
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var prompt_label: Label = %PromptLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var dialogue_data: DialogueSequenceData = null
var current_index: int = -1

var speaker_instances: Dictionary = {}
var speaker_focus_tweens: Dictionary = {}

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
	_apply_line(line)


func _apply_line(line: DialogueLineData) -> void:
	if line == null:
		_next_line()
		return

	var speaker: DialogueSpeakerData = dialogue_data.get_speaker(line.speaker_id)

	if speaker == null:
		push_warning("DialogueOverlay: Missing speaker for line: " + line.speaker_id)
		name_label.text = ""
		full_line_text = _resolve_dynamic_text(line.text)
		_start_typing_text(full_line_text)
		return

	name_label.text = _resolve_speaker_name(speaker)
	full_line_text = _resolve_dynamic_text(line.text)

	_apply_dialogue_style(speaker)
	_focus_speaker(line.speaker_id)
	_start_typing_text(full_line_text)


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

	for speaker: DialogueSpeakerData in dialogue_data.speakers:
		if speaker == null:
			continue

		var scene: PackedScene = speaker.avatar_scene
		if scene == null:
			push_warning("DialogueOverlay: Speaker has no avatar_scene: " + speaker.speaker_id)
			continue

		var instance: Node = scene.instantiate()
		speaker_instances[speaker.speaker_id] = instance

		var marker: Marker2D = _get_marker_for_position(speaker.default_position)
		marker.add_child(instance)

		if instance is Node2D:
			var node_2d: Node2D = instance as Node2D
			node_2d.position = Vector2.ZERO
			node_2d.scale = AVATAR_BASE_SCALE

		var canvas_item: CanvasItem = instance as CanvasItem
		if canvas_item != null:
			canvas_item.modulate = AVATAR_UNFOCUSED_MODULATE


func _get_marker_for_position(position_id: String) -> Marker2D:
	match position_id:
		"left":
			return left_avatar_marker
		"right":
			return right_avatar_marker
		_:
			return left_avatar_marker


func _clear_speakers() -> void:
	for tween in speaker_focus_tweens.values():
		var existing_tween: Tween = tween as Tween
		if existing_tween != null and existing_tween.is_valid():
			existing_tween.kill()

	speaker_focus_tweens.clear()

	for marker in [left_avatar_marker, right_avatar_marker]:
		if marker == null:
			continue

		for child in marker.get_children():
			child.queue_free()


func _focus_speaker(active_speaker_id: String) -> void:
	for speaker_id in speaker_instances.keys():
		var instance: CanvasItem = speaker_instances[speaker_id] as CanvasItem
		if instance == null:
			continue

		if speaker_focus_tweens.has(speaker_id):
			var old_tween: Tween = speaker_focus_tweens[speaker_id] as Tween
			if old_tween != null and old_tween.is_valid():
				old_tween.kill()

		var target_modulate: Color = AVATAR_FOCUSED_MODULATE
		var target_scale: Vector2 = AVATAR_FOCUSED_SCALE

		if speaker_id != active_speaker_id:
			target_modulate = AVATAR_UNFOCUSED_MODULATE
			target_scale = AVATAR_BASE_SCALE

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

		sequence.lines.append(line)

	start(sequence)


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
