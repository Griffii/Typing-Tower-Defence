# res://scripts/game/effects/floating_damage_number.gd
extends Node2D

@onready var damage_label: Label = %DamageLabel

@export var launch_force_min: float = 135.0
@export var launch_force_max: float = 210.0
@export var horizontal_force_min: float = -70.0
@export var horizontal_force_max: float = 70.0
@export var gravity: float = 520.0
@export var duration_min: float = 0.75
@export var duration_max: float = 1.05
@export var start_scale_min: float = 0.85
@export var start_scale_max: float = 1.15
@export var pop_scale: float = 1.65
@export var rotation_range_degrees: float = 22.0
@export var spin_speed_min: float = -90.0
@export var spin_speed_max: float = 90.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.0
var duration: float = 0.85
var spin_speed: float = 0.0
var has_started: bool = false


func play(value: Variant) -> void:
	if damage_label != null:
		damage_label.text = str(value)

	lifetime = 0.0
	duration = randf_range(duration_min, duration_max)
	has_started = true

	velocity = Vector2(
		randf_range(horizontal_force_min, horizontal_force_max),
		-randf_range(launch_force_min, launch_force_max)
	)

	spin_speed = randf_range(spin_speed_min, spin_speed_max)

	modulate.a = 1.0
	scale = Vector2.ONE * randf_range(start_scale_min, start_scale_max)
	rotation_degrees = randf_range(-rotation_range_degrees, rotation_range_degrees)

	var pop_tween := create_tween()
	pop_tween.tween_property(self, "scale", Vector2.ONE * pop_scale, 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(self, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not has_started:
		return

	lifetime += delta

	velocity.y += gravity * delta
	global_position += velocity * delta
	rotation_degrees += spin_speed * delta

	var progress: float = clampf(lifetime / duration, 0.0, 1.0)

	if progress > 0.35:
		modulate.a = 1.0 - ((progress - 0.35) / 0.65)

	if progress >= 1.0:
		queue_free()
