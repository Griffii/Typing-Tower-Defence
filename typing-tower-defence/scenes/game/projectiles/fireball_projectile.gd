# res://scripts/game/projectiles/fireball_projectile.gd
extends BaseProjectile

@export var explosion_sprite_base_radius: float = 32.0

@onready var fireball_sprite: AnimatedSprite2D = %FireballSprite
@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx
@onready var explosion_sfx: AudioStreamPlayer2D = %ExplosionSfx

var original_sprite_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	if fireball_sprite != null:
		original_sprite_scale = fireball_sprite.scale


func _on_fired() -> void:
	if fireball_sprite != null:
		fireball_sprite.visible = true
		fireball_sprite.scale = original_sprite_scale

		if fireball_sprite.sprite_frames != null and fireball_sprite.sprite_frames.has_animation("fly"):
			fireball_sprite.play("fly")

	if shoot_sfx != null:
		shoot_sfx.play()


func _on_impact_started() -> void:
	if explosion_sfx != null:
		explosion_sfx.play()

	if fireball_sprite == null:
		_finish_after_delay(1.0)
		return

	rotation = 0.0
	fireball_sprite.rotation = 0.0
	_scale_sprite_to_aoe_radius()

	if fireball_sprite.sprite_frames != null and fireball_sprite.sprite_frames.has_animation("explode"):
		if not fireball_sprite.animation_finished.is_connected(_on_explosion_finished):
			fireball_sprite.animation_finished.connect(_on_explosion_finished)

		fireball_sprite.play("explode")
	else:
		_finish_after_delay(1.0)


func _scale_sprite_to_aoe_radius() -> void:
	if fireball_sprite == null:
		return

	var aoe_radius: float = float(spell_data.get("base_aoe_radius", 0.0))
	if aoe_radius <= 0.0:
		fireball_sprite.scale = original_sprite_scale
		return

	var scale_factor: float = aoe_radius / explosion_sprite_base_radius
	fireball_sprite.scale = original_sprite_scale * scale_factor


func _on_explosion_finished() -> void:
	if fireball_sprite != null:
		fireball_sprite.scale = original_sprite_scale

	_finish_after_delay(0.15)
