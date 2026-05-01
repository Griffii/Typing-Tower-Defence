# res://scripts/autoloads/player_loadout.gd
extends Node

### UNLOCK ITEMS FROM ANYWHERE WITH THIS SYNTAX
#
# PlayerLoadout.unlock_item("hat", "flower_hat")
# PlayerLoadout.unlock_item("wand", "glass_wand")
# PlayerLoadout.unlock_item("body_color", "skin_purple")
#
##########################################################

signal loadout_changed(loadout: Dictionary)
signal item_unlocked(slot_id: String, item_id: String)

var player_name: String = "Spellicus"

var equipped_loadout: Dictionary = {
	"body": "body_01",
	"body_color": "skin_01",

	"undies": "boy_undies",
	"undies_color": "white",

	"clothes": "robe_white",
	"clothes_color": "white",

	"hair": "hair_01",
	"hair_color": "brown",

	"hat": "wizard_hat",
	"hat_color": "white",

	"wand": "oak_staff",
	"wand_color": "default",

	"spell": "fireball_01"
}

var unlocked_items: Dictionary = {
	"body": ["body_01"],
	"body_color": ["skin_01", "skin_02", "skin_03", "skin_04", "skin_05"],

	"undies": ["boy_undies", "girl_undies","leotard_undies"],
	"undies_color": ["white", "beige", "black", "red", "blue", "green"],

	"clothes": ["robe_white"],
	"clothes_color": ["white", "blue", "red", "green", "gray", "black"],

	"hair": ["hair_01", "hair_02"],
	"hair_color": [
		"white",
		"blonde",
		"brown",
		"dark_brown",
		"black",
		"gray",
		"red",
		"pink",
		"blue",
		"purple"
	],

	"hat": ["wizard_hat","flower_hat"],
	"hat_color": ["white", "blue", "red", "green", "gray", "black", "default"],


	"wand": ["oak_staff", "glass_staff"],
	"wand_color": ["default"],

	"spell": ["fireball_01", "fireball_02"]
}


func get_loadout() -> Dictionary:
	return equipped_loadout.duplicate(true)


func get_equipped(slot_id: String) -> String:
	return str(equipped_loadout.get(slot_id, ""))

func get_player_name() -> String:
	var cleaned_name := player_name.strip_edges()

	if cleaned_name.is_empty():
		return "Spellicus"

	return cleaned_name


func set_player_name(new_name: String) -> void:
	var cleaned_name := new_name.strip_edges()

	if cleaned_name.is_empty():
		cleaned_name = "Spellicus"

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
		return

	var file := FileAccess.open("user://player_loadout.json", FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	if parsed.has("player_name"):
		player_name = str(parsed["player_name"]).strip_edges()

		if player_name.is_empty():
			player_name = "Spellicus"

	if parsed.has("unlocked_items") and typeof(parsed["unlocked_items"]) == TYPE_DICTIONARY:
		for slot_id in parsed["unlocked_items"].keys():
			unlocked_items[str(slot_id)] = parsed["unlocked_items"][slot_id]

	var loaded_equipped: Dictionary = parsed

	if parsed.has("equipped_loadout") and typeof(parsed["equipped_loadout"]) == TYPE_DICTIONARY:
		loaded_equipped = parsed["equipped_loadout"]

	for key in equipped_loadout.keys():
		if loaded_equipped.has(key):
			var loaded_item_id: String = str(loaded_equipped[key])

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
			return "white"
		"hair":
			return "hair_01"
		"hair_color":
			return "brown"
		"hat":
			return "wizard_hat"
		"hat_color":
			return "white"
		"wand":
			return "oak_staff"
		"wand_color":
			return "default"
		"spell":
			return "fireball_01"
		_:
			return ""


func _is_required_slot(slot_id: String) -> bool:
	return slot_id == "body" or slot_id == "body_color" or slot_id == "spell"
