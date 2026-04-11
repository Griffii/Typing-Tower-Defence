extends Node2D

signal projectile_finished

@onready var animated_sprite: AnimatedSprite2D = %LightningSprite


var target_enemy: Node = null
var has_finished: bool = false


func fire(on_pos: Vector2, target: Node = null) -> void:
	target_enemy = target
	global_position = on_pos
	
	if animated_sprite != null:
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
	
		animated_sprite.visible = true
		animated_sprite.play()
	else:
		_finish_projectile()


func _on_animation_finished() -> void:
	if has_finished:
		return
		
	_finish_projectile()


func _finish_projectile() -> void:
	if has_finished:
		return
	
	has_finished = true
	projectile_finished.emit()
	queue_free()
