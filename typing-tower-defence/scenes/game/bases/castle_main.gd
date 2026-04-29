extends Node2D

const DEFAULT_ARROW_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/castle_arrow_projectile.tscn")
const HEART_BURST_SCENE: PackedScene = preload("res://scenes/game/effects/heart_burst.tscn")

signal castle_projectile_impact(target_enemy: Node)


@onready var base_marker: Marker2D = %BaseMarker
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var castle_health_bar: Control = %CastleHealthBar



# ---------------------------
# Health Bar passthrough
# ---------------------------
func set_base_hp(current_hp: int, max_hp: int) -> void:
	if castle_health_bar == null:
		return

	if castle_health_bar.has_method("set_base_hp"):
		castle_health_bar.set_base_hp(current_hp, max_hp)


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


# ---------------------------
# Signals
# ---------------------------
func _on_projectile_impact(target_enemy: Node) -> void:
	castle_projectile_impact.emit(target_enemy)
