extends BattlefieldLevel

func _ready() -> void:
	allowed_tower_types = [
		"basic_magic_turret",
		"chain_lightning",
		"ice_tower"
	]
