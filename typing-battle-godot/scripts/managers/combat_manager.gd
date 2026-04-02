# combat_manager.gd
extends Node

signal base_destroyed
signal hud_stats_changed(stats: Dictionary)
signal arrow_meter_changed(current_value: float, max_value: float)
signal enemy_survived_word_hit(enemy: Node)
signal arrow_meter_filled

@export var base_hp_max: int = 50
@export var word_damage: int = 10
@export var kill_score: int = 10
@export var kill_gold: int = 1
@export var arrow_damage: int = 10
@export var arrow_meter_gain_per_word: float = 25.0
@export var arrow_meter_max: float = 100.0

@onready var spawn_manager: Node = %SpawnManager

var base_hp: int = 50
var score: int = 0
var gold: int = 0
var arrow_meter: float = 0.0

var base_attackers: Array[Node] = []


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
	kill_score = int(run_config.get("kill_score", kill_score))
	kill_gold = int(run_config.get("kill_gold", kill_gold))
	arrow_damage = int(run_config.get("arrow_damage", arrow_damage))
	arrow_meter_gain_per_word = float(run_config.get("arrow_meter_gain_per_word", arrow_meter_gain_per_word))
	arrow_meter_max = float(run_config.get("arrow_meter_max", arrow_meter_max))


func reset_for_new_run() -> void:
	base_hp = base_hp_max
	score = 0
	gold = 0
	arrow_meter = 0.0
	base_attackers.clear()

	_emit_hud_stats()
	arrow_meter_changed.emit(arrow_meter, arrow_meter_max)


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
		score += kill_score
		gold += kill_gold
		_emit_hud_stats()
		return

	if target_enemy.has_method("is_enemy_dead") and target_enemy.is_enemy_dead():
		if not was_dead_before:
			score += kill_score
			gold += kill_gold
			_emit_hud_stats()
		return

	if target_enemy.has_method("get_enemy_type") and spawn_manager != null and spawn_manager.has_method("get_word_for_enemy_type"):
		var enemy_type: String = String(target_enemy.get_enemy_type())
		var new_word: String = String(spawn_manager.get_word_for_enemy_type(enemy_type))

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
		score += kill_score
		gold += kill_gold
		_emit_hud_stats()
		return

	if target_enemy.has_method("is_enemy_dead") and target_enemy.is_enemy_dead():
		if not was_dead_before:
			score += kill_score
			gold += kill_gold
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
	base_hp = max(0, base_hp - amount)
	_emit_hud_stats()

	if base_hp <= 0:
		base_destroyed.emit()


func _emit_hud_stats() -> void:
	hud_stats_changed.emit({
		"score": score,
		"gold": gold,
		"base_hp": base_hp,
		"base_hp_max": base_hp_max
	})
