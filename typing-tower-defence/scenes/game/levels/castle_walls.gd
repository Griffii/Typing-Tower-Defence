extends BattlefieldLevel

func _ready() -> void:
	enemy_scale = Vector2(0.65, 0.65)

	allowed_tower_types = ["basic_magic_turret"]

	tower_scene_map = {
		"slot_01": DEFAULT_TOWER_SCENE,
		"slot_02": DEFAULT_TOWER_SCENE,
		"slot_03": DEFAULT_TOWER_SCENE,
	}
