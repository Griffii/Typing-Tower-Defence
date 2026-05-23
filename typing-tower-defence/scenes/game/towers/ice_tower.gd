# res://scripts/game/towers/ice_tower.gd
extends Node2D

@export var range_dash_count: int = 36
@export var range_dash_fill: float = 0.55
@export var range_outline_width: float = 2.0
@export var range_outline_rotation_speed: float = 0.65

@export_group("Ice Field Visual")
@export var ice_visual_initial_expand_time: float = 0.75
@export var ice_visual_refresh_interval: float = 10.0
@export var ice_visual_full_alpha: float = 0.72
@export var ice_visual_low_alpha: float = 0.36
@export var ice_visual_restore_time: float = 1.0
@export var ice_field_base_size: Vector2 = Vector2(256.0, 256.0)

@export_group("Crystal Animation")
@export var crystal_intro_time: float = 0.28
@export var crystal_rebound_time: float = 0.12
@export var crystal_settle_time: float = 0.10
@export var crystal_overshoot_scale: Vector2 = Vector2(1.16, 1.16)
@export var crystal_bob_height: float = 7.0
@export var crystal_bob_time: float = 1.15

@export_group("Light Flicker")
@export var light_base_energy: float = 1.0
@export var light_flicker_amount: float = 0.14
@export var light_flicker_speed: float = 3.5

@onready var range_area: Area2D = %RangeArea
@onready var hover_area: Area2D = %HoverArea
@onready var crystal_root: Node2D = %CrystalRoot
@onready var point_light_2d: PointLight2D = %PointLight2D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var ice_field: ColorRect = %IceField

@onready var summon_circle: CPUParticles2D = %SummonCircle
@onready var spawn_sfx: AudioStreamPlayer2D = %SpawnSFX


var slot_id: String = ""
var combat_manager: Node = null
var projectile_container: Node = null

var tower_range: float = 180.0
var slow_multiplier: float = 0.55
var slow_refresh_interval: float = 0.15
var slow_duration: float = 0.25

var slow_refresh_timer: float = 0.0
var ice_visual_timer: float = 0.0
var ice_visual_tween: Tween = null
var ice_field_has_expanded: bool = false

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

	if ice_field != null:
		ice_field.visible = true
		ice_field.modulate.a = 0.0
		ice_field.pivot_offset = ice_field.size * 0.5
		ice_field.position = -ice_field.size * 0.5
		ice_field.scale = Vector2.ZERO

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

	ice_visual_timer = randf_range(0.0, 0.25)
	set_process(true)


func setup_tower(new_slot_id: String, new_combat_manager: Node, new_projectile_container: Node) -> void:
	slot_id = new_slot_id
	combat_manager = new_combat_manager
	projectile_container = new_projectile_container

	if combat_manager != null and combat_manager.has_method("get_tower_stats"):
		var stats: Dictionary = combat_manager.get_tower_stats(slot_id)

		if has_override_range:
			tower_range = override_range
		else:
			tower_range = float(stats.get("range", tower_range))

		slow_multiplier = float(stats.get("slow_multiplier", slow_multiplier))
		slow_refresh_interval = float(stats.get("slow_refresh_interval", slow_refresh_interval))
		slow_duration = float(stats.get("slow_duration", slow_duration))

	_update_range_shapes()

	await get_tree().physics_frame
	_refresh_targets_from_overlaps()


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

	_cleanup_targets()

	slow_refresh_timer -= delta
	if slow_refresh_timer <= 0.0:
		slow_refresh_timer = slow_refresh_interval
		_apply_slow_to_targets()

	ice_visual_timer -= delta
	if ice_visual_timer <= 0.0:
		ice_visual_timer = ice_visual_refresh_interval
		_refresh_ice_field_visual()


func _apply_slow_to_targets() -> void:
	var source_id: String = "ice_tower_%s_%d" % [slot_id, get_instance_id()]

	for enemy in targets_in_range:
		if not _is_valid_enemy(enemy):
			continue

		if enemy.has_method("apply_speed_modifier"):
			enemy.apply_speed_modifier(source_id, slow_multiplier, slow_duration)


func _refresh_ice_field_visual() -> void:
	if ice_field == null:
		return

	if not ice_field_has_expanded:
		_play_initial_ice_field_expansion()
		return

	_pulse_existing_ice_field()


func _play_initial_ice_field_expansion() -> void:
	if ice_field == null:
		return

	if ice_visual_tween != null and ice_visual_tween.is_valid():
		ice_visual_tween.kill()

	var target_scale: Vector2 = _get_ice_field_target_scale()

	if animation_player != null and animation_player.has_animation("fire"):
		animation_player.play("fire")

	ice_field.visible = true
	ice_field.modulate.a = 0.0
	ice_field.scale = Vector2.ZERO

	ice_visual_tween = create_tween()

	ice_visual_tween.parallel().tween_property(
		ice_field,
		"scale",
		target_scale,
		ice_visual_initial_expand_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	ice_visual_tween.parallel().tween_property(
		ice_field,
		"modulate:a",
		ice_visual_full_alpha,
		ice_visual_initial_expand_time
	)

	ice_visual_tween.finished.connect(func() -> void:
		ice_field_has_expanded = true
		_start_ice_field_idle_fade()
	)



func _start_ice_field_idle_fade() -> void:
	if ice_field == null:
		return

	if ice_visual_tween != null and ice_visual_tween.is_valid():
		ice_visual_tween.kill()

	var fade_down_time: float = max(0.1, ice_visual_refresh_interval - ice_visual_restore_time)

	ice_visual_tween = create_tween()
	ice_visual_tween.tween_property(
		ice_field,
		"modulate:a",
		ice_visual_low_alpha,
		fade_down_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _pulse_existing_ice_field() -> void:
	if ice_field == null:
		return

	if ice_visual_tween != null and ice_visual_tween.is_valid():
		ice_visual_tween.kill()

	if animation_player != null and animation_player.has_animation("fire"):
		animation_player.play("fire")

	ice_field.visible = true
	ice_field.scale = _get_ice_field_target_scale()

	ice_visual_tween = create_tween()
	ice_visual_tween.tween_property(
		ice_field,
		"modulate:a",
		ice_visual_full_alpha,
		ice_visual_restore_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	ice_visual_tween.finished.connect(func() -> void:
		_start_ice_field_idle_fade()
	)



func _get_ice_field_target_scale() -> Vector2:
	var diameter: float = tower_range * 2.0
	var safe_size: Vector2 = ice_field_base_size

	if ice_field != null and ice_field.size.x > 0.0 and ice_field.size.y > 0.0:
		safe_size = ice_field.size

	return Vector2(
		diameter / max(1.0, safe_size.x),
		diameter / max(1.0, safe_size.y)
	)


func play_summon_effect() -> void:
	if summon_circle == null:
		return

	summon_circle.restart()
	summon_circle.emitting = true
	
	spawn_sfx.play()


func _play_crystal_intro_animation() -> void:
	if crystal_root == null:
		return
	
	play_summon_effect()

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


func _update_light_flicker(delta: float) -> void:
	if point_light_2d == null:
		return

	light_time += delta

	var wave_a: float = sin(light_time * light_flicker_speed)
	var wave_b: float = sin(light_time * light_flicker_speed * 1.73 + 1.4)
	var combined: float = (wave_a * 0.65) + (wave_b * 0.35)

	point_light_2d.energy = light_base_energy + combined * light_flicker_amount


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


func _is_valid_enemy(node) -> bool:
	if node == null:
		return false

	if not is_instance_valid(node):
		return false

	if not node is Node2D:
		return false

	if not node.is_in_group("enemies"):
		return false

	if node.has_method("is_enemy_dead") and node.is_enemy_dead():
		return false

	return true


func _try_add_target(node) -> void:
	if not _is_valid_enemy(node):
		return

	var enemy: Node2D = node as Node2D

	if targets_in_range.has(enemy):
		return

	targets_in_range.append(enemy)


func _try_remove_target(node) -> void:
	if not _is_valid_enemy(node):
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
