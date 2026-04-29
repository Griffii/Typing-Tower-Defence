# res://scripts/game/player/player_character.gd
class_name PlayerCharacter
extends Node2D

const DEFAULT_SPECIAL_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/castle_arrow_projectile.tscn")

signal special_projectile_impact(target_enemy: Node)
signal player_damaged(amount: int)

@export var special_projectile_scene: PackedScene = DEFAULT_SPECIAL_PROJECTILE_SCENE
@export var projectile_travel_duration: float = 0.35
@export var projectile_arc_height: float = 48.0

@onready var special_meter_bar: ProgressBar = %SpecialMeterBar
@onready var special_spawn_marker: Marker2D = %SpecialSpawnMarker


func _ready() -> void:
	if special_meter_bar != null:
		special_meter_bar.min_value = 0.0
		special_meter_bar.max_value = 1.0
		special_meter_bar.value = 0.0


# ---------------------------
# Special Meter
# ---------------------------
func set_special_meter(current_value: float, max_value: float) -> void:
	if special_meter_bar == null:
		return

	special_meter_bar.max_value = max(0.001, max_value)
	special_meter_bar.value = clampf(current_value, 0.0, special_meter_bar.max_value)


func reset_special_meter() -> void:
	if special_meter_bar == null:
		return

	special_meter_bar.value = 0.0


# ---------------------------
# Position Helpers
# ---------------------------
func get_special_spawn_position() -> Vector2:
	if special_spawn_marker == null:
		return global_position

	return special_spawn_marker.global_position


# ---------------------------
# Projectile / Spell Logic
# ---------------------------
func fire_special_projectile(target_enemy: Node, projectile_container: Node) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return
	if projectile_container == null or not is_instance_valid(projectile_container):
		return
	if special_projectile_scene == null:
		return

	var spawn_position: Vector2 = get_special_spawn_position()

	var projectile: Node = special_projectile_scene.instantiate()
	projectile_container.add_child(projectile)

	if projectile.has_signal("impact_reached"):
		projectile.impact_reached.connect(_on_special_projectile_impact)

	if projectile.has_method("fire"):
		projectile.fire(
			spawn_position,
			target_enemy,
			projectile_travel_duration,
			projectile_arc_height
		)

func request_level_damage(amount: int) -> void:
	if amount <= 0:
		return
	
	player_damaged.emit(amount)


# ---------------------------
# Signals
# ---------------------------
func _on_special_projectile_impact(target_enemy: Node) -> void:
	special_projectile_impact.emit(target_enemy)
