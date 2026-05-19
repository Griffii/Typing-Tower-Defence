# res://scripts/autoloads/player_loadout.gd
extends Node

### UNLOCK ITEMS FROM ANYWHERE WITH THIS SYNTAX ##########
#
# PlayerLoadout.unlock_item("hat", "wizard_hat")
# PlayerLoadout.unlock_item("staff", "glass_staff")
# PlayerLoadout.unlock_item("body_color", "skin_purple")
#
##########################################################

signal loadout_changed(loadout: Dictionary)
signal item_unlocked(slot_id: String, item_id: String)

const DEFAULT_PLAYER_NAME := "Spellicus"

var player_name: String = DEFAULT_PLAYER_NAME

var equipped_loadout: Dictionary = {
	"body": "body_01",
	"body_color": "skin_01",

	"eyes": "eyes_01",
	"eyes_color": "eye_blue",

	"clothes": "wizard_robes",
	"clothes_color": "black",

	"hair": "messy_short_hair",
	"hair_color": "black",

	"hat": "none",
	"hat_color": "black",

	"staff": "oak_staff",

	"spell": "fireball_01"
}

var unlocked_items: Dictionary = {
	"body": ["body_01"],
	"body_color": [
		"skin_01",
		"skin_02",
		"skin_03",
		"skin_04",
		"skin_05",
		"skin_06",
		"skin_red",
		"skin_purple",
		"skin_pink"
	],

	"eyes": ["eyes_01"],
	"eyes_color": [
		"eye_black",
		"eye_blue",
		"eye_green",
		"eye_brown",
		"eye_gold",
		"eye_purple",
		"eye_red"
	],

	"clothes": ["wizard_robes","elf_mage"],
	"clothes_color": [
		"default",
		"blue",
		"red",
		"green",
		"gray",
		"black",
		"purple",
		"pink"
	],

	"hair": ["messy_short_hair","academic_short_hair","long_hair","elf_mage_hair"],
	"hair_color": [
		"default",
		"blonde",
		"brown",
		"dark_brown",
		"black",
		"red_hair",
		"blue",
		"purple",
		"pink"
	],

	"hat": ["wizard_hat"],
	"hat_color": [
		"default",
		"blue",
		"red",
		"green",
		"gray",
		"black",
		"purple",
		"pink"
	],

	"staff": [
		"oak_staff",
		"glass_staff",
		"elf_mage_staff"
	],

	"spell": [
		"fireball_01",
		"fireball_02",
		"fireball_03",
		"fireball_04"
	]
}


func get_loadout() -> Dictionary:
	return equipped_loadout.duplicate(true)


func get_equipped(slot_id: String) -> String:
	return str(equipped_loadout.get(slot_id, ""))


func get_player_name() -> String:
	var cleaned_name := player_name.strip_edges()

	if cleaned_name.is_empty():
		return DEFAULT_PLAYER_NAME

	return cleaned_name


func set_player_name(new_name: String) -> void:
	var cleaned_name := new_name.strip_edges()

	if cleaned_name.is_empty():
		cleaned_name = DEFAULT_PLAYER_NAME

	player_name = cleaned_name
	save_loadout()


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

	item_unlocked.emit(slot_id, item_id)
	loadout_changed.emit(get_loadout())
	save_loadout()


func save_loadout() -> void:
	var save_data := {
		"player_name": player_name,
		"equipped_loadout": equipped_loadout,
		"unlocked_items": unlocked_items
	}

	var file := FileAccess.open("user://player_loadout.json", FileAccess.WRITE)

	if file == null:
		return

	file.store_string(JSON.stringify(save_data))


func load_loadout() -> void:
	if not FileAccess.file_exists("user://player_loadout.json"):
		_validate_loaded_loadout()
		return

	var file := FileAccess.open("user://player_loadout.json", FileAccess.READ)

	if file == null:
		_validate_loaded_loadout()
		return

	var parsed = JSON.parse_string(file.get_as_text())

	if typeof(parsed) != TYPE_DICTIONARY:
		_validate_loaded_loadout()
		return

	if parsed.has("player_name"):
		player_name = str(parsed["player_name"]).strip_edges()

		if player_name.is_empty():
			player_name = DEFAULT_PLAYER_NAME

	if parsed.has("unlocked_items") and typeof(parsed["unlocked_items"]) == TYPE_DICTIONARY:
		_load_unlocked_items(parsed["unlocked_items"])

	var loaded_equipped: Dictionary = parsed

	if parsed.has("equipped_loadout") and typeof(parsed["equipped_loadout"]) == TYPE_DICTIONARY:
		loaded_equipped = parsed["equipped_loadout"]

	_migrate_old_loadout_keys(loaded_equipped)

	for key in equipped_loadout.keys():
		if loaded_equipped.has(key):
			var loaded_item_id: String = str(loaded_equipped[key])

			if _is_required_slot(key) and (loaded_item_id.is_empty() or loaded_item_id == "none"):
				continue

			equipped_loadout[key] = loaded_item_id

	_validate_loaded_loadout()
	loadout_changed.emit(get_loadout())
	save_loadout()


func _load_unlocked_items(loaded_unlocked_items: Dictionary) -> void:
	for slot_id_variant in loaded_unlocked_items.keys():
		var slot_id := str(slot_id_variant)

		if _is_removed_slot(slot_id):
			continue

		var target_slot_id := _migrate_slot_id(slot_id)

		if target_slot_id.is_empty():
			continue

		if not unlocked_items.has(target_slot_id):
			unlocked_items[target_slot_id] = []

		var loaded_array = loaded_unlocked_items[slot_id_variant]

		if typeof(loaded_array) != TYPE_ARRAY:
			continue

		for item_id_variant in loaded_array:
			var item_id := str(item_id_variant)

			if item_id.is_empty():
				continue

			if not unlocked_items[target_slot_id].has(item_id):
				unlocked_items[target_slot_id].append(item_id)


func _migrate_old_loadout_keys(loaded_equipped: Dictionary) -> void:
	if loaded_equipped.has("wand") and not loaded_equipped.has("staff"):
		loaded_equipped["staff"] = str(loaded_equipped["wand"])


func _migrate_slot_id(slot_id: String) -> String:
	match slot_id:
		"wand":
			return "staff"

		_:
			return slot_id


func _is_removed_slot(slot_id: String) -> bool:
	return (
		slot_id == "undies"
		or slot_id == "undies_color"
		or slot_id == "wand_color"
	)


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

		"eyes":
			return "eyes_01"
		
		"eyes_color":
			return "eye_blue"

		"clothes":
			return "elf_mage"
		"clothes_color":
			return "default"

		"hair":
			return "elf_mage_hair"

		"hair_color":
			return "default"

		"hat":
			return "wizard_hat"

		"hat_color":
			return "blue"

		"staff":
			return "oak_staff"

		"spell":
			return "fireball_01"

		_:
			return ""


func _is_required_slot(slot_id: String) -> bool:
	return (
		slot_id == "body"
		or slot_id == "body_color"
		or slot_id == "eyes"
		or slot_id == "clothes"
		or slot_id == "hair"
		or slot_id == "hair_color"
		or slot_id == "spell"
	)
