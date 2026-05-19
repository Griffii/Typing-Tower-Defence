## Data for tower types.
## Towers are passive once placed.
## No charging, upkeep, or direct tower levels.
##
## Compatibility note:
## get_level_data(), get_max_level(), get_next_cost(), etc. still exist
## because CombatManager and build/shop code still call them.

extends RefCounted

const TOWER_TYPES := {
	"basic_magic_turret": {
		"scene": preload("uid://ciwqq06h6kavx"),
		"display_name": "Basic Magic Turret",
		"description": "Shoots magic fireballs at enemies.",
		"icon": preload("uid://cagkyx3rciwg6"),
		"cost": 60,
		"tower_role": "damage",
		"effect": "single_target_projectile",
		"damage": 4,
		"attack_interval": 1.5,
		"projectile_speed": 480.0,
		"range": 200.0,
		"targeting": "nearest",
		"can_receive_damage_upgrades": true
	},

	"chain_lightning": {
		"scene": preload("uid://y4a2j88o08jf"),
		"display_name": "Chain Lightning Tower",
		"description": "Fires lightning that hits multiple enemies.",
		"icon": preload("uid://ds5mibip8yqge"),
		"cost": 90,
		"tower_role": "damage",
		"effect": "chain_lightning",
		"damage": 5,
		"attack_interval": 3.0,
		"projectile_speed": 9999.0,
		"range": 200.0,
		"chain_range": 100.0,
		"max_chain_targets": 4,
		"targeting": "nearest",
		"can_receive_damage_upgrades": true
	},

	"ice_tower": {
		"scene": preload("uid://ciwqq06h6kavx"),
		"display_name": "Ice Tower",
		"description": "Creates an icy field to slow enemies.",
		"icon": preload("uid://bjkiyugprlyuf"),
		"cost": 80,
		"tower_role": "control",
		"effect": "area_slow",
		"range": 180.0,
		"slow_multiplier": 0.55,
		"slow_refresh_interval": 0.15,
		"slow_duration": 0.25,
		"damage": 0,
		"can_receive_damage_upgrades": false
	}
}


static func has_tower_type(tower_type: String) -> bool:
	return TOWER_TYPES.has(tower_type)


static func get_tower_data(tower_type: String) -> Dictionary:
	if not TOWER_TYPES.has(tower_type):
		return {}

	return TOWER_TYPES[tower_type].duplicate(true)


static func get_all_tower_types() -> Array[String]:
	var tower_types: Array[String] = []

	for tower_type: String in TOWER_TYPES.keys():
		tower_types.append(tower_type)

	return tower_types


static func filter_valid_tower_types(tower_types: Array) -> Array[String]:
	var valid_types: Array[String] = []

	for tower_type in tower_types:
		var tower_type_string: String = str(tower_type)
		if has_tower_type(tower_type_string):
			valid_types.append(tower_type_string)

	return valid_types


static func get_display_name(tower_type: String) -> String:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return str(tower_data.get("display_name", tower_type))


static func get_description(tower_type: String) -> String:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return str(tower_data.get("description", ""))


static func get_tower_scene(tower_type: String) -> PackedScene:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return tower_data.get("scene", null)


static func get_icon(tower_type: String) -> Texture2D:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return tower_data.get("icon", null)


static func get_cost(tower_type: String) -> int:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return int(tower_data.get("cost", -1))


static func get_tower_role(tower_type: String) -> String:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return str(tower_data.get("tower_role", ""))


static func get_effect(tower_type: String) -> String:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return str(tower_data.get("effect", ""))


static func get_damage(tower_type: String) -> int:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return int(tower_data.get("damage", 0))


static func get_attack_interval(tower_type: String) -> float:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return float(tower_data.get("attack_interval", 1.0))


static func get_projectile_speed(tower_type: String) -> float:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return float(tower_data.get("projectile_speed", 0.0))


static func get_range(tower_type: String) -> float:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return float(tower_data.get("range", 0.0))


static func get_targeting(tower_type: String) -> String:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return str(tower_data.get("targeting", "nearest"))


static func get_chain_range(tower_type: String) -> float:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return float(tower_data.get("chain_range", 0.0))


static func get_max_chain_targets(tower_type: String) -> int:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return int(tower_data.get("max_chain_targets", 1))


static func get_slow_multiplier(tower_type: String) -> float:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return float(tower_data.get("slow_multiplier", 1.0))


static func get_slow_refresh_interval(tower_type: String) -> float:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return float(tower_data.get("slow_refresh_interval", 0.15))


static func get_slow_duration(tower_type: String) -> float:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return float(tower_data.get("slow_duration", 0.25))


static func can_receive_damage_upgrades(tower_type: String) -> bool:
	var tower_data: Dictionary = get_tower_data(tower_type)
	return bool(tower_data.get("can_receive_damage_upgrades", false))


# ---------------------------
# Compatibility API
# ---------------------------

static func get_levels(tower_type: String) -> Array:
	var tower_data: Dictionary = get_tower_data(tower_type)

	if tower_data.is_empty():
		return []

	return [tower_data]


static func get_max_level(tower_type: String) -> int:
	if not has_tower_type(tower_type):
		return 0

	return 1


static func get_level_data(tower_type: String, level: int) -> Dictionary:
	if level != 1:
		return {}

	return get_tower_data(tower_type)


static func get_next_level_data(tower_type: String, current_level: int) -> Dictionary:
	if current_level >= 1:
		return {}

	return get_level_data(tower_type, 1)


static func get_next_cost(tower_type: String, current_level: int) -> int:
	if current_level >= 1:
		return -1

	return get_cost(tower_type)
