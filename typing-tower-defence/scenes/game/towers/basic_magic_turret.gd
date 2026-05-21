# res://scripts/game/towers/basic_magic_turret.gd
extends Node2D

const MAGIC_PROJECTILE_SCENE: PackedScene = preload("uid://hkis3ut0qmh5")

@export var range_dash_count: int = 36
@export var range_dash_fill: float = 0.55
@export var range_outline_width: float = 2.0
@export var range_outline_rotation_speed: float = 0.65

@export_group("Crystal Animation")
@export var crystal_intro_time: float = 0.28
@export var crystal_rebound_time: float = 0.12
@export var crystal_settle_time: float = 0.10
@export var crystal_overshoot_scale: Vector2 = Vector2(1.16, 1.16)
@export var crystal_bob_height: float = 7.0
@export var crystal_bob_time: float = 1.15

@export_group("Light Flicker")
@export var light_base_energy: float = 1.15
@export var light_flicker_amount: float = 0.18
@export var light_flicker_speed: float = 4.0

@onready var projectile_spawn: Marker2D = %ProjectileSpawn
@onready var range_area: Area2D = %RangeArea
@onready var hover_area: Area2D = %HoverArea

@onready var crystal_root: Node2D = %CrystalRoot
@onready var point_light_2d: PointLight2D = %PointLight2D

var slot_id: String = ""
var combat_manager: Node = null
var projectile_container: Node = null

var damage: int = 4
var attack_interval: float = 0.65
var projectile_speed: float = 480.0
var tower_range: float = 220.0
var targeting: String = "nearest"

var attack_timer: float = 0.0
var targets_in_range: Array[Node2D] = []

var show_range_outline: bool = false
var range_outline_rotation: float = 0.0
var has_override_range: bool = false
var override_range: float = 0.0

var crystal_base_position: Vector2 = Vector2.ZERO
var crystal_bob_tween: Tween = null
var crystal_intro_tween: Tween = null
var light_time: float = 0.0


func _ready() -> void:
	add_to_group("towers")

	if crystal_root != null:
		crystal_base_position = crystal_root.position
		_play_crystal_intro_animation()

	if point_light_2d != null:
		point_light_2d.energy = 0.0

	if range_area != null:
		if not range_area.body_entered.is_connected(_on_range_body_entered):
			range_area.body_entered.connect(_on_range_body_entered)

		if not range_area.body_exited.is_connected(_on_range_body_exited):
			range_area.body_exited.connect(_on_range_body_exited)

		if not range_area.area_entered.is_connected(_on_range_area_entered):
			range_area.area_entered.connect(_on_range_area_entered)

		if not range_area.area_exited.is_connected(_on_range_area_exited):
			range_area.area_exited.connect(_on_range_area_exited)

	if hover_area != null:
		hover_area.input_pickable = true

		if not hover_area.mouse_entered.is_connected(_on_hover_area_mouse_entered):
			hover_area.mouse_entered.connect(_on_hover_area_mouse_entered)

		if not hover_area.mouse_exited.is_connected(_on_hover_area_mouse_exited):
			hover_area.mouse_exited.connect(_on_hover_area_mouse_exited)

	_update_range_shapes()
	set_process(true)


func _play_crystal_intro_animation() -> void:
	if crystal_root == null:
		return

	if crystal_intro_tween != null and crystal_intro_tween.is_valid():
		crystal_intro_tween.kill()

	if crystal_bob_tween != null and crystal_bob_tween.is_valid():
		crystal_bob_tween.kill()

	crystal_root.position = crystal_base_position
	crystal_root.scale = Vector2.ZERO
	crystal_root.modulate.a = 0.0

	crystal_intro_tween = create_tween()

	crystal_intro_tween.parallel().tween_property(
		crystal_root,
		"modulate:a",
		1.0,
		crystal_intro_time
	)

	crystal_intro_tween.parallel().tween_property(
		crystal_root,
		"scale",
		crystal_overshoot_scale,
		crystal_intro_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if point_light_2d != null:
		crystal_intro_tween.parallel().tween_property(
			point_light_2d,
			"energy",
			light_base_energy,
			crystal_intro_time
		)

	crystal_intro_tween.tween_property(
		crystal_root,
		"scale",
		Vector2(0.92, 0.92),
		crystal_rebound_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	crystal_intro_tween.tween_property(
		crystal_root,
		"scale",
		Vector2.ONE,
		crystal_settle_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	crystal_intro_tween.finished.connect(func() -> void:
		_start_crystal_bob_animation()
	)


func _start_crystal_bob_animation() -> void:
	if crystal_root == null:
		return

	if crystal_bob_tween != null and crystal_bob_tween.is_valid():
		crystal_bob_tween.kill()

	crystal_bob_tween = create_tween()
	crystal_bob_tween.set_loops()

	crystal_bob_tween.tween_property(
		crystal_root,
		"position:y",
		crystal_base_position.y - crystal_bob_height,
		crystal_bob_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	crystal_bob_tween.tween_property(
		crystal_root,
		"position:y",
		crystal_base_position.y,
		crystal_bob_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func setup_tower(new_slot_id: String, new_combat_manager: Node, new_projectile_container: Node) -> void:
	slot_id = new_slot_id
	combat_manager = new_combat_manager
	projectile_container = new_projectile_container

	if combat_manager != null and combat_manager.has_method("get_tower_stats"):
		var stats: Dictionary = combat_manager.get_tower_stats(slot_id)

		damage = int(stats.get("damage", damage))
		attack_interval = float(stats.get("attack_interval", attack_interval))
		projectile_speed = float(stats.get("projectile_speed", projectile_speed))

		if has_override_range:
			tower_range = override_range
		else:
			tower_range = float(stats.get("range", tower_range))

		targeting = str(stats.get("targeting", targeting))

	_update_range_shapes()

	await get_tree().physics_frame
	_refresh_targets_from_overlaps()

	attack_timer = randf_range(0.0, attack_interval)


func set_override_range(new_range: float) -> void:
	has_override_range = true
	override_range = new_range
	tower_range = new_range

	_update_range_shapes()

	await get_tree().physics_frame
	_refresh_targets_from_overlaps()


func _process(delta: float) -> void:
	_update_light_flicker(delta)

	if show_range_outline:
		range_outline_rotation += delta * range_outline_rotation_speed
		queue_redraw()

	if damage <= 0:
		return

	if attack_interval <= 0.0:
		return

	_cleanup_targets()

	attack_timer -= delta
	if attack_timer > 0.0:
		return

	var target: Node2D = _get_target()
	if target == null:
		attack_timer = 0.1
		return

	_fire_at_target(target)
	attack_timer = attack_interval


func _update_light_flicker(delta: float) -> void:
	if point_light_2d == null:
		return

	light_time += delta

	var wave_a: float = sin(light_time * light_flicker_speed)
	var wave_b: float = sin(light_time * light_flicker_speed * 1.73 + 1.4)
	var combined: float = (wave_a * 0.65) + (wave_b * 0.35)

	point_light_2d.energy = light_base_energy + combined * light_flicker_amount


func _get_target() -> Node2D:
	match targeting:
		"nearest":
			return _get_nearest_target()

		_:
			return _get_nearest_target()


func _get_nearest_target() -> Node2D:
	_cleanup_targets()

	var nearest: Node2D = null
	var nearest_distance: float = INF
	var origin: Vector2 = global_position

	if projectile_spawn != null:
		origin = projectile_spawn.global_position

	for target in targets_in_range:
		if not _is_valid_enemy(target):
			continue

		var distance: float = origin.distance_to(target.global_position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest = target

	return nearest


func _fire_at_target(target: Node2D) -> void:
	if not _is_valid_enemy(target):
		return

	var from_pos: Vector2 = global_position
	if projectile_spawn != null:
		from_pos = projectile_spawn.global_position

	if MAGIC_PROJECTILE_SCENE != null and projectile_container != null:
		var projectile: Node = MAGIC_PROJECTILE_SCENE.instantiate()
		projectile_container.add_child(projectile)

		if projectile.has_method("fire"):
			projectile.fire(
				from_pos,
				target,
				damage,
				combat_manager,
				projectile_speed
			)
			return

	if combat_manager != null and combat_manager.has_method("apply_tower_hit"):
		combat_manager.apply_tower_hit(target, damage)
	elif target.has_method("apply_damage"):
		target.apply_damage(damage)


func _speed_to_duration(speed_value: float) -> float:
	if speed_value <= 0.0:
		return 0.25

	return clamp(140.0 / speed_value, 0.12, 0.45)


func _update_range_shapes() -> void:
	_set_area_radius(range_area, tower_range)
	queue_redraw()


func _set_area_radius(area: Area2D, radius: float) -> void:
	if area == null:
		return

	var shape_node: CollisionShape2D = area.get_node_or_null("CollisionShape2D")
	if shape_node == null:
		return

	var circle: CircleShape2D = shape_node.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		shape_node.shape = circle

	circle.radius = radius


func _draw() -> void:
	if not show_range_outline:
		return

	if tower_range <= 0.0:
		return

	var dash_angle: float = TAU / float(range_dash_count)

	for i in range(range_dash_count):
		var start_angle: float = range_outline_rotation + float(i) * dash_angle
		var end_angle: float = start_angle + dash_angle * range_dash_fill

		var start_pos: Vector2 = Vector2(cos(start_angle), sin(start_angle)) * tower_range
		var end_pos: Vector2 = Vector2(cos(end_angle), sin(end_angle)) * tower_range

		draw_line(start_pos, end_pos, Color(1.0, 1.0, 1.0, 0.85), range_outline_width)


func _refresh_targets_from_overlaps() -> void:
	targets_in_range.clear()

	if range_area == null:
		return

	for body in range_area.get_overlapping_bodies():
		_try_add_target(body)

	for area in range_area.get_overlapping_areas():
		_try_add_target(area)


func _cleanup_targets() -> void:
	for i in range(targets_in_range.size() - 1, -1, -1):
		var target: Node2D = targets_in_range[i]

		if not _is_valid_enemy(target):
			targets_in_range.remove_at(i)


func _is_valid_enemy(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false

	if not node is Node2D:
		return false

	if not node.is_in_group("enemies"):
		return false

	if node.has_method("is_enemy_dead") and node.is_enemy_dead():
		return false

	return true


func _try_add_target(node: Node) -> void:
	if not _is_valid_enemy(node):
		return

	var enemy: Node2D = node as Node2D

	if targets_in_range.has(enemy):
		return

	targets_in_range.append(enemy)


func _try_remove_target(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	if not node is Node2D:
		return

	var enemy: Node2D = node as Node2D
	var index: int = targets_in_range.find(enemy)

	if index != -1:
		targets_in_range.remove_at(index)


func _on_range_body_entered(body: Node) -> void:
	_try_add_target(body)


func _on_range_body_exited(body: Node) -> void:
	_try_remove_target(body)


func _on_range_area_entered(area: Area2D) -> void:
	_try_add_target(area)


func _on_range_area_exited(area: Area2D) -> void:
	_try_remove_target(area)


func _on_hover_area_mouse_entered() -> void:
	show_range_outline = true
	queue_redraw()


func _on_hover_area_mouse_exited() -> void:
	show_range_outline = false
	queue_redraw()
