## Data for various portal/tower types, per level
extends RefCounted

const TOWER_TYPES := {
	"basic_magic_turret": {
		"display_name": "Magic Turret",
		"description": "A basic magic crystal that fires small beams at the nearest enemy.",
		"icon": preload("uid://fw68dporkcpi"),
		"levels": [
			{
				"cost": 60,
				"effect": "magic_beam",
				"damage": 6,
				"attack_interval": .8,
				"projectile_speed": 420.0,
				"range": 220.0,
				"time_added_per_word": 1.0
			},
			{
				"cost": 95,
				"effect": "magic_beam",
				"damage": 8,
				"attack_interval": 0.7,
				"projectile_speed": 450.0,
				"range": 230.0,
				"time_added_per_word": 2.0
			},
			{
				"cost": 140,
				"effect": "magic_beam",
				"damage": 10,
				"attack_interval": 0.6,
				"projectile_speed": 480.0,
				"range": 240.0,
				"time_added_per_word": 3.0
			}
		]
	},

	"lightning": {
		"display_name": "Lightning Tower",
		"description": "Charges a powerful burst that strikes multiple enemies instantly.",
		"icon": preload("uid://ds5mibip8yqge"),
		"levels": [
			{
				"cost": 75,
				"effect": "lightning_burst",
				"damage": 8,
				"attack_interval": 2.0,
				"targets_per_burst": 5,
				"range": 220.0,
				"time_added_per_word": 1.0
			},
			{
				"cost": 115,
				"effect": "lightning_burst",
				"damage": 10,
				"attack_interval": 1.5,
				"targets_per_burst": 6,
				"range": 230.0,
				"time_added_per_word": 2.0
			},
			{
				"cost": 165,
				"effect": "lightning_burst",
				"damage": 12,
				"attack_interval": 1.0,
				"targets_per_burst": 7,
				"range": 240.0,
				"time_added_per_word": 3.0
			}
		]
	}
}


static func has_tower_type(tower_type: String) -> bool:
	return TOWER_TYPES.has(tower_type)


static func get_tower_data(tower_type: String) -> Dictionary:
	if not TOWER_TYPES.has(tower_type):
		return {}
	return TOWER_TYPES[tower_type]


static func get_display_name(tower_type: String) -> String:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return str(tower_data.get("display_name", tower_type))


static func get_icon(tower_type: String) -> Texture2D:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return tower_data.get("icon", null)


static func get_levels(tower_type: String) -> Array:
	var tower_data: Dictionary = get_tower_data(tower_type)
	var levels: Variant = tower_data.get("levels", [])
	if typeof(levels) == TYPE_ARRAY:
		return levels
	return []


static func get_max_level(tower_type: String) -> int:
	return get_levels(tower_type).size()


static func get_level_data(tower_type: String, level: int) -> Dictionary:
	var levels: Array = get_levels(tower_type)

	if level <= 0:
		return {}

	var index := level - 1
	if index < 0 or index >= levels.size():
		return {}

	var level_data: Variant = levels[index]
	if typeof(level_data) == TYPE_DICTIONARY:
		return level_data

	return {}


static func get_next_level_data(tower_type: String, current_level: int) -> Dictionary:
	return get_level_data(tower_type, current_level + 1)


static func get_next_cost(tower_type: String, current_level: int) -> int:
	var next_level_data: Dictionary = get_next_level_data(tower_type, current_level)
	if next_level_data.is_empty():
		return -1
	return int(next_level_data.get("cost", -1))
