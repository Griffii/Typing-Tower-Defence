extends BattlefieldLevel

func _ready() -> void:
	enemy_scale = Vector2(0.7, 0.7)
	enemy_speed_multiplier = 0.7

	allowed_tower_types = [
		"basic_magic_turret",
		"chain_lightning",
		"ice_tower"
	]
