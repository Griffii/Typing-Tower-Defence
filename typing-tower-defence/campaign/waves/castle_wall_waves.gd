extends RefCounted


func get_wave_definitions() -> Array:
	return [
		{
			"spawn_interval": 1.6,
			"wave_word_list_ids": ["easy"],
			"enemies": [
				_enemy("grunt", ["easy"]),
				_enemy("grunt", ["easy"]),
				_enemy("grunt", ["easy"]),
			],
		},
		{
			"spawn_interval": 1.5,
			"wave_word_list_ids": ["easy"],
			"enemies": [
				_enemy("grunt", ["easy"]),
				_enemy("grunt", ["easy"]),
				_enemy("grunt", ["easy"]),
				_enemy("grunt", ["easy"]),
			],
		},
		{
			"spawn_interval": 1.45,
			"wave_word_list_ids": ["easy", "medium"],
			"enemies": [
				_enemy("grunt", ["easy"]),
				_enemy("grunt", ["easy"]),
				_enemy("scout", ["easy", "medium"]),
				_enemy("grunt", ["medium"]),
			],
		},
		{
			"spawn_interval": 1.35,
			"wave_word_list_ids": ["medium"],
			"enemies": [
				_enemy("grunt", ["medium"]),
				_enemy("scout", ["medium"]),
				_enemy("grunt", ["medium"]),
				_enemy("scout", ["medium"]),
				_enemy("grunt", ["easy", "medium"]),
			],
		},
		{
			"spawn_interval": 1.25,
			"wave_word_list_ids": ["medium"],
			"enemies": [
				_enemy("grunt", ["medium"]),
				_enemy("scout", ["medium"]),
				_enemy("tank", ["medium"]),
				_enemy("grunt", ["medium"]),
				_enemy("scout", ["medium"]),
			],
		},
	]


func _enemy(enemy_type: String, word_list_ids: Array[String]) -> Dictionary:
	return {
		"enemy_type": enemy_type,
		"word_list_ids": word_list_ids,
	}
