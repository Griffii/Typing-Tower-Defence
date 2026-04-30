# res://data/player/customization_definitions.gd
class_name CustomizationDefinitions

const ITEM_ICON_BASE_PATH: String = "res://assets/images/player/icons/"

const ITEMS: Dictionary = {
	"body_color": {
		"skin_01": {
			"display_name": "Skin 1",
			"color": Color("#ffffff"),
			"unlock_hint": "",
			"bonuses": {}
		},
		"skin_02": {
			"display_name": "Skin 2",
			"color": Color("#f2c7a5"),
			"unlock_hint": "",
			"bonuses": {}
		},
		"skin_03": {
			"display_name": "Skin 3",
			"color": Color("#d99a6c"),
			"unlock_hint": "",
			"bonuses": {}
		},
		"skin_04": {
			"display_name": "Skin 4",
			"color": Color("#9b5f3f"),
			"unlock_hint": "",
			"bonuses": {}
		},
		"skin_05": {
			"display_name": "Skin 5",
			"color": Color("#5c3828"),
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"undies": {
		"boy_undies": {
			"display_name": "Boy Undies",
			"animation_id": "boy_undies",
			"unlock_hint": "",
			"bonuses": {}
		},
		"girl_undies": {
			"display_name": "Girl Undies",
			"animation_id": "girl_undies",
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"clothes": {
		"clothes_01": {
			"display_name": "Blue Wizard Robe",
			"animation_id": "clothes_01",
			"unlock_hint": "",
			"bonuses": {}
		},
		"clothes_02": {
			"display_name": "Red Wizard Robe",
			"animation_id": "clothes_02",
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"hair": {
		"hair_01": {
			"display_name": "Hair 1",
			"animation_id": "hair_01",
			"unlock_hint": "",
			"bonuses": {}
		},
		"hair_02": {
			"display_name": "Hair 2",
			"animation_id": "hair_02",
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"hat": {
		"hat_01": {
			"display_name": "Blue Wizard Hat",
			"animation_id": "hat_01",
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"wand": {
		"wand_01": {
			"display_name": "Beginner Wand",
			"animation_id": "wand_01",
			"unlock_hint": "",
			"bonuses": {}
		}
	}
}


static func has_slot(slot_id: String) -> bool:
	return ITEMS.has(slot_id)


static func has_item(slot_id: String, item_id: String) -> bool:
	if not ITEMS.has(slot_id):
		return false

	return ITEMS[slot_id].has(item_id)


static func get_item_data(slot_id: String, item_id: String) -> Dictionary:
	if not has_item(slot_id, item_id):
		return {}

	var data: Dictionary = ITEMS[slot_id][item_id].duplicate(true)

	if not data.has("item_icon"):
		var auto_icon: Texture2D = get_auto_item_icon(item_id)
		if auto_icon != null:
			data["item_icon"] = auto_icon

	return data


static func get_items_for_slot(slot_id: String) -> Dictionary:
	if not ITEMS.has(slot_id):
		return {}

	return ITEMS[slot_id].duplicate(true)


static func get_auto_item_icon(item_id: String) -> Texture2D:
	var png_path: String = ITEM_ICON_BASE_PATH + item_id + ".png"
	var webp_path: String = ITEM_ICON_BASE_PATH + item_id + ".webp"

	if ResourceLoader.exists(png_path):
		return load(png_path)

	if ResourceLoader.exists(webp_path):
		return load(webp_path)

	return null


static func get_body_color(item_id: String) -> Color:
	var data: Dictionary = get_item_data("body_color", item_id)
	return data.get("color", Color.WHITE)
