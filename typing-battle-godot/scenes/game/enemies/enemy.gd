# res://scripts/game/enemies/enemy.gd
class_name Enemy
extends CharacterBody2D

signal enemy_died(enemy: Node)
signal enemy_reached_base(enemy: Node)

const EnemyDefinitions = preload("res://data/enemies/enemy_definitions.gd")
const HIT_BURST_EFFECT_SCENE: PackedScene = preload("res://scenes/game/effects/hit_burst.tscn")
const COIN_BURST_EFFECT_SCENE: PackedScene = preload("res://scenes/game/effects/coin_burst.tscn")
const BUBBLE_BURST_EFFECT_SCENE: PackedScene = preload("res://scenes/game/effects/bubble_burst.tscn")

@export var base_reach_distance: float = 8.0
@export var use_hit_burst_effect: bool = true
@export var use_coin_burst_effect: bool = true

@onready var visual_root: Node2D = %VisualRoot
@onready var label_root: Node2D = %LabelRoot
@onready var label_anchor: Marker2D = %LabelAnchor
@onready var word_label_controller: WordLabelController = %WordLabelController
@onready var hp_label: Label = %HpLabel

var move_speed: float = 40.0
var max_hp: int = 10
var reward_score: int = 10
var reward_gold: int = 1
var base_attack_damage: int = 1
var base_attack_interval: float = 1.0

var current_hp: int = 10
var current_word: String = ""
var enemy_type: String = ""
var enemy_id: String = ""
var enemy_data_store: Dictionary = {}

var is_dead: bool = false
var has_reached_base: bool = false
var is_targeted: bool = false
var is_attack_anim_active: bool = false
var is_damage_anim_active: bool = false

var base_target: Node2D = null
var base_attack_timer: float = 0.0

var current_target: Node = null
var targets_in_range: Array[Node] = []

var path_points: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var path_reach_distance: float = 6.0


func _ready() -> void:
	add_to_group("enemies")

	if word_label_controller != null:
		word_label_controller.set_anchor(label_anchor)

	_apply_visuals()
	_apply_facing()
	_update_labels()
	_play_walk_animation()


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_cleanup_targets()

	if is_instance_valid(current_target):
		velocity = Vector2.ZERO
		move_and_slide()

		base_attack_timer -= delta
		if base_attack_timer <= 0.0:
			base_attack_timer = base_attack_interval
			play_attack_animation()

			if is_instance_valid(current_target) and current_target.has_method("apply_damage"):
				current_target.apply_damage(base_attack_damage)
		return

	if has_reached_base:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if path_points.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if path_index >= path_points.size():
		has_reached_base = true
		velocity = Vector2.ZERO
		move_and_slide()
		base_attack_timer = 0.0
		play_attack_animation()
		enemy_reached_base.emit(self)
		return

	var target_point: Vector2 = path_points[path_index]
	var to_point: Vector2 = target_point - global_position
	var distance: float = to_point.length()

	if distance <= path_reach_distance:
		path_index += 1
		return

	var direction: Vector2 = to_point.normalized()
	velocity = direction * move_speed
	move_and_slide()

	_play_walk_animation()


func setup_enemy(enemy_data: Dictionary) -> void:
	enemy_data_store = enemy_data.duplicate(true)

	enemy_type = str(enemy_data.get("enemy_type", "grunt"))
	enemy_id = str(enemy_data.get("enemy_id", ""))

	_apply_type_stats(enemy_type)

	current_word = str(enemy_data.get("word", ""))

	var raw_points: Variant = enemy_data.get("path_points", PackedVector2Array())
	if raw_points is PackedVector2Array:
		path_points = raw_points

	current_hp = max_hp
	has_reached_base = false
	is_dead = false
	is_targeted = false
	is_attack_anim_active = false
	is_damage_anim_active = false
	base_attack_timer = 0.0
	path_index = 0
	current_target = null
	targets_in_range.clear()

	if word_label_controller != null:
		word_label_controller.set_anchor(label_anchor)

	_apply_visuals()
	_apply_facing()
	_update_labels()
	_play_walk_animation()


func _apply_type_stats(type_name: String) -> void:
	var stats: Dictionary = EnemyDefinitions.ENEMY_STATS.get(type_name, EnemyDefinitions.ENEMY_STATS["grunt"])

	move_speed = float(stats.get("move_speed", 40.0))
	max_hp = int(stats.get("max_hp", 10))
	reward_score = int(stats.get("reward_score", 10))
	reward_gold = int(stats.get("reward_gold", 1))
	base_attack_damage = int(stats.get("base_attack_damage", 1))
	base_attack_interval = float(stats.get("base_attack_interval", 1.0))


func process_base_attack(delta: float, combat_manager: Node) -> void:
	if is_dead:
		return

	if not has_reached_base:
		return

	base_attack_timer -= delta
	if base_attack_timer > 0.0:
		return

	base_attack_timer = base_attack_interval
	play_attack_animation()
	
	# Wait for the anim to start before applying damage to the base.
	# Janky, but its easy and it works.
	await get_tree().create_timer(0.2).timeout
	
	if combat_manager != null and combat_manager.has_method("apply_base_damage"):
		combat_manager.apply_base_damage(base_attack_damage)


func set_base_target(target: Node2D) -> void:
	base_target = target


func set_word(new_word: String) -> void:
	current_word = new_word
	clear_typing_feedback()


func assign_new_word(new_word: String) -> void:
	set_word(new_word)


func set_targeted(targeted: bool) -> void:
	is_targeted = targeted

	if word_label_controller != null:
		word_label_controller.set_targeted(targeted)

	clear_typing_feedback()


func set_typing_progress(typed_text: String) -> void:
	if word_label_controller != null:
		word_label_controller.set_typing_progress(typed_text)


func clear_typing_feedback() -> void:
	_update_labels()


func apply_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp = max(0, current_hp - amount)
	_update_labels()

	if current_hp <= 0:
		die()
		return

	_spawn_hit_burst_effect()
	play_take_damage_animation()


func play_take_damage_animation() -> void:
	pass


func play_attack_animation() -> void:
	pass


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	clear_typing_feedback()

	current_target = null
	targets_in_range.clear()

	_spawn_coin_burst_effect()

	# Small delay to allow effects/animations to play
	#await get_tree().create_timer(0.4).timeout

	enemy_died.emit(self)
	queue_free()


func is_enemy_dead() -> bool:
	return is_dead


func has_reached_base_target() -> bool:
	return has_reached_base


func get_current_word() -> String:
	return current_word


func get_enemy_type() -> String:
	return enemy_type


func get_reward_score() -> int:
	return reward_score


func get_reward_gold() -> int:
	return reward_gold


func get_enemy_data() -> Dictionary:
	return enemy_data_store.duplicate(true)


func _update_labels() -> void:
	if word_label_controller != null:
		word_label_controller.set_word(current_word)
		word_label_controller.set_targeted(is_targeted)

	if hp_label != null:
		hp_label.text = "%d / %d" % [current_hp, max_hp]


func _apply_visuals() -> void:
	pass


func _apply_facing() -> void:
	if visual_root != null:
		visual_root.scale.x = -1.0

	if label_root != null:
		label_root.scale.x = 1.0


func _play_walk_animation() -> void:
	pass


func _spawn_hit_burst_effect() -> void:
	if not use_hit_burst_effect:
		return
	if HIT_BURST_EFFECT_SCENE == null:
		return

	var effect: Node2D = HIT_BURST_EFFECT_SCENE.instantiate() as Node2D
	if effect == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	parent_node.add_child(effect)
	effect.global_position = _get_effect_spawn_position()


func _spawn_coin_burst_effect() -> void:
	if not use_coin_burst_effect:
		return
	if COIN_BURST_EFFECT_SCENE == null:
		return

	var effect: Node2D = COIN_BURST_EFFECT_SCENE.instantiate() as Node2D
	if effect == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	parent_node.add_child(effect)
	effect.global_position = _get_effect_spawn_position()


func _get_effect_spawn_position() -> Vector2:
	if visual_root != null:
		return visual_root.global_position

	return global_position


func _on_detection_body_entered(body: Node) -> void:
	_try_add_target(body)


func _on_detection_body_exited(body: Node) -> void:
	_remove_target(body)


func _on_detection_area_entered(area: Area2D) -> void:
	_try_add_target(area.get_parent())


func _on_detection_area_exited(area: Area2D) -> void:
	_remove_target(area.get_parent())


func _try_add_target(candidate: Node) -> void:
	if is_dead:
		return
	if candidate == null or not is_instance_valid(candidate):
		return
	if not candidate.is_in_group("soldiers"):
		return
	if candidate.has_method("is_soldier_dead") and candidate.is_soldier_dead():
		return
	if targets_in_range.has(candidate):
		return

	targets_in_range.append(candidate)
	_try_set_next_target()


func _remove_target(candidate: Node) -> void:
	var idx: int = targets_in_range.find(candidate)
	if idx != -1:
		targets_in_range.remove_at(idx)

	if candidate == current_target:
		current_target = null
		_try_set_next_target()


func _cleanup_targets() -> void:
	for i in range(targets_in_range.size() - 1, -1, -1):
		var target: Node = targets_in_range[i]
		if not is_instance_valid(target):
			targets_in_range.remove_at(i)
			continue
		if target.has_method("is_soldier_dead") and target.is_soldier_dead():
			targets_in_range.remove_at(i)

	if current_target != null:
		if not is_instance_valid(current_target):
			current_target = null
		elif current_target.has_method("is_soldier_dead") and current_target.is_soldier_dead():
			current_target = null

	if current_target == null:
		_try_set_next_target()


func _try_set_next_target() -> void:
	if current_target != null and is_instance_valid(current_target):
		return

	if targets_in_range.is_empty():
		current_target = null
		return

	current_target = targets_in_range[0]
	base_attack_timer = 0.0
