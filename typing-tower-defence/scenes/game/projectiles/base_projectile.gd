# res://scripts/game/projectiles/base_projectile.gd
class_name BaseProjectile
extends Node2D

signal impact_reached(target_enemy: Node)
signal projectile_finished

@export var speed: float = 800.0
@export var impact_distance: float = 14.0
@export var max_lifetime: float = 4.0
@export var target_offset: Vector2 = Vector2.ZERO
@export var enemy_group_name: String = "enemies"

var target_enemy: Node = null
var fallback_target_position: Vector2 = Vector2.ZERO
var spell_data: Dictionary = {}

var has_impacted: bool = false
var has_finished: bool = false
var is_flying: bool = false
var lifetime: float = 0.0


func setup_spell(data: Dictionary) -> void:
	spell_data = data.duplicate(true)


func fire(from_pos: Vector2, target: Node, _duration: float = 1.0, _height: float = 0.0) -> void:
	global_position = from_pos
	target_enemy = target
	lifetime = 0.0
	has_impacted = false
	has_finished = false
	is_flying = true

	if is_instance_valid(target_enemy) and target_enemy is Node2D:
		fallback_target_position = (target_enemy as Node2D).global_position + target_offset
	else:
		fallback_target_position = from_pos

	_on_fired()


func _process(delta: float) -> void:
	if not is_flying:
		return

	lifetime += delta

	if lifetime >= max_lifetime:
		_on_impact()
		return

	var target_position: Vector2 = fallback_target_position

	if is_instance_valid(target_enemy) and target_enemy is Node2D:
		target_position = (target_enemy as Node2D).global_position + target_offset
		fallback_target_position = target_position

	var to_target: Vector2 = target_position - global_position
	var distance: float = to_target.length()

	if distance <= impact_distance:
		global_position = target_position
		_on_impact()
		return

	var move_distance: float = speed * delta

	if move_distance >= distance:
		global_position = target_position
		_on_impact()
		return

	global_position += to_target.normalized() * move_distance
	rotation = to_target.angle()


func _on_impact() -> void:
	if has_impacted:
		return

	has_impacted = true
	is_flying = false

	_apply_area_effects()

	if is_instance_valid(target_enemy):
		impact_reached.emit(target_enemy)

	_on_impact_started()


func _apply_area_effects() -> void:
	var aoe_radius: float = float(spell_data.get("base_aoe_radius", 0.0))
	var effects: Array = spell_data.get("effects", [])

	if aoe_radius <= 0.0:
		return

	for enemy: Node in get_tree().get_nodes_in_group(enemy_group_name):
		if not _is_valid_enemy_in_area(enemy, aoe_radius):
			continue

		for effect: Dictionary in effects:
			_apply_effect_to_enemy(enemy, effect)


func _is_valid_enemy_in_area(enemy: Node, aoe_radius: float) -> bool:
	if not is_instance_valid(enemy):
		return false
	if not enemy is Node2D:
		return false
	if enemy.has_method("is_enemy_dead") and enemy.is_enemy_dead():
		return false

	return global_position.distance_to((enemy as Node2D).global_position) <= aoe_radius


func _apply_effect_to_enemy(enemy: Node, effect: Dictionary) -> void:
	var effect_type: String = str(effect.get("type", ""))
	var base_damage: int = int(spell_data.get("base_damage", 0))

	match effect_type:
		"damage":
			if enemy.has_method("apply_damage"):
				enemy.apply_damage(base_damage)

		"slow":
			if enemy.has_method("apply_slow"):
				var slow_multiplier: float = float(effect.get("multiplier", 0.5))
				var duration: float = float(effect.get("duration", 2.0))
				enemy.apply_slow(slow_multiplier, duration)


func _on_fired() -> void:
	pass


func _on_impact_started() -> void:
	_finish_after_delay(0.1)


func _finish_after_delay(delay: float) -> void:
	if has_finished:
		return

	await get_tree().create_timer(delay).timeout
	_finish_projectile()


func _finish_projectile() -> void:
	if has_finished:
		return

	has_finished = true
	projectile_finished.emit()
	queue_free()
