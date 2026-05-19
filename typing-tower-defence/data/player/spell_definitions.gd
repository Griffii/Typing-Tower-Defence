# res://data/player/spell_definitions.gd

const SPELLS: Dictionary = {
	"fireball_01": {
		"display_name": "Fireball",
		"projectile_scene": preload("uid://cm7ifw74sum0m"),
		"base_damage": 10,
		"base_aoe_radius": 96.0,
		"effects": [
			{
				"type": "damage"
			}
		]
	},
	"fireball_02": {
		"display_name": "Alt Fireball",
		"projectile_scene": preload("uid://c6dqkxpumogby"),
		"base_damage": 10,
		"base_aoe_radius": 128.0,
		"effects": [
			{
				"type": "damage"
			}
		]
	},
	"fireball_03": {
		"display_name": "Blue Fireball",
		"projectile_scene": preload("uid://dlda6ydil1wqt"),
		"base_damage": 10,
		"base_aoe_radius": 96.0,
		"effects": [
			{
				"type": "damage"
			}
		]
	},
	"fireball_04": {
		"display_name": "Alt Blue Fireball",
		"projectile_scene": preload("uid://vjmd0616thqm"),
		"base_damage": 10,
		"base_aoe_radius": 96.0,
		"effects": [
			{
				"type": "damage"
			}
		]
	},
}


static func has_spell(spell_id: String) -> bool:
	return SPELLS.has(spell_id)


static func get_display_name(spell_id: String) -> String:
	return str(SPELLS.get(spell_id, {}).get("display_name", spell_id))


static func get_projectile_scene(spell_id: String) -> PackedScene:
	return SPELLS.get(spell_id, {}).get("projectile_scene", null)


static func get_preview_scene(spell_id: String) -> PackedScene:
	return SPELLS.get(spell_id, {}).get("projectile_scene", null)


static func get_base_damage(spell_id: String) -> int:
	return int(SPELLS.get(spell_id, {}).get("base_damage", 10))


static func get_base_aoe_radius(spell_id: String) -> float:
	return float(SPELLS.get(spell_id, {}).get("base_aoe_radius", 0.0))


static func get_effects(spell_id: String) -> Array:
	return SPELLS.get(spell_id, {}).get("effects", []).duplicate(true)


static func get_spell_data(spell_id: String) -> Dictionary:
	if not SPELLS.has(spell_id):
		return {}

	return SPELLS[spell_id].duplicate(true)
