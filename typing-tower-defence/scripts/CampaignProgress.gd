# res://scripts/autoloads/campaign_progress.gd
extends Node

signal campaign_progress_changed

var completed_levels: Dictionary = {}

var upgrade_levels: Dictionary = {
	"word_damage": 0,
	"special_damage": 0,
	"special_meter_gain": 0,
	"gold_gain": 0,
}


func _ready() -> void:
	reset_campaign_progress()


func is_level_completed(level_id: String) -> bool:
	return bool(completed_levels.get(level_id, false))


func is_level_unlocked(level_data: CampaignLevelData) -> bool:
	if level_data == null:
		return false

	if level_data.required_level_id.is_empty():
		return true

	return is_level_completed(level_data.required_level_id)


func complete_level(level_id: String) -> void:
	if level_id.is_empty():
		return

	completed_levels[level_id] = true
	campaign_progress_changed.emit()


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func set_upgrade_level(upgrade_id: String, level: int) -> void:
	if not upgrade_levels.has(upgrade_id):
		return

	upgrade_levels[upgrade_id] = max(0, level)
	campaign_progress_changed.emit()


func get_upgrade_levels() -> Dictionary:
	return upgrade_levels.duplicate(true)


func set_upgrade_levels(new_levels: Dictionary) -> void:
	for upgrade_id in upgrade_levels.keys():
		upgrade_levels[upgrade_id] = int(new_levels.get(upgrade_id, upgrade_levels[upgrade_id]))

	campaign_progress_changed.emit()


func reset_campaign_progress() -> void:
	completed_levels.clear()

	upgrade_levels = {
		"word_damage": 0,
		"special_damage": 0,
		"special_meter_gain": 0,
		"gold_gain": 0,
	}

	campaign_progress_changed.emit()
