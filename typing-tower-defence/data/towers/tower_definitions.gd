extends RefCounted

const TOWER_TYPES := {
	"arrow": {
		"display_name": "Arrow Tower",
		"description": "Rapid physical attacks with strong sustained damage.",
		"icon": preload("uid://fw68dporkcpi"),
		"levels": [
			{
				"cost": 60,
				"charge_required": 3,
				"duration": 5.0,
				"cooldown": 4.0,
				"effect": "rapid_fire",
				"damage": 4,
				"attack_interval": 0.45,
				"projectile_speed": 420.0,
				"range": 220.0
			},
			{
				"cost": 95,
				"charge_required": 3,
				"duration": 5.0,
				"cooldown": 4.0,
				"effect": "rapid_fire",
				"damage": 5,
				"attack_interval": 0.40,
				"projectile_speed": 450.0,
				"range": 230.0
			},
			{
				"cost": 140,
				"charge_required": 3,
				"duration": 5.0,
				"cooldown": 4.0,
				"effect": "rapid_fire",
				"damage": 6,
				"attack_interval": 0.36,
				"projectile_speed": 480.0,
				"range": 240.0
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
				"charge_required": 5,
				"duration": 0.6,
				"cooldown": 4.5,
				"effect": "lightning_burst",
				"damage": 18,
				"targets_per_burst": 5,
				"range": 99999.0
			},
			{
				"cost": 115,
				"charge_required": 5,
				"duration": 0.6,
				"cooldown": 4.2,
				"effect": "lightning_burst",
				"damage": 24,
				"targets_per_burst": 6,
				"range": 99999.0
			},
			{
				"cost": 165,
				"charge_required": 5,
				"duration": 0.6,
				"cooldown": 3.8,
				"effect": "lightning_burst",
				"damage": 30,
				"targets_per_burst": 7,
				"range": 99999.0
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
