# res://scripts/game/player/player_character.gd
class_name PlayerCharacter
extends Node2D

const SpellDefinitions = preload("res://data/player/spell_definitions.gd")
const DEFAULT_SPECIAL_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/fireball_projectile_01.tscn")

signal special_projectile_impact(target_enemy: Node)
signal player_damaged(amount: int)

@export var special_projectile_scene: PackedScene = DEFAULT_SPECIAL_PROJECTILE_SCENE
@export var projectile_travel_duration: float = 1.0
@export var projectile_arc_height: float = 0.0

@onready var avatar: PlayerAvatar = %PlayerAvatar
@onready var special_meter_bar: ProgressBar = %SpecialMeterBar
@onready var special_spawn_marker: Marker2D = %SpecialSpawnMarker


func _ready() -> void:
	_setup_special_meter()
	_apply_saved_loadout()
	_apply_equipped_spell()


# ---------------------------
# Setup
# ---------------------------
func _setup_special_meter() -> void:
	if special_meter_bar == null:
		return

	special_meter_bar.min_value = 0.0
	special_meter_bar.max_value = 1.0
	special_meter_bar.value = 0.0


func _apply_saved_loadout() -> void:
	PlayerLoadout.load_loadout()

	if avatar == null:
		return

	avatar.apply_loadout(PlayerLoadout.get_loadout())
	avatar.play_idle()


func _apply_equipped_spell() -> void:
	var spell_id: String = PlayerLoadout.get_equipped("spell")
	var scene: PackedScene = SpellDefinitions.get_projectile_scene(spell_id)

	if scene == null:
		special_projectile_scene = DEFAULT_SPECIAL_PROJECTILE_SCENE
		return

	special_projectile_scene = scene


# ---------------------------
# Avatar / Visuals
# ---------------------------
func apply_avatar_loadout(loadout: Dictionary) -> void:
	if avatar == null:
		return

	avatar.apply_loadout(loadout)


func get_avatar() -> PlayerAvatar:
	return avatar


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
func set_special_projectile_scene(new_scene: PackedScene) -> void:
	if new_scene == null:
		return

	special_projectile_scene = new_scene


func fire_special_projectile(target_enemy: Node, projectile_container: Node) -> void:
	_apply_equipped_spell()

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
	print("[PlayerCharacter] special projectile impact: ", target_enemy)
	special_projectile_impact.emit(target_enemy)
