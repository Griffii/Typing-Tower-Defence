extends Node2D

@onready var anim_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D

var finished: bool = false


func _ready() -> void:
	if anim_sprite == null:
		queue_free()
		return

	# Ensure it doesn't loop
	if anim_sprite.sprite_frames != null:
		anim_sprite.sprite_frames.set_animation_loop(anim_sprite.animation, false)

	# Connect signal once
	if not anim_sprite.animation_finished.is_connected(_on_animation_finished):
		anim_sprite.animation_finished.connect(_on_animation_finished)

	# Play audio ONLY if a stream is assigned
	if audio_stream_player_2d and audio_stream_player_2d.stream:
		audio_stream_player_2d.play()

	anim_sprite.play()


func _on_animation_finished() -> void:
	if finished:
		return

	finished = true
	queue_free()
