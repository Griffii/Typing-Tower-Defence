# res://scripts/menus/level_select_map.gd
extends Control

signal selection_finished
signal back_requested

const CampaignLevelRegistry = preload("uid://c82ft73lvun6v")
const DIALOGUE_OVERLAY_SCENE: PackedScene = preload("uid://bxtvbt0ut71y2")

const MAP_INTRO_DIALOGUE: DialogueSequenceData = preload("res://data/dialogue/campaign/world_map/map_intro_dialogue.tres")
const MAP_AFTER_CASTLE_WALLS_DIALOGUE: DialogueSequenceData = preload("res://data/dialogue/campaign/world_map/map_after_castle_walls_dialogue.tres")
const MAP_AFTER_GRASSLANDS_DIALOGUE: DialogueSequenceData = preload("uid://b1ui71efd3l2a")
const MAP_AFTER_SEASIDE_FARM_DIALOGUE: DialogueSequenceData = preload("uid://b357ctye6xato")

const BUTTON_BASE_SCALE: Vector2 = Vector2.ONE
const BUTTON_HOVER_SCALE: Vector2 = Vector2(1.08, 1.08)
const BUTTON_HOVER_TIME: float = 0.08

const MAP_MIN_X: float = -600.0
const MAP_MAX_X: float = 0.0

@onready var map_content: Control = %MapContent
@onready var back_button: Button = %BackButton

@onready var castle_walls_button: Button = %CastleWallsButton
@onready var grasslands_button: Button = %GrasslandsButton
@onready var seaside_farm_button: Button = %SeasideFarmButton
@onready var castle_walls_container: MarginContainer = %CastleWallsContainer
@onready var grasslands_container: MarginContainer = %GrasslandsContainer
@onready var seaside_farm_container: MarginContainer = %SeasideFarmContainer

var buttons_by_level_id: Dictionary = {}
var button_tweens: Dictionary = {}

var is_dragging_map: bool = false
var drag_last_mouse_x: float = 0.0
var dialogue_is_playing: bool = false


func _ready() -> void:
	_cache_buttons()
	_connect_signals()
	_setup_button_hover_effects()
	_refresh_buttons()

	await get_tree().process_frame
	await _play_needed_map_dialogue()


func _cache_buttons() -> void:
	buttons_by_level_id = {
		"castle_walls": castle_walls_button,
		"grasslands": grasslands_button,
		"seaside_farm": seaside_farm_button,
	}


func _connect_signals() -> void:
	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	if CampaignProgress != null and CampaignProgress.has_signal("campaign_progress_changed"):
		if not CampaignProgress.campaign_progress_changed.is_connected(_on_campaign_progress_changed):
			CampaignProgress.campaign_progress_changed.connect(_on_campaign_progress_changed)

	for level_data in CampaignLevelRegistry.LEVELS:
		if level_data == null:
			continue

		var level_id: String = level_data.level_id

		if not buttons_by_level_id.has(level_id):
			push_warning("LevelSelectMap: No button found for level_id: %s" % level_id)
			continue

		var button: Button = buttons_by_level_id[level_id]

		if button == null:
			continue

		if not button.pressed.is_connected(_on_level_button_pressed.bind(level_data)):
			button.pressed.connect(_on_level_button_pressed.bind(level_data))


func _setup_button_hover_effects() -> void:
	_setup_hover_button(back_button)

	_setup_hover_button(
		castle_walls_button,
		castle_walls_container
	)

	_setup_hover_button(
		grasslands_button,
		grasslands_container
	)

	_setup_hover_button(
		seaside_farm_button,
		seaside_farm_container
	)


func _setup_hover_button(
	button: Button,
	scale_target: Control = null
) -> void:

	if button == null:
		return

	if scale_target == null:
		scale_target = button

	scale_target.pivot_offset = scale_target.size * 0.5

	if not scale_target.resized.is_connected(_on_scale_target_resized.bind(scale_target)):
		scale_target.resized.connect(_on_scale_target_resized.bind(scale_target))

	if not button.mouse_entered.is_connected(_on_button_mouse_entered.bind(scale_target, button)):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(scale_target, button))

	if not button.mouse_exited.is_connected(_on_button_mouse_exited.bind(scale_target)):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(scale_target))


func _on_scale_target_resized(scale_target: Control) -> void:
	if scale_target == null:
		return

	scale_target.pivot_offset = scale_target.size * 0.5


func _on_button_mouse_entered(
	scale_target: Control,
	button: Button
) -> void:

	if button == null or button.disabled:
		return

	_tween_button_scale(scale_target, BUTTON_HOVER_SCALE)


func _on_button_mouse_exited(scale_target: Control) -> void:
	_tween_button_scale(scale_target, BUTTON_BASE_SCALE)


func _tween_button_scale(
	scale_target: Control,
	target_scale: Vector2
) -> void:

	if scale_target == null:
		return

	if button_tweens.has(scale_target):
		var old_tween: Tween = button_tweens[scale_target] as Tween
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	var tween: Tween = create_tween()
	tween.tween_property(
		scale_target,
		"scale",
		target_scale,
		BUTTON_HOVER_TIME
	)

	button_tweens[scale_target] = tween


func _gui_input(event: InputEvent) -> void:
	if dialogue_is_playing:
		return

	if map_content == null:
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton

		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		if mouse_button.pressed:
			if _is_mouse_over_any_button():
				return

			is_dragging_map = true
			drag_last_mouse_x = mouse_button.position.x
			accept_event()
		else:
			is_dragging_map = false

	elif event is InputEventMouseMotion:
		if not is_dragging_map:
			return

		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var delta_x: float = motion.position.x - drag_last_mouse_x
		drag_last_mouse_x = motion.position.x

		_move_map_by_delta(delta_x)
		accept_event()


func _move_map_by_delta(delta_x: float) -> void:
	if map_content == null:
		return

	var new_x: float = clampf(map_content.position.x + delta_x, MAP_MIN_X, MAP_MAX_X)
	map_content.position.x = new_x


func _is_mouse_over_any_button() -> bool:
	var all_buttons: Array[Button] = [
		back_button,
		castle_walls_button,
		grasslands_button,
		seaside_farm_button,
	]

	var mouse_position: Vector2 = get_global_mouse_position()

	for button in all_buttons:
		if button == null:
			continue

		if not button.visible:
			continue

		var rect: Rect2 = button.get_global_rect()
		if rect.has_point(mouse_position):
			return true

	return false


func _on_campaign_progress_changed() -> void:
	_refresh_buttons()


func _refresh_buttons() -> void:
	for level_data in CampaignLevelRegistry.LEVELS:
		if level_data == null:
			continue

		var level_id: String = level_data.level_id

		if not buttons_by_level_id.has(level_id):
			continue

		var button: Button = buttons_by_level_id[level_id]

		if button == null:
			continue

		var unlocked: bool = CampaignProgress.is_level_unlocked(level_data)
		var completed: bool = CampaignProgress.is_level_completed(level_id)

		button.disabled = not unlocked

		if completed:
			button.text = "%s ✓" % level_data.display_name
		elif unlocked:
			button.text = level_data.display_name
		else:
			button.text = "Locked"

		button.tooltip_text = _get_level_tooltip(level_data, unlocked, completed)


func _get_level_tooltip(level_data: CampaignLevelData, unlocked: bool, completed: bool) -> String:
	if completed:
		return "%s\nCompleted" % level_data.display_name

	if unlocked:
		return "%s\nAvailable" % level_data.display_name

	if level_data.required_level_id.is_empty():
		return "%s\nLocked" % level_data.display_name

	var required_name: String = _get_display_name_for_level_id(level_data.required_level_id)

	return "%s\nLocked. Complete %s first." % [
		level_data.display_name,
		required_name,
	]


func _get_display_name_for_level_id(level_id: String) -> String:
	for level_data in CampaignLevelRegistry.LEVELS:
		if level_data != null and level_data.level_id == level_id:
			return level_data.display_name

	return level_id.replace("_", " ").capitalize()


func _play_needed_map_dialogue() -> void:
	if CampaignProgress == null:
		return

	var sequence: DialogueSequenceData = null
	var flag_id: String = ""

	if CampaignProgress.is_level_completed("seaside_farm") and not _has_seen_map_dialogue("after_seaside_farm"):
		sequence = MAP_AFTER_SEASIDE_FARM_DIALOGUE
		flag_id = "after_seaside_farm"

	elif CampaignProgress.is_level_completed("grasslands") and not _has_seen_map_dialogue("after_grasslands"):
		sequence = MAP_AFTER_GRASSLANDS_DIALOGUE
		flag_id = "after_grasslands"

	elif CampaignProgress.is_level_completed("castle_walls") and not _has_seen_map_dialogue("after_castle_walls"):
		sequence = MAP_AFTER_CASTLE_WALLS_DIALOGUE
		flag_id = "after_castle_walls"

	elif not _has_seen_map_dialogue("intro"):
		sequence = MAP_INTRO_DIALOGUE
		flag_id = "intro"

	if sequence == null or flag_id.is_empty():
		return

	await _play_dialogue_sequence(sequence)
	_mark_map_dialogue_seen(flag_id)


func _play_dialogue_sequence(sequence: DialogueSequenceData) -> void:
	if sequence == null:
		return

	if DIALOGUE_OVERLAY_SCENE == null:
		push_warning("LevelSelectMap: DIALOGUE_OVERLAY_SCENE is null.")
		return

	var overlay: DialogueOverlay = DIALOGUE_OVERLAY_SCENE.instantiate() as DialogueOverlay

	if overlay == null:
		push_warning("LevelSelectMap: Dialogue overlay scene does not use DialogueOverlay.")
		return

	dialogue_is_playing = true
	is_dragging_map = false

	add_child(overlay)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	if overlay.has_signal("dialogue_sfx_requested"):
		if not overlay.dialogue_sfx_requested.is_connected(_on_dialogue_sfx_requested):
			overlay.dialogue_sfx_requested.connect(_on_dialogue_sfx_requested)

	overlay.start(sequence)

	await overlay.dialogue_finished

	dialogue_is_playing = false


func _on_dialogue_sfx_requested(sfx_id: String) -> void:
	var clean_sfx_id: String = sfx_id.strip_edges()

	print("LevelSelectMap Dialogue SFX requested: ", clean_sfx_id)

	if clean_sfx_id.is_empty():
		return

	var sfx_player: AudioStreamPlayer = find_child(clean_sfx_id, true, false) as AudioStreamPlayer

	if sfx_player == null:
		push_warning("LevelSelectMap: Dialogue SFX not found: " + clean_sfx_id)
		return

	print("LevelSelectMap playing Dialogue SFX: ", sfx_player.name)
	sfx_player.play()


func _has_seen_map_dialogue(flag_id: String) -> bool:
	if CampaignProgress == null:
		return false

	var meta_key: String = _get_map_dialogue_meta_key(flag_id)

	if CampaignProgress.has_meta(meta_key):
		return bool(CampaignProgress.get_meta(meta_key))

	return false


func _mark_map_dialogue_seen(flag_id: String) -> void:
	if CampaignProgress == null:
		return

	CampaignProgress.set_meta(_get_map_dialogue_meta_key(flag_id), true)


func _get_map_dialogue_meta_key(flag_id: String) -> String:
	return "map_dialogue_seen_%s" % flag_id


func _on_level_button_pressed(level_data: CampaignLevelData) -> void:
	if dialogue_is_playing:
		return

	if level_data == null:
		return

	if not CampaignProgress.is_level_unlocked(level_data):
		return

	GameSession.setup_campaign(level_data)

	selection_finished.emit()


func _on_back_pressed() -> void:
	if dialogue_is_playing:
		return

	back_requested.emit()
