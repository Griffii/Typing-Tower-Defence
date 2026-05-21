# res://scripts/game/projectiles/magic_turret_projectile.gd
extends Node2D

signal impact_reached(target_enemy: Node)
signal projectile_finished

@export var impact_distance: float = 14.0
@export var max_lifetime: float = 4.0
@export var target_offset: Vector2 = Vector2.ZERO
@export var fade_in_time: float = 0.06

@onready var projectile_sprite: AnimatedSprite2D = %FireballSprite
@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx
@onready var impact_sfx: AudioStreamPlayer2D = %ExplosionSfx

var target_enemy: Node = null
var fallback_target_position: Vector2 = Vector2.ZERO
var combat_manager: Node = null

var damage: int = 0
var speed: float = 480.0
var lifetime: float = 0.0

var has_impacted: bool = false
var has_finished: bool = false
var is_flying: bool = false

var original_sprite_scale: Vector2 = Vector2.ONE
var fade_tween: Tween = null


func _ready() -> void:
	modulate.a = 0.0

	if projectile_sprite != null:
		original_sprite_scale = projectile_sprite.scale


func fire(from_pos: Vector2, target: Node, new_damage: int, new_combat_manager: Node, new_speed: float = 480.0) -> void:
	global_position = from_pos
	target_enemy = target
	damage = new_damage
	combat_manager = new_combat_manager
	speed = new_speed

	lifetime = 0.0
	has_impacted = false
	has_finished = false
	is_flying = true

	modulate.a = 0.0

	if is_instance_valid(target_enemy) and target_enemy is Node2D:
		fallback_target_position = (target_enemy as Node2D).global_position + target_offset
	else:
		fallback_target_position = from_pos

	var initial_direction: Vector2 = fallback_target_position - global_position
	if initial_direction.length() > 0.001:
		rotation = initial_direction.angle()

	if projectile_sprite != null:
		projectile_sprite.visible = true
		projectile_sprite.scale = original_sprite_scale

		if projectile_sprite.sprite_frames != null and projectile_sprite.sprite_frames.has_animation("fly"):
			projectile_sprite.play("fly")

	_start_fade_in()

	if shoot_sfx != null:
		shoot_sfx.play()

	set_process(true)


func _start_fade_in() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	if fade_in_time <= 0.0:
		modulate.a = 1.0
		return

	fade_tween = create_tween()
	fade_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		fade_in_time
	)


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
	set_process(false)

	modulate.a = 1.0

	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	if is_instance_valid(target_enemy):
		if combat_manager != null and combat_manager.has_method("apply_tower_hit"):
			combat_manager.apply_tower_hit(target_enemy, damage)
		elif target_enemy.has_method("apply_damage"):
			target_enemy.apply_damage(damage)

		impact_reached.emit(target_enemy)

	if impact_sfx != null:
		impact_sfx.play()

	if projectile_sprite == null:
		_finish_after_delay(1.0)
		return

	rotation = 0.0
	projectile_sprite.scale = original_sprite_scale

	if projectile_sprite.sprite_frames != null and projectile_sprite.sprite_frames.has_animation("explode"):
		if not projectile_sprite.animation_finished.is_connected(_on_explosion_finished):
			projectile_sprite.animation_finished.connect(_on_explosion_finished)

		projectile_sprite.play("explode")
	else:
		_finish_after_delay(1.0)


func _on_explosion_finished() -> void:
	if projectile_sprite != null:
		projectile_sprite.scale = original_sprite_scale

	_finish_after_delay(0.15)


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
