extends BattlefieldLevel

func _ready() -> void:
	enemy_scale = Vector2(0.75, 0.75)

	allowed_tower_types = ["arrow"]

	tower_scene_map = {
		"slot_01": DEFAULT_TOWER_SCENE,
		"slot_02": DEFAULT_TOWER_SCENE,
	}
