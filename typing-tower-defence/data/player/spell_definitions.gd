# res://data/player/spell_definitions.gd


const SPELLS: Dictionary = {
	"fireball_01": {
		"display_name": "Fireball",
		"projectile_scene": preload("res://scenes/game/projectiles/fireball_projectile_01.tscn"),
		"base_damage": 10
	},
	"fireball_02": {
		"display_name": "Alt Fireball",
		"projectile_scene": preload("res://scenes/game/projectiles/fireball_projectile_02.tscn"),
		"base_damage": 10
	}
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


static func get_spell_data(spell_id: String) -> Dictionary:
	if not SPELLS.has(spell_id):
		return {}

	return SPELLS[spell_id].duplicate(true)
