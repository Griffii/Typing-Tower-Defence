extends RefCounted


func get_wave_definitions() -> Array:
	return [
		{
			"spawn_interval": 1.35,
			"wave_word_list_ids": ["easy", "medium"],
			"enemies": [
				_enemy("grunt", ["easy"]),
				_enemy("slime", ["easy"]),
				_enemy("grunt", ["medium"]),
				_enemy("slime", ["medium"]),
				_enemy("scout", ["medium"]),
			],
		},
		{
			"spawn_interval": 1.25,
			"wave_word_list_ids": ["medium"],
			"enemies": [
				_enemy("slime", ["medium"]),
				_enemy("grunt", ["medium"]),
				_enemy("scout", ["medium"]),
				_enemy("slime", ["medium"]),
				_enemy("tank", ["medium"]),
			],
		},
		{
			"spawn_interval": 1.15,
			"wave_word_list_ids": ["medium", "hard"],
			"enemies": [
				_enemy("grunt", ["medium"]),
				_enemy("slime", ["medium"]),
				_enemy("scout", ["medium", "hard"]),
				_enemy("slime", ["hard"]),
				_enemy("tank", ["medium"]),
				_enemy("scout", ["hard"]),
			],
		},
		{
			"spawn_interval": 1.05,
			"wave_word_list_ids": ["medium", "hard"],
			"enemies": [
				_enemy("slime", ["medium"]),
				_enemy("slime", ["hard"]),
				_enemy("scout", ["hard"]),
				_enemy("tank", ["medium", "hard"]),
				_enemy("grunt", ["hard"]),
				_enemy("scout", ["hard"]),
				_enemy("slime", ["hard"]),
			],
		},
		{
			"spawn_interval": 0.95,
			"wave_word_list_ids": ["hard"],
			"enemies": [
				_enemy("grunt", ["hard"]),
				_enemy("scout", ["hard"]),
				_enemy("tank", ["hard"]),
				_enemy("slime", ["hard"]),
				_enemy("scout", ["hard"]),
				_enemy("tank", ["medium", "hard"]),
				_enemy("boss", ["hard"]),
			],
		},
	]


func _enemy(enemy_type: String, word_list_ids: Array[String]) -> Dictionary:
	return {
		"enemy_type": enemy_type,
		"word_list_ids": word_list_ids,
	}
