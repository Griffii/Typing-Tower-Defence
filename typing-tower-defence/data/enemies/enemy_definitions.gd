# res://data/enemies/enemy_definitions.gd
class_name EnemyDefinitions
extends RefCounted

const ENEMY_STATS := {
	"grunt": {
		"move_speed": 50.0,
		"max_hp": 18,
		"reward_score": 10,
		"reward_gold": 8,
		"base_attack_damage": 2,
		"base_attack_interval": 1.5,
	},
	"scout": {
		"move_speed": 70.0,
		"max_hp": 10,
		"reward_score": 10,
		"reward_gold": 10,
		"base_attack_damage": 1,
		"base_attack_interval": 1.0,
	},
	"tank": {
		"move_speed": 30.0,
		"max_hp": 42,
		"reward_score": 10,
		"reward_gold": 15,
		"base_attack_damage": 3,
		"base_attack_interval": 2.0,
	},
	"boss": {
		"move_speed": 20.0,
		"max_hp": 300,
		"reward_score": 10,
		"reward_gold": 100,
		"base_attack_damage": 8,
		"base_attack_interval": 3.0,
	},
	"slime": {
		"move_speed": 50.0,
		"max_hp": 22,
		"reward_score": 10,
		"reward_gold": 9,
		"base_attack_damage": 2,
		"base_attack_interval": 1.4,
	},
	"boss_slime": {
		"move_speed": 15.0,    
		"max_hp": 350,          
		"reward_score": 120,
		"reward_gold": 130,
		"base_attack_damage": 10,     
		"base_attack_interval": 3.5,  
	},
	
}
