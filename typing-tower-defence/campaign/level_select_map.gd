# res://scripts/menus/level_select_map.gd
extends Control

signal selection_finished
signal back_requested

const CampaignLevelRegistry = preload("uid://c82ft73lvun6v") ##"res://campaign/campaign_level_registry.gd"

@onready var back_button: Button = %BackButton

@onready var castle_walls_button: Button = %CastleWallsButton
@onready var grasslands_button: Button = %GrasslandsButton
@onready var seaside_farm_button: Button = %SeasideFarmButton

var buttons_by_level_id: Dictionary = {}


func _ready() -> void:
	_cache_buttons()
	_connect_signals()
	_refresh_buttons()


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
		if not CampaignProgress.campaign_progress_changed.is_connected(_refresh_buttons):
			CampaignProgress.campaign_progress_changed.connect(_refresh_buttons)

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
	
		print(
		"[LevelSelectMap] ",
		level_data.level_id,
		" required=",
		level_data.required_level_id,
		" completed=",
		CampaignProgress.is_level_completed(level_data.required_level_id),
		" unlocked=",
		CampaignProgress.is_level_unlocked(level_data)
	)


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


func _on_level_button_pressed(level_data: CampaignLevelData) -> void:
	if level_data == null:
		return

	if not CampaignProgress.is_level_unlocked(level_data):
		return

	GameSession.setup_campaign(level_data)

	selection_finished.emit()


func _on_back_pressed() -> void:
	back_requested.emit()
