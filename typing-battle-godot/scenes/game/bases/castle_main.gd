extends Node2D

const DEFAULT_ARROW_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/castle_arrow_projectile.tscn")
const HEART_BURST_SCENE: PackedScene = preload("res://scenes/game/effects/heart_burst.tscn")

signal castle_projectile_impact(target_enemy: Node)

@export var projectile_scene: PackedScene = DEFAULT_ARROW_PROJECTILE_SCENE
@export var projectile_travel_duration: float = 0.35
@export var projectile_arc_height: float = 48.0

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var arrow_spawn_marker: Marker2D = %ArrowSpawnMarker
@onready var base_marker: Marker2D = %BaseMarker
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# Reference to your NEW health bar scene
@onready var castle_health_bar: Control = %CastleHealthBar


func _ready() -> void:
	if progress_bar != null:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0


# ---------------------------
# NEW: Health Bar passthrough
# ---------------------------
func set_base_hp(current_hp: int, max_hp: int) -> void:
	if castle_health_bar == null:
		return

	if castle_health_bar.has_method("set_base_hp"):
		castle_health_bar.set_base_hp(current_hp, max_hp)


# ---------------------------
# Arrow Meter (unchanged)
# ---------------------------
func set_arrow_meter(current_value: float, max_value: float) -> void:
	if progress_bar == null:
		return

	progress_bar.max_value = max(0.001, max_value)
	progress_bar.value = clampf(current_value, 0.0, progress_bar.max_value)


func reset_arrow_meter() -> void:
	if progress_bar == null:
		return

	progress_bar.value = 0.0


# ---------------------------
# Position Helpers
# ---------------------------
func get_arrow_spawn_position() -> Vector2:
	if arrow_spawn_marker == null:
		return global_position

	return arrow_spawn_marker.global_position


func get_base_position() -> Vector2:
	if base_marker == null:
		return global_position

	return base_marker.global_position


# ---------------------------
# Projectile Logic
# ---------------------------
func fire_castle_projectile(target_enemy: Node, projectile_container: Node) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return
	if projectile_container == null or not is_instance_valid(projectile_container):
		return
	if projectile_scene == null:
		return

	var spawn_position: Vector2 = get_arrow_spawn_position()

	var projectile: Node = projectile_scene.instantiate()
	projectile_container.add_child(projectile)

	if projectile.has_signal("impact_reached"):
		projectile.impact_reached.connect(_on_projectile_impact)

	if projectile.has_method("fire"):
		projectile.fire(
			spawn_position,
			target_enemy,
			projectile_travel_duration,
			projectile_arc_height
		)


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
