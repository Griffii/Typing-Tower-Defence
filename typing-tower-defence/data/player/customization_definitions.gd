# res://data/player/customization_definitions.gd


const ITEMS: Dictionary = {
	"body": {
		"body_01": {
			"display_name": "Body",
			"texture": preload("res://assets/images/player/bodies/body_01.png"),
			"available_dyes": ["skin_01", "skin_02", "skin_03", "skin_04", "skin_05"],
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"body_color": {
		"skin_01": {"display_name": "Skin 1", "color": Color("#ffffff"), "unlock_hint": "", "bonuses": {}},
		"skin_02": {"display_name": "Skin 2", "color": Color("#f2c7a5"), "unlock_hint": "", "bonuses": {}},
		"skin_03": {"display_name": "Skin 3", "color": Color("#d99a6c"), "unlock_hint": "", "bonuses": {}},
		"skin_04": {"display_name": "Skin 4", "color": Color("#9b5f3f"), "unlock_hint": "", "bonuses": {}},
		"skin_05": {"display_name": "Skin 5", "color": Color("#5c3828"), "unlock_hint": "", "bonuses": {}}
	},

	"undies": {
		"boy_undies": {
			"display_name": "Boy Undies",
			"texture": preload("res://assets/images/player/undies/boy_undies.png"),
			"available_dyes": ["white", "gray"],
			"unlock_hint": "",
			"bonuses": {}
		},
		"girl_undies": {
			"display_name": "Girl Undies",
			"texture": preload("res://assets/images/player/undies/girl_undies.png"),
			"available_dyes": ["white", "gray"],
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"clothes": {
		"robe_white": {
			"display_name": "Wizard Robe",
			"texture": preload("res://assets/images/player/clothes/robe_white.png"),
			"available_dyes": ["blue", "red", "green", "white", "gray", "black"],
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"hair": {
		"hair_01": {
			"display_name": "Hair 1",
			"texture": preload("res://assets/images/player/hair/hair_01.png"),
			"available_dyes": ["brown", "black", "blonde"],
			"unlock_hint": "",
			"bonuses": {}
		},
		"hair_02": {
			"display_name": "Hair 2",
			"texture": preload("res://assets/images/player/hair/hair_02.png"),
			"available_dyes": ["brown", "black", "blonde"],
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"hat": {
		"wizard_hat": {
			"display_name": "Wizard Hat",
			"texture": preload("res://assets/images/player/hats/wizard_hat.png"),
			"available_dyes": ["blue", "red", "green", "white", "gray", "black"],
			"unlock_hint": "",
			"bonuses": {}
		}
	},

	"wand": {
		"wand_01": {
			"display_name": "Beginner Staff",
			"texture": preload("res://assets/images/player/wands/oak_staff.png"),
			"available_dyes": ["brown", "black", "white", "gray"],
			"unlock_hint": "",
			"bonuses": {}
		}
	}
}


const DYES: Dictionary = {
	"white": {"display_name": "White", "color": Color("#ffffff"), "unlock_hint": ""},
	"gray": {"display_name": "Gray", "color": Color("#aaaaaa"), "unlock_hint": ""},
	"blue": {"display_name": "Blue", "color": Color("#4f7cff"), "unlock_hint": ""},
	"red": {"display_name": "Red", "color": Color("#d94b4b"), "unlock_hint": ""},
	"green": {"display_name": "Green", "color": Color("#5bbf73"), "unlock_hint": ""},
	"brown": {"display_name": "Brown", "color": Color("#7a4a2a"), "unlock_hint": ""},
	"black": {"display_name": "Black", "color": Color("#202020"), "unlock_hint": ""},
	"blonde": {"display_name": "Blonde", "color": Color("#e8c76f"), "unlock_hint": ""}
}


static func has_item(slot_id: String, item_id: String) -> bool:
	return ITEMS.has(slot_id) and ITEMS[slot_id].has(item_id)


static func get_item_data(slot_id: String, item_id: String) -> Dictionary:
	if not has_item(slot_id, item_id):
		return {}

	var data: Dictionary = ITEMS[slot_id][item_id].duplicate(true)

	if data.has("texture") and not data.has("item_icon"):
		data["item_icon"] = data["texture"]

	return data


static func get_items_for_slot(slot_id: String) -> Dictionary:
	if not ITEMS.has(slot_id):
		return {}

	return ITEMS[slot_id].duplicate(true)


static func get_texture(slot_id: String, item_id: String) -> Texture2D:
	var data: Dictionary = get_item_data(slot_id, item_id)
	return data.get("texture", null)


static func get_body_color(color_id: String) -> Color:
	var data: Dictionary = get_item_data("body_color", color_id)
	return data.get("color", Color.WHITE)


static func get_dye_data(dye_id: String) -> Dictionary:
	if not DYES.has(dye_id):
		return {}

	var data: Dictionary = DYES[dye_id].duplicate(true)
	data["bonuses"] = {}
	return data


static func get_dye_color(dye_id: String) -> Color:
	var data: Dictionary = get_dye_data(dye_id)
	return data.get("color", Color.WHITE)


static func get_dye_display_name(dye_id: String) -> String:
	var data: Dictionary = get_dye_data(dye_id)
	return str(data.get("display_name", dye_id))


static func get_bonuses(slot_id: String, item_id: String) -> Dictionary:
	var data: Dictionary = get_item_data(slot_id, item_id)
	return data.get("bonuses", {}).duplicate(true)


static func get_available_dyes_for_item(slot_id: String, item_id: String) -> Array[String]:
	var result: Array[String] = []
	var data: Dictionary = get_item_data(slot_id, item_id)

	var dyes: Array = data.get("available_dyes", [])
	for dye_id_variant in dyes:
		result.append(str(dye_id_variant))

	return result
