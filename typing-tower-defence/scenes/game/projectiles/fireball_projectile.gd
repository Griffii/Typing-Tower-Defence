# res://scripts/game/projectiles/fireball_projectile.gd
extends Node2D

signal impact_reached(target_enemy: Node)
signal projectile_finished

@export var speed: float = 600.0
@export var impact_distance: float = 14.0
@export var max_lifetime: float = 4.0
@export var target_offset: Vector2 = Vector2.ZERO

@onready var fireball_sprite: AnimatedSprite2D = %FireballSprite
@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx
@onready var explosion_sfx: AudioStreamPlayer2D = %ExplosionSfx

var target_enemy: Node = null
var fallback_target_position: Vector2 = Vector2.ZERO
var has_impacted: bool = false
var is_flying: bool = false
var lifetime: float = 0.0


func fire(from_pos: Vector2, target: Node, _duration: float = 1.0, _height: float = 0.0) -> void:
	global_position = from_pos
	target_enemy = target
	lifetime = 0.0
	has_impacted = false
	is_flying = true

	if is_instance_valid(target_enemy) and target_enemy is Node2D:
		fallback_target_position = (target_enemy as Node2D).global_position + target_offset
	else:
		fallback_target_position = from_pos

	if fireball_sprite != null:
		fireball_sprite.visible = true
		if fireball_sprite.sprite_frames != null and fireball_sprite.sprite_frames.has_animation("fly"):
			fireball_sprite.play("fly")

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
		impact_reached.emit(target_enemy)

	if explosion_sfx != null:
		explosion_sfx.play()

	if fireball_sprite != null:
		rotation = 0.0
		fireball_sprite.rotation = 0.0
		fireball_sprite.play("explode")
	else:
		_finish_after_delay(0.25)


func _on_explosion_finished() -> void:
	_finish_projectile()


func _finish_after_delay(delay: float) -> void:
	var timer := get_tree().create_timer(delay)
	await timer.timeout
	_finish_projectile()


func _finish_projectile() -> void:
	projectile_finished.emit()
	queue_free()
