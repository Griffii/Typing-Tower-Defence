extends BattlefieldLevel

func _ready() -> void:
	enemy_scale = Vector2(0.65, 0.65)

	allowed_tower_types = [
		"basic_magic_turret",
		"chain_lightning",
		"ice_tower"
	]
