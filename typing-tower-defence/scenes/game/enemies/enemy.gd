class_name Enemy
extends CharacterBody2D

signal enemy_died(enemy: Node)
signal enemy_reached_base(enemy: Node)

const EnemyDefinitions = preload("res://data/enemies/enemy_definitions.gd")
const HIT_BURST_EFFECT_SCENE: PackedScene = preload("res://scenes/game/effects/hit_burst.tscn")
const COIN_BURST_EFFECT_SCENE: PackedScene = preload("res://scenes/game/effects/coin_burst.tscn")
const FLOATING_DAMAGE_NUMBER_SCENE: PackedScene = preload("uid://c7xyxla7irhdp")

@export var base_reach_distance: float = 8.0
@export var use_hit_burst_effect: bool = true
@export var use_coin_burst_effect: bool = true
@export var use_floating_damage_numbers: bool = true
@export var floating_damage_offset: Vector2 = Vector2(0, -28)

@onready var visual_root: Node2D = %VisualRoot
@onready var health_bar: Control = %HealthBar
@onready var floating_damage_number_marker: Marker2D = %FloatingDamageNumberMarker

var move_speed: float = 40.0
var max_hp: int = 10
var reward_score: int = 10
var reward_gold: int = 1
var base_attack_damage: int = 1
var base_attack_interval: float = 1.0

var current_hp: int = 10
var enemy_type: String = ""
var enemy_id: String = ""
var enemy_data_store: Dictionary = {}

var is_dead: bool = false
var has_reached_base: bool = false
var is_attack_anim_active: bool = false
var is_damage_anim_active: bool = false

var base_attack_timer: float = 0.0

var path_points: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var path_reach_distance: float = 6.0


func _ready() -> void:
	add_to_group("enemies")
	_apply_visuals()
	_apply_facing()
	_update_health_bar()
	_play_walk_animation()


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
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
		_reach_base()
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

	var raw_points: Variant = enemy_data.get("path_points", PackedVector2Array())
	if raw_points is PackedVector2Array:
		path_points = raw_points
	else:
		path_points = PackedVector2Array()

	current_hp = max_hp
	has_reached_base = false
	is_dead = false
	is_attack_anim_active = false
	is_damage_anim_active = false
	base_attack_timer = 0.0
	path_index = 0

	_apply_visuals()
	_apply_facing()
	_update_health_bar()
	_play_walk_animation()


func _apply_type_stats(type_name: String) -> void:
	var stats: Dictionary = EnemyDefinitions.ENEMY_STATS.get(type_name, EnemyDefinitions.ENEMY_STATS["grunt"])

	move_speed = float(stats.get("move_speed", 40.0))
	max_hp = int(stats.get("max_hp", 10))
	reward_score = int(stats.get("reward_score", 10))
	reward_gold = int(stats.get("reward_gold", 1))
	base_attack_damage = int(stats.get("base_attack_damage", 1))
	base_attack_interval = float(stats.get("base_attack_interval", 1.0))


func _reach_base() -> void:
	if has_reached_base:
		return

	has_reached_base = true
	velocity = Vector2.ZERO
	move_and_slide()
	base_attack_timer = 0.0
	play_attack_animation()
	enemy_reached_base.emit(self)


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

	await get_tree().create_timer(0.2).timeout

	if is_dead:
		return

	if combat_manager != null and combat_manager.has_method("apply_base_damage"):
		combat_manager.apply_base_damage(base_attack_damage)


func take_damage(amount: int) -> void:
	if is_dead:
		return
	if amount <= 0:
		return

	var applied_damage: int = min(amount, current_hp)
	current_hp = max(0, current_hp - amount)

	_update_health_bar()
	_spawn_floating_damage_number(applied_damage)

	if current_hp <= 0:
		die()
		return

	_spawn_hit_burst_effect()
	play_take_damage_animation()


func apply_damage(amount: int) -> void:
	take_damage(amount)


func play_take_damage_animation() -> void:
	pass


func play_attack_animation() -> void:
	pass


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	_spawn_coin_burst_effect()

	enemy_died.emit(self)
	queue_free()


func is_enemy_dead() -> bool:
	return is_dead


func has_reached_base_target() -> bool:
	return has_reached_base


func get_enemy_type() -> String:
	return enemy_type


func get_reward_score() -> int:
	return reward_score


func get_reward_gold() -> int:
	return reward_gold


func get_enemy_data() -> Dictionary:
	return enemy_data_store.duplicate(true)


func _update_health_bar() -> void:
	if health_bar == null:
		return

	if health_bar.has_method("set_base_hp"):
		health_bar.set_base_hp(current_hp, max_hp)
	elif health_bar.has_method("set_hp"):
		health_bar.set_hp(current_hp, max_hp)


func _apply_visuals() -> void:
	pass


func _apply_facing() -> void:
	if visual_root != null:
		visual_root.scale.x = -1.0


func _play_walk_animation() -> void:
	pass


func _spawn_floating_damage_number(amount: int) -> void:
	if not use_floating_damage_numbers:
		return
	if FLOATING_DAMAGE_NUMBER_SCENE == null:
		return

	var effect := FLOATING_DAMAGE_NUMBER_SCENE.instantiate() as Node2D
	if effect == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	parent_node.add_child(effect)
	effect.global_position = _get_floating_damage_spawn_position()

	if effect.has_method("play"):
		effect.play(amount)

func _get_floating_damage_spawn_position() -> Vector2:
	if floating_damage_number_marker != null:
		return floating_damage_number_marker.global_position

	return _get_effect_spawn_position() + floating_damage_offset

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
