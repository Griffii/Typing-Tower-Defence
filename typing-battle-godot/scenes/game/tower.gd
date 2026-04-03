extends Node2D

const TOWER_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/tower_projectile.tscn")

@onready var projectile_spawn: Marker2D = %ProjectileSpawn
@onready var range_area: Area2D = %RangeArea

var slot_id: String = ""
var combat_manager: Node = null
var projectile_container: Node = null

var damage: int = 2
var attack_interval: float = 1.0
var projectile_speed: float = 400.0
var range: float = 250.0

var attack_cooldown: float = 0.0
var targets_in_range: Array[Node2D] = []


func _ready() -> void:
	if range_area != null:
		range_area.body_entered.connect(_on_range_body_entered)
		range_area.body_exited.connect(_on_range_body_exited)


func setup_tower(new_slot_id: String, new_combat_manager: Node, new_projectile_container: Node) -> void:
	slot_id = new_slot_id
	combat_manager = new_combat_manager
	projectile_container = new_projectile_container

	if combat_manager == null or not combat_manager.has_method("get_tower_stats"):
		return

	var stats: Dictionary = combat_manager.get_tower_stats(slot_id)
	damage = int(stats.get("damage", 0))
	attack_interval = float(stats.get("attack_interval", 1.0))
	projectile_speed = float(stats.get("projectile_speed", 400.0))
	range = float(stats.get("range", 250.0))

	_update_range_shape()
	await get_tree().physics_frame
	_refresh_targets_from_overlaps()

	set_process(damage > 0)


func _process(delta: float) -> void:
	if damage <= 0:
		return

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		return

	_cleanup_targets()

	var target := _get_nearest_target_in_range()
	if target == null:
		return

	_fire_at_target(target)
	attack_cooldown = attack_interval


func _cleanup_targets() -> void:
	for i in range(targets_in_range.size() - 1, -1, -1):
		var target := targets_in_range[i]
		if not is_instance_valid(target):
			targets_in_range.remove_at(i)
			continue

		if target.has_method("is_enemy_dead") and target.is_enemy_dead():
			targets_in_range.remove_at(i)


func _get_nearest_target_in_range() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	var origin: Vector2 = projectile_spawn.global_position

	for target in targets_in_range:
		if not is_instance_valid(target):
			continue
		if target.has_method("is_enemy_dead") and target.is_enemy_dead():
			continue

		var dist := origin.distance_to(target.global_position)
		if dist < nearest_distance:
			nearest_distance = dist
			nearest = target

	return nearest


func _fire_at_target(target: Node2D) -> void:
	if projectile_container == null:
		return

	var projectile = TOWER_PROJECTILE_SCENE.instantiate()
	projectile_container.add_child(projectile)

	if projectile.has_method("fire"):
		projectile.fire(
			projectile_spawn.global_position,
			target,
			damage,
			combat_manager,
			_speed_to_duration(projectile_speed),
			48.0
		)


func _speed_to_duration(speed_value: float) -> float:
	if speed_value <= 0.0:
		return 0.35

	return clamp(140.0 / speed_value, 0.18, 0.6)


func _update_range_shape() -> void:
	if range_area == null:
		return

	var shape_node: CollisionShape2D = range_area.get_node_or_null("CollisionShape2D")
	if shape_node == null:
		return

	var circle := shape_node.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		shape_node.shape = circle

	circle.radius = range


func _refresh_targets_from_overlaps() -> void:
	targets_in_range.clear()

	if range_area == null:
		return

	var overlapping_bodies = range_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		_try_add_target(body)


func _try_add_target(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not (node is Node2D):
		return
	if not node.is_in_group("enemies"):
		return

	var enemy := node as Node2D

	if targets_in_range.has(enemy):
		return

	targets_in_range.append(enemy)


func _try_remove_target(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not (node is Node2D):
		return
	if not node.is_in_group("enemies"):
		return

	var enemy := node as Node2D
	var index := targets_in_range.find(enemy)
	if index != -1:
		targets_in_range.remove_at(index)


func _on_range_body_entered(body: Node) -> void:
	_try_add_target(body)


func _on_range_body_exited(body: Node) -> void:
	_try_remove_target(body)
