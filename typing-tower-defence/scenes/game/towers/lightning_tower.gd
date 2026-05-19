extends Node2D

const TOWER_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/lightning_projectile.tscn")

@onready var projectile_spawn: Marker2D = %ProjectileSpawn
@onready var range_area: Area2D = %RangeArea
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx
@onready var lightning_sfx: AudioStreamPlayer2D = %LightningSfx

var slot_id: String = ""
var combat_manager: Node = null
var projectile_container: Node = null

var damage: int = 8
var attack_interval: float = 1.6
var projectile_speed: float = 9999.0
var range: float = 260.0
var chain_range: float = 120.0
var max_chain_targets: int = 4
var targeting: String = "nearest"

var attack_timer: float = 0.0
var targets_in_range: Array[Node2D] = []


func _ready() -> void:
	if range_area != null:
		if not range_area.body_entered.is_connected(_on_range_body_entered):
			range_area.body_entered.connect(_on_range_body_entered)

		if not range_area.body_exited.is_connected(_on_range_body_exited):
			range_area.body_exited.connect(_on_range_body_exited)

	set_process(false)


func setup_tower(new_slot_id: String, new_combat_manager: Node, new_projectile_container: Node) -> void:
	slot_id = new_slot_id
	combat_manager = new_combat_manager
	projectile_container = new_projectile_container

	if combat_manager == null or not combat_manager.has_method("get_tower_stats"):
		return

	var stats: Dictionary = combat_manager.get_tower_stats(slot_id)

	damage = int(stats.get("damage", damage))
	attack_interval = float(stats.get("attack_interval", attack_interval))
	projectile_speed = float(stats.get("projectile_speed", projectile_speed))
	range = float(stats.get("range", range))
	chain_range = float(stats.get("chain_range", chain_range))
	max_chain_targets = int(stats.get("max_chain_targets", max_chain_targets))
	targeting = str(stats.get("targeting", targeting))

	_update_range_shape()

	await get_tree().physics_frame
	_refresh_targets_from_overlaps()

	attack_timer = randf_range(0.0, attack_interval)
	set_process(damage > 0 and attack_interval > 0.0)


func _process(delta: float) -> void:
	if damage <= 0:
		return

	_cleanup_targets()

	attack_timer -= delta
	if attack_timer > 0.0:
		return

	attack_timer = attack_interval
	_fire_chain_lightning()


func _fire_chain_lightning() -> void:
	if combat_manager == null or projectile_container == null:
		return

	var first_target: Node2D = _get_first_target()
	if first_target == null:
		return

	var chain_targets: Array[Node2D] = _build_chain_targets(first_target)
	if chain_targets.is_empty():
		return

	_play_chain_lightning_sequence(chain_targets)


func _get_first_target() -> Node2D:
	_cleanup_targets()

	if targets_in_range.is_empty():
		return null

	match targeting:
		"nearest":
			return _get_nearest_target_to_position(global_position, targets_in_range)

		_:
			return _get_nearest_target_to_position(global_position, targets_in_range)


func _build_chain_targets(first_target: Node2D) -> Array[Node2D]:
	var chain_targets: Array[Node2D] = []

	if not _is_valid_enemy(first_target):
		return chain_targets

	chain_targets.append(first_target)

	var current_target: Node2D = first_target

	while chain_targets.size() < max_chain_targets:
		var next_target: Node2D = _get_next_chain_target(current_target, chain_targets)

		if next_target == null:
			break

		chain_targets.append(next_target)
		current_target = next_target

	return chain_targets


func _get_next_chain_target(from_target: Node2D, already_hit: Array[Node2D]) -> Node2D:
	if from_target == null or not is_instance_valid(from_target):
		return null

	var candidates: Array[Node2D] = []

	for enemy in targets_in_range:
		if not _is_valid_enemy(enemy):
			continue

		if already_hit.has(enemy):
			continue

		var distance: float = from_target.global_position.distance_to(enemy.global_position)
		if distance <= chain_range:
			candidates.append(enemy)

	if candidates.is_empty():
		return null

	return _get_nearest_target_to_position(from_target.global_position, candidates)


func _get_nearest_target_to_position(origin: Vector2, candidates: Array[Node2D]) -> Node2D:
	var nearest_target: Node2D = null
	var nearest_distance: float = INF

	for enemy in candidates:
		if not _is_valid_enemy(enemy):
			continue

		var distance: float = origin.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = enemy

	return nearest_target


func _play_chain_lightning_sequence(chain_targets: Array[Node2D]) -> void:
	if shoot_sfx != null:
		shoot_sfx.play()

	if animation_player != null and animation_player.has_animation("shoot"):
		animation_player.play("shoot")

	if lightning_sfx != null:
		lightning_sfx.play()

	var previous_position: Vector2 = global_position
	if projectile_spawn != null:
		previous_position = projectile_spawn.global_position

	for target in chain_targets:
		if not _is_valid_enemy(target):
			continue

		_spawn_lightning_projectile(previous_position, target)

		if combat_manager.has_method("apply_tower_hit"):
			combat_manager.apply_tower_hit(target, damage)

		previous_position = target.global_position


func _spawn_lightning_projectile(from_position: Vector2, target: Node2D) -> void:
	if projectile_container == null:
		return
	if target == null or not is_instance_valid(target):
		return

	var projectile = TOWER_PROJECTILE_SCENE.instantiate()
	projectile_container.add_child(projectile)

	if projectile.has_method("fire"):
		projectile.fire(from_position, target)


func _is_valid_enemy(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not enemy is Node2D:
		return false
	if not enemy.is_in_group("enemies"):
		return false
	if enemy.has_method("is_enemy_dead") and enemy.is_enemy_dead():
		return false

	return true


func _cleanup_targets() -> void:
	for i in range(targets_in_range.size() - 1, -1, -1):
		var target := targets_in_range[i]
		if not _is_valid_enemy(target):
			targets_in_range.remove_at(i)


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
	if not _is_valid_enemy(node):
		return

	var enemy := node as Node2D

	if targets_in_range.has(enemy):
		return

	targets_in_range.append(enemy)


func _try_remove_target(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not node is Node2D:
		return

	var enemy := node as Node2D
	var index := targets_in_range.find(enemy)

	if index != -1:
		targets_in_range.remove_at(index)


func _on_range_body_entered(body: Node) -> void:
	_try_add_target(body)


func _on_range_body_exited(body: Node) -> void:
	_try_remove_target(body)
