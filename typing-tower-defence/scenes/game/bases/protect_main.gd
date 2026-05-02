extends Node2D

const HEART_BURST_SCENE: PackedScene = preload("res://scenes/game/effects/heart_burst.tscn")


@onready var base_marker: Marker2D = %BaseMarker
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var health_bar: Control = %HealthBar



# ---------------------------
# Health Bar passthrough
# ---------------------------
func set_base_hp(current_hp: int, max_hp: int) -> void:
	if health_bar == null:
		return

	if health_bar.has_method("set_base_hp"):
		health_bar.set_base_hp(current_hp, max_hp)


func get_base_position() -> Vector2:
	if base_marker == null:
		return global_position

	return base_marker.global_position



# ---------------------------
# Animations / Effects
# ---------------------------
func play_take_damage() -> void:
	if animation_player == null:
		return
	if not animation_player.has_animation("take_damage"):
		return
	
	animation_player.stop()
	animation_player.play("take_damage")


func spawn_repair_burst() -> void:
	if HEART_BURST_SCENE == null:
		return

	var burst: Node2D = HEART_BURST_SCENE.instantiate() as Node2D
	if burst == null:
		return

	get_tree().current_scene.add_child(burst)
	burst.global_position = get_base_position()
