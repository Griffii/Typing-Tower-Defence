extends Node

signal base_destroyed
signal base_damaged(amount: int)
signal base_repaired(amount: int)
signal hud_stats_changed(stats: Dictionary)
signal enemy_survived_word_hit(enemy: Node)
signal special_meter_changed(current_value: float, max_value: float)
signal special_meter_filled
signal tower_state_changed

const ShopDefinitions = preload("res://data/shop/shop_definitions.gd")
const TowerDefinitions = preload("res://data/towers/tower_definitions.gd")

const WORD_LISTS_DIR := "res://data/word_lists/"

@export var base_hp_max: int = 100
@export var word_damage: int = 10
@export var special_damage: int = 10
@export var special_meter_gain_per_word: float = 15.0
@export var special_meter_max: float = 100.0
@export var gold_gain_multiplier: float = 1.0

@onready var spawn_manager: Node = %SpawnManager

var run_mode: String = "legacy"

var base_word_damage: int = 10
var base_special_damage: int = 10
var base_special_meter_gain_per_word: float = 15.0
var base_gold_gain_multiplier: float = 1.0

var base_hp: int = 100
var gold: int = 60
var special_meter: float = 0.0

var replacement_word_provider: Node = null
var base_attackers: Array[Node] = []

var upgrade_levels := {
	"word_damage": 0,
	"special_damage": 0,
	"special_meter_gain": 0,
	"gold_gain": 0
}

var available_tower_slots: Array[String] = []
var tower_levels: Dictionary = {}
var tower_types: Dictionary = {}

var tower_word_list_ids: Array[String] = []
var tower_word_pool: Array[String] = []


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
	run_mode = String(run_config.get("mode", "legacy"))

	base_hp_max = int(run_config.get("starting_base_hp", base_hp_max))

	base_word_damage = int(run_config.get("word_damage", 10))
	base_special_damage = int(run_config.get("special_damage", 10))
	base_special_meter_gain_per_word = float(run_config.get("special_meter_gain_per_word", 15.0))
	base_gold_gain_multiplier = float(run_config.get("gold_gain_multiplier", 1.0))

	special_meter_max = float(run_config.get("special_meter_max", special_meter_max))

	var incoming_upgrade_levels: Dictionary = run_config.get("persistent_upgrade_levels", {})

	upgrade_levels = {
		"word_damage": int(incoming_upgrade_levels.get("word_damage", 0)),
		"special_damage": int(incoming_upgrade_levels.get("special_damage", 0)),
		"special_meter_gain": int(incoming_upgrade_levels.get("special_meter_gain", 0)),
		"gold_gain": int(incoming_upgrade_levels.get("gold_gain", 0)),
	}

	_set_tower_word_list_ids_from_run_config(run_config)
	_rebuild_tower_word_pool()
	_recalculate_player_upgrade_stats()


# ---------------------------
# Tower / portal word pool
# ---------------------------

func _set_tower_word_list_ids_from_run_config(run_config: Dictionary) -> void:
	tower_word_list_ids.clear()

	var ids: Variant = run_config.get("tower_word_list_ids", [])

	if ids is Array:
		for raw_id in ids:
			var clean_id := str(raw_id).strip_edges()
			if not clean_id.is_empty() and not tower_word_list_ids.has(clean_id):
				tower_word_list_ids.append(clean_id)

	if not tower_word_list_ids.is_empty():
		return

	var wave_definitions: Variant = run_config.get("wave_definitions", [])
	if not (wave_definitions is Array):
		return

	for wave in wave_definitions:
		if not (wave is Dictionary):
			continue

		var wave_ids: Variant = wave.get("tower_word_list_ids", wave.get("wave_word_list_ids", []))
		if not (wave_ids is Array):
			continue

		for raw_wave_id in wave_ids:
			var wave_id := str(raw_wave_id).strip_edges()
			if not wave_id.is_empty() and not tower_word_list_ids.has(wave_id):
				tower_word_list_ids.append(wave_id)


func _rebuild_tower_word_pool() -> void:
	tower_word_pool.clear()

	for list_id in tower_word_list_ids:
		var words: Array[String] = _get_words_from_word_list_id(list_id)

		for word in words:
			var clean_word := str(word).strip_edges()
			if clean_word.is_empty():
				continue
			if not tower_word_pool.has(clean_word):
				tower_word_pool.append(clean_word)

	if tower_word_pool.is_empty():
		push_warning("CombatManager: tower_word_pool was empty. Falling back to 'magic'.")
		tower_word_pool.append("magic")


func _get_words_from_word_list_id(list_id: String) -> Array[String]:
	var list_data: WordListData = _load_word_list_data(list_id)

	if list_data == null:
		push_warning("CombatManager: Could not load word list id: %s" % list_id)
		return []

	return list_data.words.duplicate()


func _load_word_list_data(list_id: String) -> WordListData:
	var clean_id := list_id.strip_edges()
	if clean_id.is_empty():
		return null

	var direct_path := WORD_LISTS_DIR + clean_id + ".tres"

	if ResourceLoader.exists(direct_path):
		var direct_resource := load(direct_path)
		if direct_resource is WordListData:
			return direct_resource as WordListData

	var dir := DirAccess.open(WORD_LISTS_DIR)
	if dir == null:
		push_warning("CombatManager: Could not open word list directory: %s" % WORD_LISTS_DIR)
		return null

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := WORD_LISTS_DIR + file_name
			var resource := load(path)

			if resource is WordListData:
				var word_list := resource as WordListData
				if word_list.id == clean_id:
					dir.list_dir_end()
					return word_list

		file_name = dir.get_next()

	dir.list_dir_end()
	return null


func set_tower_word_list_ids(new_ids: Array[String]) -> void:
	tower_word_list_ids.clear()

	for raw_id in new_ids:
		var clean_id := str(raw_id).strip_edges()
		if not clean_id.is_empty() and not tower_word_list_ids.has(clean_id):
			tower_word_list_ids.append(clean_id)

	_rebuild_tower_word_pool()
	apply_tower_word_pool_to_existing_portals()


func set_tower_word_pool(new_pool: Array[String]) -> void:
	tower_word_pool.clear()

	for word in new_pool:
		var clean_word := str(word).strip_edges()
		if not clean_word.is_empty() and not tower_word_pool.has(clean_word):
			tower_word_pool.append(clean_word)

	if tower_word_pool.is_empty():
		tower_word_pool.append("magic")

	apply_tower_word_pool_to_existing_portals()


func apply_word_pool_to_portal(portal: Node) -> void:
	if portal == null or not is_instance_valid(portal):
		return

	if portal.has_method("set_word_pool"):
		portal.set_word_pool(tower_word_pool)


func apply_tower_word_pool_to_existing_portals() -> void:
	for portal in get_tree().get_nodes_in_group("portals"):
		apply_word_pool_to_portal(portal)


# ---------------------------
# Replacement word provider
# ---------------------------

func set_replacement_word_provider(provider: Node) -> void:
	replacement_word_provider = provider


func clear_replacement_word_provider() -> void:
	replacement_word_provider = null


func _get_replacement_word_for_target(target_enemy: Node) -> String:
	if replacement_word_provider != null and is_instance_valid(replacement_word_provider):
		if replacement_word_provider.has_method("get_replacement_word_for_enemy"):
			var provider_word: String = String(replacement_word_provider.get_replacement_word_for_enemy(target_enemy))
			if not provider_word.is_empty():
				return provider_word

	if spawn_manager != null and spawn_manager.has_method("get_replacement_word_for_enemy"):
		var spawn_word: String = String(spawn_manager.get_replacement_word_for_enemy(target_enemy))
		if not spawn_word.is_empty():
			return spawn_word

	if target_enemy != null and is_instance_valid(target_enemy):
		if target_enemy.has_method("get_current_word"):
			return String(target_enemy.get_current_word())

	return ""


# ---------------------------
# Upgrade stats
# ---------------------------

func _recalculate_player_upgrade_stats() -> void:
	word_damage = base_word_damage
	special_damage = base_special_damage
	special_meter_gain_per_word = base_special_meter_gain_per_word
	gold_gain_multiplier = base_gold_gain_multiplier

	for upgrade_id in upgrade_levels.keys():
		var level: int = int(upgrade_levels.get(upgrade_id, 0))

		if level <= 0:
			continue

		if not ShopDefinitions.UPGRADES.has(upgrade_id):
			continue

		var def: Dictionary = ShopDefinitions.UPGRADES[upgrade_id]
		var value_per_level: Variant = def.get("value_per_level", 0)

		match upgrade_id:
			"word_damage":
				word_damage += int(value_per_level) * level

			"special_damage":
				special_damage += int(value_per_level) * level

			"special_meter_gain":
				special_meter_gain_per_word += float(value_per_level) * float(level)

			"gold_gain":
				gold_gain_multiplier += float(value_per_level) * float(level)


# ---------------------------
# Run state
# ---------------------------

func set_available_tower_slots(slot_ids: Array[String]) -> void:
	available_tower_slots = slot_ids.duplicate()
	_reset_tower_state()
	tower_state_changed.emit()


func reset_for_new_run() -> void:
	base_hp = base_hp_max
	gold = 60 #Give player enough gold to buy one tower
	base_attackers.clear()
	_reset_tower_state()
	_emit_hud_stats()
	reset_special_meter()
	tower_state_changed.emit()


func _reset_tower_state() -> void:
	tower_levels.clear()
	tower_types.clear()

	for slot_id in available_tower_slots:
		tower_levels[slot_id] = 0
		tower_types[slot_id] = ""


# ---------------------------
# Typing / damage
# ---------------------------

func resolve_completed_word(target_enemy: Node) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return

	_gain_special_meter_from_word()

	if not target_enemy.has_method("apply_damage"):
		return

	target_enemy.apply_damage(word_damage)

	if not is_instance_valid(target_enemy):
		return

	if target_enemy.has_method("is_enemy_dead") and target_enemy.is_enemy_dead():
		return

	var new_word: String = _get_replacement_word_for_target(target_enemy)

	if not new_word.is_empty():
		if target_enemy.has_method("assign_new_word"):
			target_enemy.assign_new_word(new_word)
		elif target_enemy.has_method("set_word"):
			target_enemy.set_word(new_word)

	enemy_survived_word_hit.emit(target_enemy)


func notify_typing_target_word_completed(_target: Node) -> void:
	_gain_special_meter_from_word()


func _gain_special_meter_from_word() -> void:
	special_meter += special_meter_gain_per_word

	if special_meter >= special_meter_max:
		special_meter = 0.0
		special_meter_filled.emit()

	special_meter_changed.emit(special_meter, special_meter_max)


func fire_player_special_at_target(target_enemy: Node) -> void:
	print("[CombatManager] fire_player_special_at_target: ", target_enemy)

	if target_enemy == null or not is_instance_valid(target_enemy):
		print("[CombatManager] invalid special target")
		return

	if not target_enemy.has_method("apply_damage") and not target_enemy.has_method("take_damage"):
		print("[CombatManager] target has no damage method")
		return

	print("[CombatManager] applying special damage: ", special_damage)

	if target_enemy.has_method("take_damage"):
		target_enemy.take_damage(special_damage)
	else:
		target_enemy.apply_damage(special_damage)

	if not is_instance_valid(target_enemy):
		return



func reset_special_meter() -> void:
	special_meter = 0.0
	special_meter_changed.emit(special_meter, special_meter_max)


func apply_tower_hit(target_enemy: Node, damage_amount: int) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return

	if target_enemy.has_method("take_damage"):
		target_enemy.take_damage(damage_amount)
	elif target_enemy.has_method("apply_damage"):
		target_enemy.apply_damage(damage_amount)


# ---------------------------
# Gold / enemy rewards
# ---------------------------

func award_enemy_kill_rewards(enemy: Node) -> void:
	_award_enemy_kill_rewards(enemy)

func _award_enemy_kill_rewards(enemy: Node) -> void:
	var reward_gold: int = 0

	if enemy != null and is_instance_valid(enemy):
		if enemy.has_method("get_reward_gold"):
			reward_gold = int(enemy.get_reward_gold())

	gold += int(round(reward_gold * gold_gain_multiplier))
	_emit_hud_stats()


# ---------------------------
# Base
# ---------------------------

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


func _emit_hud_stats() -> void:
	hud_stats_changed.emit({
		"gold": gold,
		"base_hp": base_hp,
		"base_hp_max": base_hp_max
	})


# ---------------------------
# Shop upgrades
# ---------------------------

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

		"word_damage", "special_damage", "special_meter_gain", "gold_gain":
			upgrade_levels[upgrade_id] = current_level + 1
			_recalculate_player_upgrade_stats()
			_save_persistent_upgrade_if_needed()

	_emit_hud_stats()
	special_meter_changed.emit(special_meter, special_meter_max)
	return true


func _save_persistent_upgrade_if_needed() -> void:
	if run_mode != "campaign":
		return

	if CampaignProgress != null and CampaignProgress.has_method("set_upgrade_levels"):
		CampaignProgress.set_upgrade_levels(upgrade_levels)


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
		"special_damage": special_damage,
		"special_meter_gain_per_word": special_meter_gain_per_word,
		"gold_gain_multiplier": gold_gain_multiplier
	}


# ---------------------------
# Tower API
# ---------------------------

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


func get_portal_stats(slot_id: String) -> Dictionary:
	return get_tower_stats(slot_id)


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
