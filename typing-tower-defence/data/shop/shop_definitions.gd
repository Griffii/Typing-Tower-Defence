## Data for shop upgrade items and other things to buy

const UPGRADES := {
	"repair_base": {
		"display_name": "Repair",
		"base_cost": 30,
		"cost_scaling": 8,
		"max_level": -1,
		"value_per_level": 10,
		"description": "Restore {value} base HP."
	},

	"word_damage": {
		"display_name": "Word Damage",
		"base_cost": 40,
		"cost_scaling": 28,
		"max_level": 10,
		"value_per_level": 1,
		"description": "+{value} typing damage."
	},

	"special_damage": {
		"display_name": "Special Damage",
		"base_cost": 50,
		"cost_scaling": 32,
		"max_level": 10,
		"value_per_level": 4,
		"description": "+{value} special damage."
	},

	"special_meter_gain": {
		"display_name": "Special Charge",
		"base_cost": 55,
		"cost_scaling": 35,
		"max_level": 10,
		"value_per_level": 2.0,
		"description": "+{value} special meter gain per word."
	},

	"gold_gain": {
		"display_name": "Gold Gain",
		"base_cost": 80,
		"cost_scaling": 55,
		"max_level": 10,
		"value_per_level": 0.08,
		"description": "+{value}x gold multiplier."
	}
}
