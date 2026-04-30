# res://scripts/autoloads/player_loadout.gd
extends Node

signal loadout_changed(loadout: Dictionary)

var equipped_loadout: Dictionary = {
	"body": "body_01",
	"body_color": "skin_01",

	"undies": "boy_undies",
	"undies_color": "white",

	"clothes": "robe_white",
	"clothes_color": "blue",

	"hair": "hair_01",
	"hair_color": "brown",

	"hat": "wizard_hat",
	"hat_color": "blue",

	"wand": "wand_01",
	"wand_color": "brown",

	"spell": "fireball_01"
}

var unlocked_items: Dictionary = {
	"body": ["body_01"],
	"body_color": ["skin_01", "skin_02", "skin_03", "skin_04", "skin_05"],

	"undies": ["boy_undies", "girl_undies"],
	"undies_color": ["white", "gray"],

	"clothes": ["robe_white"],
	"clothes_color": ["blue", "red", "green", "white", "gray", "black"],

	"hair": ["hair_01", "hair_02"],
	"hair_color": ["brown", "black", "blonde"],

	"hat": ["wizard_hat"],
	"hat_color": ["blue", "red", "green", "white", "gray", "black"],

	"wand": ["wand_01"],
	"wand_color": ["brown", "black", "white", "gray"],

	"spell": ["fireball_01", "fireball_02"]
}


func get_loadout() -> Dictionary:
	return equipped_loadout.duplicate(true)


func get_equipped(slot_id: String) -> String:
	return str(equipped_loadout.get(slot_id, ""))


func is_unlocked(slot_id: String, item_id: String) -> bool:
	if item_id == "none":
		return true

	if not unlocked_items.has(slot_id):
		return false

	return unlocked_items[slot_id].has(item_id)


func equip(slot_id: String, item_id: String) -> bool:
	if not equipped_loadout.has(slot_id):
		return false

	if _is_required_slot(slot_id) and (item_id.is_empty() or item_id == "none"):
		return false

	if item_id != "none" and not is_unlocked(slot_id, item_id):
		return false

	equipped_loadout[slot_id] = item_id
	loadout_changed.emit(get_loadout())
	save_loadout()
	return true


func unlock_item(slot_id: String, item_id: String) -> void:
	if slot_id.is_empty() or item_id.is_empty():
		return

	if not unlocked_items.has(slot_id):
		unlocked_items[slot_id] = []

	if unlocked_items[slot_id].has(item_id):
		return

	unlocked_items[slot_id].append(item_id)


func save_loadout() -> void:
	var file := FileAccess.open("user://player_loadout.json", FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(equipped_loadout))


func load_loadout() -> void:
	if not FileAccess.file_exists("user://player_loadout.json"):
		return

	var file := FileAccess.open("user://player_loadout.json", FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	for key in equipped_loadout.keys():
		if parsed.has(key):
			var loaded_item_id: String = str(parsed[key])

			if _is_required_slot(key) and (loaded_item_id.is_empty() or loaded_item_id == "none"):
				continue

			equipped_loadout[key] = loaded_item_id

	_validate_loaded_loadout()
	loadout_changed.emit(get_loadout())


func _validate_loaded_loadout() -> void:
	for slot_id in equipped_loadout.keys():
		var item_id: String = str(equipped_loadout[slot_id])

		if _is_required_slot(slot_id) and (item_id.is_empty() or item_id == "none"):
			equipped_loadout[slot_id] = _get_default_for_slot(slot_id)
			continue

		if item_id == "none":
			continue

		if not is_unlocked(slot_id, item_id):
			equipped_loadout[slot_id] = _get_default_for_slot(slot_id)


func _get_default_for_slot(slot_id: String) -> String:
	match slot_id:
		"body":
			return "body_01"
		"body_color":
			return "skin_01"
		"undies":
			return "boy_undies"
		"undies_color":
			return "white"
		"clothes":
			return "robe_white"
		"clothes_color":
			return "blue"
		"hair":
			return "hair_01"
		"hair_color":
			return "brown"
		"hat":
			return "wizard_hat"
		"hat_color":
			return "blue"
		"wand":
			return "wand_01"
		"wand_color":
			return "brown"
		"spell":
			return "fireball_01"
		_:
			return ""


func _is_required_slot(slot_id: String) -> bool:
	return slot_id == "body" or slot_id == "body_color" or slot_id == "spell"
