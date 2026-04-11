class_name ShopDefinitions

const UPGRADES := {
	"repair_base": {
		"display_name": "Repair",
		"base_cost": 25,
		"cost_scaling": 5,
		"max_level": -1,
		"value_per_level": 8,
		"description": "Restore {value} base HP."
	},
	"word_damage": {
		"display_name": "Word Damage",
		"base_cost": 35,
		"cost_scaling": 20,
		"max_level": 6,
		"value_per_level": 1,
		"description": "+{value} typing damage."
	},
	"arrow_damage": {
		"display_name": "Arrow Damage",
		"base_cost": 45,
		"cost_scaling": 25,
		"max_level": 5,
		"value_per_level": 4,
		"description": "+{value} arrow damage."
	},
	"arrow_meter_gain": {
		"display_name": "Arrow Charge",
		"base_cost": 45,
		"cost_scaling": 25,
		"max_level": 5,
		"value_per_level": 3,
		"description": "+{value} arrow meter gain per word."
	},
	"gold_gain": {
		"display_name": "Gold Gain",
		"base_cost": 65,
		"cost_scaling": 35,
		"max_level": 4,
		"value_per_level": 0.10,
		"description": "+{value}x gold multiplier."
	}
}
