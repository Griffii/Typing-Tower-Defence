extends RefCounted


func get_wave_definitions() -> Array:
	return [
		{
			"spawn_interval": 1.2,
			"wave_word_list_ids": ["medium"],
			"enemies": [
				_enemy("slime", ["medium"]),
				_enemy("slime", ["medium"]),
				_enemy("slime", ["medium"]),
				_enemy("slime", ["easy", "medium"]),
				_enemy("slime", ["medium"]),
				_enemy("slime", ["medium"]),
			],
		},
		{
			"spawn_interval": 1.1,
			"wave_word_list_ids": ["medium", "hard"],
			"enemies": [
				_enemy("slime", ["medium"]),
				_enemy("slime", ["medium"]),
				_enemy("slime", ["hard"]),
				_enemy("slime", ["medium"]),
				_enemy("boss_slime", ["medium"]),
			],
		},
		{
			"spawn_interval": 1.0,
			"wave_word_list_ids": ["hard"],
			"enemies": [
				_enemy("slime", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("slime", ["medium", "hard"]),
				_enemy("boss_slime", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("slime", ["hard"]),
			],
		},
		{
			"spawn_interval": 0.9,
			"wave_word_list_ids": ["hard"],
			"enemies": [
				_enemy("slime", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("boss_slime", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("boss_slime", ["medium", "hard"]),
				_enemy("slime", ["hard"]),
			],
		},
		{
			"spawn_interval": 0.8,
			"wave_word_list_ids": ["hard"],
			"enemies": [
				_enemy("slime", ["hard"]),
				_enemy("boss_slime", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("boss_slime", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("boss_slime", ["hard"]),
			],
		},
	]


func _enemy(enemy_type: String, word_list_ids: Array[String]) -> Dictionary:
	return {
		"enemy_type": enemy_type,
		"word_list_ids": word_list_ids,
	}
