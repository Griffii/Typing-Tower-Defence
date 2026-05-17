# res://scripts/game/projectiles/magic_beam_projectile.gd
extends Node2D

signal impact_reached(target_enemy: Node)
signal projectile_finished

@export var speed: float = 800.0
@export var impact_distance: float = 14.0
@export var max_lifetime: float = 4.0
@export var target_offset: Vector2 = Vector2.ZERO
@export var finish_delay_after_impact: float = 0.15

@onready var projectile_sprite: AnimatedSprite2D = %FireballSprite
@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx
@onready var impact_sfx: AudioStreamPlayer2D = %ExplosionSfx

var target_enemy: Node = null
var damage: int = 0
var fallback_target_position: Vector2 = Vector2.ZERO

var has_impacted: bool = false
var has_finished: bool = false
var is_flying: bool = false
var lifetime: float = 0.0


func fire(
	from_pos: Vector2,
	target: Node,
	damage_amount: int = 0,
	_combat_manager: Node = null,
	_duration: float = 1.0,
	_height: float = 0.0
) -> void:
	global_position = from_pos
	target_enemy = target
	damage = damage_amount

	lifetime = 0.0
	has_impacted = false
	has_finished = false
	is_flying = true

	if is_instance_valid(target_enemy) and target_enemy is Node2D:
		fallback_target_position = (target_enemy as Node2D).global_position + target_offset
	else:
		fallback_target_position = from_pos

	if projectile_sprite != null:
		projectile_sprite.visible = true

		if projectile_sprite.sprite_frames != null and projectile_sprite.sprite_frames.has_animation("fly"):
			projectile_sprite.play("fly")

	if shoot_sfx != null:
		shoot_sfx.play()


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

	if is_instance_valid(target_enemy):
		if target_enemy.has_method("take_damage"):
			target_enemy.take_damage(damage)
		elif target_enemy.has_method("apply_damage"):
			target_enemy.apply_damage(damage)

		impact_reached.emit(target_enemy)

	if impact_sfx != null:
		impact_sfx.play()

	if projectile_sprite == null:
		_finish_after_delay(finish_delay_after_impact)
		return

	rotation = 0.0
	projectile_sprite.rotation = 0.0

	if projectile_sprite.sprite_frames != null and projectile_sprite.sprite_frames.has_animation("explode"):
		if not projectile_sprite.animation_finished.is_connected(_on_impact_animation_finished):
			projectile_sprite.animation_finished.connect(_on_impact_animation_finished)

		projectile_sprite.play("explode")
	else:
		_finish_after_delay(finish_delay_after_impact)


func _on_impact_animation_finished() -> void:
	_finish_after_delay(finish_delay_after_impact)


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
