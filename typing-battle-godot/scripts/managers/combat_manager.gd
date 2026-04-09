extends Node

signal base_destroyed
signal base_damaged(amount: int)
signal base_repaired(amount: int)
signal hud_stats_changed(stats: Dictionary)
signal arrow_meter_changed(current_value: float, max_value: float)
signal enemy_survived_word_hit(enemy: Node)
signal arrow_meter_filled
signal tower_state_changed

const ShopDefinitions = preload("res://data/shop/shop_definitions.gd")
const TowerDefinitions = preload("res://data/towers/tower_definitions.gd")

@export var base_hp_max: int = 100
@export var word_damage: int = 10
@export var arrow_damage: int = 10
@export var arrow_meter_gain_per_word: float = 15.0
@export var arrow_meter_max: float = 100.0
@export var gold_gain_multiplier: float = 1.0

@onready var spawn_manager: Node = %SpawnManager

var base_hp: int = 100

var gold: int = 0
var arrow_meter: float = 0.0

var base_attackers: Array[Node] = []

var upgrade_levels := {
	"word_damage": 0,
	"arrow_damage": 0,
	"arrow_meter_gain": 0,
	"gold_gain": 0
}

var available_tower_slots: Array[String] = []
var tower_levels: Dictionary = {}
var tower_types: Dictionary = {}


func _ready() -> void:
	add_to_group("combat_manager")

func _process(delta: float) -> void:
	for i in range(base_attackers.size() - 1, -1, -1):
		var enemy: Node = base_attackers[i]
		if not is_instance_valid(enemy):
			base_attackers.remove_at(i)
			continue

		if enemy.has_method("process_base_attack"):
			enemy.process_base_attack(delta, self)


func setup_run(run_config: Dictionary) -> void:
	base_hp_max = int(run_config.get("starting_base_hp", base_hp_max))
	word_damage = int(run_config.get("word_damage", word_damage))
	arrow_damage = int(run_config.get("arrow_damage", arrow_damage))
	arrow_meter_gain_per_word = float(run_config.get("arrow_meter_gain_per_word", arrow_meter_gain_per_word))
	arrow_meter_max = float(run_config.get("arrow_meter_max", arrow_meter_max))
	gold_gain_multiplier = float(run_config.get("gold_gain_multiplier", gold_gain_multiplier))


func set_available_tower_slots(slot_ids: Array[String]) -> void:
	available_tower_slots = slot_ids.duplicate()
	_reset_tower_state()
	tower_state_changed.emit()


func reset_for_new_run() -> void:
	base_hp = base_hp_max
	gold = 0
	base_attackers.clear()
	_reset_tower_state()
	_emit_hud_stats()
	reset_arrow_meter()
	tower_state_changed.emit()


func _reset_tower_state() -> void:
	tower_levels.clear()
	tower_types.clear()

	for slot_id in available_tower_slots:
		tower_levels[slot_id] = 0
		tower_types[slot_id] = ""


func resolve_completed_word(target_enemy: Node) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return

	if not target_enemy.has_method("apply_damage"):
		return

	var was_dead_before: bool = false
	if target_enemy.has_method("is_enemy_dead"):
		was_dead_before = target_enemy.is_enemy_dead()

	target_enemy.apply_damage(word_damage)

	arrow_meter += arrow_meter_gain_per_word
	if arrow_meter >= arrow_meter_max:
		arrow_meter = 0.0
		arrow_meter_filled.emit()

	arrow_meter_changed.emit(arrow_meter, arrow_meter_max)

	if not is_instance_valid(target_enemy):
		return

	if target_enemy.has_method("is_enemy_dead") and target_enemy.is_enemy_dead():
		if not was_dead_before:
			_award_enemy_kill_rewards(target_enemy)
		return

	if spawn_manager != null and spawn_manager.has_method("get_replacement_word_for_enemy"):
		var new_word: String = String(spawn_manager.get_replacement_word_for_enemy(target_enemy))

		if target_enemy.has_method("assign_new_word"):
			target_enemy.assign_new_word(new_word)
		elif target_enemy.has_method("set_word"):
			target_enemy.set_word(new_word)

	enemy_survived_word_hit.emit(target_enemy)


func fire_castle_arrow_at_target(target_enemy: Node) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return

	if not target_enemy.has_method("apply_damage"):
		return

	var was_dead_before: bool = false
	if target_enemy.has_method("is_enemy_dead"):
		was_dead_before = target_enemy.is_enemy_dead()

	target_enemy.apply_damage(arrow_damage)

	if not is_instance_valid(target_enemy):
		return

	if target_enemy.has_method("is_enemy_dead") and target_enemy.is_enemy_dead():
		if not was_dead_before:
			_award_enemy_kill_rewards(target_enemy)


func reset_arrow_meter() -> void:
	arrow_meter = 0.0
	arrow_meter_changed.emit(arrow_meter, arrow_meter_max)


func _award_enemy_kill_rewards(enemy: Node) -> void:
	var reward_gold: int = 0

	if enemy != null and is_instance_valid(enemy):
		if enemy.has_method("get_reward_gold"):
			reward_gold = int(enemy.get_reward_gold())

	gold += int(round(reward_gold * gold_gain_multiplier))
	_emit_hud_stats()


func register_enemy_at_base(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	if base_attackers.has(enemy):
		return

	base_attackers.append(enemy)


func unregister_enemy_at_base(enemy: Node) -> void:
	var index: int = base_attackers.find(enemy)
	if index != -1:
		base_attackers.remove_at(index)


func apply_base_damage(amount: int) -> void:
	if amount <= 0:
		return

	var previous_hp: int = base_hp
	base_hp = max(0, base_hp - amount)
	var applied_damage: int = previous_hp - base_hp

	if applied_damage > 0:
		base_damaged.emit(applied_damage)

	_emit_hud_stats()

	if base_hp <= 0:
		base_destroyed.emit()


func apply_upgrade_purchase(upgrade_id: String) -> bool:
	if not ShopDefinitions.UPGRADES.has(upgrade_id):
		return false

	var def: Dictionary = ShopDefinitions.UPGRADES[upgrade_id]
	var current_level: int = int(upgrade_levels.get(upgrade_id, 0))
	var max_level: int = int(def.get("max_level", -1))

	if max_level >= 0 and current_level >= max_level:
		return false

	var cost: int = get_upgrade_cost(upgrade_id)
	if gold < cost:
		return false

	gold -= cost

	match upgrade_id:
		"repair_base":
			var repair_amount: int = int(def.get("value_per_level", 0))
			var previous_hp: int = base_hp
			base_hp = min(base_hp_max, base_hp + repair_amount)
			var applied_repair: int = base_hp - previous_hp

			if applied_repair > 0:
				base_repaired.emit(applied_repair)

		"word_damage":
			word_damage += int(def.get("value_per_level", 0))
			upgrade_levels[upgrade_id] = current_level + 1

		"arrow_damage":
			arrow_damage += int(def.get("value_per_level", 0))
			upgrade_levels[upgrade_id] = current_level + 1

		"arrow_meter_gain":
			arrow_meter_gain_per_word += float(def.get("value_per_level", 0))
			upgrade_levels[upgrade_id] = current_level + 1

		"gold_gain":
			gold_gain_multiplier += float(def.get("value_per_level", 0))
			upgrade_levels[upgrade_id] = current_level + 1

	_emit_hud_stats()
	arrow_meter_changed.emit(arrow_meter, arrow_meter_max)
	return true


func get_upgrade_cost(upgrade_id: String) -> int:
	if not ShopDefinitions.UPGRADES.has(upgrade_id):
		return 999999

	var def: Dictionary = ShopDefinitions.UPGRADES[upgrade_id]
	var current_level: int = int(upgrade_levels.get(upgrade_id, 0))
	return int(def.get("base_cost", 0)) + current_level * int(def.get("cost_scaling", 0))


func get_shop_state() -> Dictionary:
	return {
		"gold": gold,
		"base_hp": base_hp,
		"base_hp_max": base_hp_max,
		"upgrade_levels": upgrade_levels.duplicate(true),
		"word_damage": word_damage,
		"arrow_damage": arrow_damage,
		"arrow_meter_gain_per_word": arrow_meter_gain_per_word,
		"gold_gain_multiplier": gold_gain_multiplier
	}


func _emit_hud_stats() -> void:
	hud_stats_changed.emit({
		"gold": gold,
		"base_hp": base_hp,
		"base_hp_max": base_hp_max
	})


### Tower API #####

func has_tower_slot(slot_id: String) -> bool:
	return tower_levels.has(slot_id)


func get_tower_level(slot_id: String) -> int:
	return int(tower_levels.get(slot_id, 0))


func get_tower_type(slot_id: String) -> String:
	return str(tower_types.get(slot_id, ""))


func get_tower_stats(slot_id: String) -> Dictionary:
	var tower_type: String = get_tower_type(slot_id)
	if tower_type.is_empty():
		return {}

	var level: int = get_tower_level(slot_id)
	if level <= 0:
		return {}

	return TowerDefinitions.get_level_data(tower_type, level)


func get_max_tower_level(slot_id: String) -> int:
	var tower_type: String = get_tower_type(slot_id)
	if tower_type.is_empty():
		return 0

	return TowerDefinitions.get_max_level(tower_type)


func get_next_tower_cost(slot_id: String, preview_tower_type: String = "") -> int:
	var current_level: int = get_tower_level(slot_id)
	var tower_type: String = get_tower_type(slot_id)

	if current_level <= 0:
		tower_type = preview_tower_type

	if tower_type.is_empty():
		return -1

	return TowerDefinitions.get_next_cost(tower_type, current_level)


func can_purchase_tower_level(slot_id: String, preview_tower_type: String = "") -> bool:
	var cost := get_next_tower_cost(slot_id, preview_tower_type)
	if cost < 0:
		return false
	return gold >= cost


func purchase_tower_upgrade(slot_id: String, selected_tower_type: String) -> bool:
	if not has_tower_slot(slot_id):
		return false

	var current_level: int = get_tower_level(slot_id)
	var built_tower_type: String = get_tower_type(slot_id)
	var active_tower_type: String = built_tower_type

	if current_level <= 0:
		if selected_tower_type.is_empty():
			return false

		if not TowerDefinitions.has_tower_type(selected_tower_type):
			return false

		active_tower_type = selected_tower_type
	else:
		if active_tower_type.is_empty():
			return false

	var cost: int = get_next_tower_cost(slot_id, active_tower_type)
	if cost < 0 or gold < cost:
		return false

	gold -= cost
	tower_levels[slot_id] = current_level + 1

	if current_level <= 0:
		tower_types[slot_id] = active_tower_type

	_emit_hud_stats()
	tower_state_changed.emit()
	return true


func get_build_state() -> Dictionary:
	var slot_state := {}

	for slot_id in available_tower_slots:
		var current_level: int = get_tower_level(slot_id)
		var tower_type: String = get_tower_type(slot_id)
		var next_cost: int = get_next_tower_cost(slot_id)
		var max_level: int = get_max_tower_level(slot_id)

		slot_state[slot_id] = {
			"level": current_level,
			"tower_type": tower_type,
			"next_cost": next_cost,
			"max_level": max_level,
			"is_built": current_level > 0,
			"current_stats": get_tower_stats(slot_id)
		}

	return {
		"gold": gold,
		"slots": slot_state
	}


func apply_tower_hit(target_enemy: Node, damage_amount: int) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return

	var was_dead_before := false
	if target_enemy.has_method("is_enemy_dead"):
		was_dead_before = target_enemy.is_enemy_dead()

	if target_enemy.has_method("apply_damage"):
		target_enemy.apply_damage(damage_amount)

	if target_enemy.has_method("is_enemy_dead") and target_enemy.is_enemy_dead():
		if not was_dead_before:
			_award_enemy_kill_rewards(target_enemy)
