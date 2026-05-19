# res://scripts/game/projectiles/magic_turret_projectile.gd
extends BaseProjectile

@onready var projectile_sprite: AnimatedSprite2D = %FireballSprite
@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx
@onready var impact_sfx: AudioStreamPlayer2D = %ExplosionSfx

var original_sprite_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	if projectile_sprite != null:
		original_sprite_scale = projectile_sprite.scale


func _on_fired() -> void:
	if projectile_sprite != null:
		projectile_sprite.visible = true
		projectile_sprite.scale = original_sprite_scale

		if projectile_sprite.sprite_frames != null and projectile_sprite.sprite_frames.has_animation("fly"):
			projectile_sprite.play("fly")

	if shoot_sfx != null:
		shoot_sfx.play()


func _on_impact_started() -> void:
	if impact_sfx != null:
		impact_sfx.play()

	if projectile_sprite == null:
		_finish_after_delay(1.0)
		return

	rotation = 0.0
	projectile_sprite.rotation = 0.0
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
