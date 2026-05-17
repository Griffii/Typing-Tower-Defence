# res://scripts/game/portals/lightning_portal.gd
extends Node2D

const LIGHTNING_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/lightning_projectile.tscn")

@onready var projectile_spawn: Marker2D = %ProjectileSpawn
@onready var range_area: Area2D = %RangeArea
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var hover_area: Area2D = %HoverArea
@onready var word_label: RichTextLabel = %WordLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx
@onready var lightning_sfx: AudioStreamPlayer2D = %LightningSfx

var slot_id: String = ""
var combat_manager: Node = null
var projectile_container: Node = null

var damage: int = 18
var portal_range: float = 250.0
var targets_per_burst: int = 5
var time_added_per_word: float = 3.0
var attack_interval: float = 1.5
var max_display_time: float = 30.0

var attack_cooldown: float = 0.0
var active_time_remaining: float = 0.0

var targets_in_range: Array[Node2D] = []
var current_word: String = ""
var word_pool: Array[String] = []
var used_words: Array[String] = []
var is_targeted: bool = false
var typing_progress_text: String = ""

var show_range_outline: bool = false
var range_dash_count: int = 32
var range_dash_fill: float = 0.55
var range_outline_width: float = 2.0


func _ready() -> void:
	add_to_group("typing_targets")
	add_to_group("portals")

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

	if word_label != null:
		word_label.bbcode_enabled = true
		word_label.fit_content = true
		word_label.scroll_active = false
		word_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	_assign_new_word()
	_update_ui()
	set_process(true)


func setup_portal(new_slot_id: String, new_combat_manager: Node, new_projectile_container: Node) -> void:
	slot_id = new_slot_id
	combat_manager = new_combat_manager
	projectile_container = new_projectile_container

	if combat_manager != null and combat_manager.has_method("get_portal_stats"):
		var stats: Dictionary = combat_manager.get_portal_stats(slot_id)
		damage = int(stats.get("damage", damage))
		portal_range = float(stats.get("range", portal_range))
		targets_per_burst = int(stats.get("targets_per_burst", targets_per_burst))
		time_added_per_word = float(stats.get("time_added_per_word", time_added_per_word))
		attack_interval = float(stats.get("attack_interval", attack_interval))

	elif combat_manager != null and combat_manager.has_method("get_tower_stats"):
		var stats: Dictionary = combat_manager.get_tower_stats(slot_id)
		damage = int(stats.get("damage", damage))
		portal_range = float(stats.get("range", portal_range))
		targets_per_burst = int(stats.get("targets_per_burst", targets_per_burst))
		time_added_per_word = float(stats.get("time_added_per_word", stats.get("duration", time_added_per_word)))
		attack_interval = float(stats.get("attack_interval", attack_interval))

	_update_range_shape()

	await get_tree().physics_frame
	_refresh_targets_from_overlaps()

	if current_word.is_empty():
		_assign_new_word()

	_update_ui()
	set_process(damage > 0)


func setup_tower(new_slot_id: String, new_combat_manager: Node, new_projectile_container: Node) -> void:
	setup_portal(new_slot_id, new_combat_manager, new_projectile_container)


func set_word_pool(new_words: Array[String]) -> void:
	word_pool.clear()

	for word in new_words:
		var clean_word := str(word).strip_edges()
		if not clean_word.is_empty():
			word_pool.append(clean_word)

	used_words.clear()
	_assign_new_word()
	_update_ui()


func set_override_range(new_range: float) -> void:
	portal_range = new_range
	_update_range_shape()
	_refresh_targets_from_overlaps()


func _process(delta: float) -> void:
	if damage <= 0:
		return

	_cleanup_targets()

	if active_time_remaining > 0.0:
		active_time_remaining = max(0.0, active_time_remaining - delta)
		attack_cooldown -= delta

		if attack_cooldown <= 0.0:
			_fire_lightning_burst()
			attack_cooldown = attack_interval
	else:
		attack_cooldown = 0.0

	_update_ui()


# ---------------------------
# Typing target interface
# ---------------------------

func get_current_word() -> String:
	return current_word


func can_accept_word() -> bool:
	return not current_word.is_empty()


func complete_current_word() -> void:
	if not can_accept_word():
		return

	active_time_remaining += time_added_per_word
	typing_progress_text = ""
	_assign_new_word()
	_update_ui()


func try_charge_with_word(typed_word: String) -> bool:
	if not can_accept_word():
		return false

	if typed_word.strip_edges().to_lower() != current_word.to_lower():
		return false

	complete_current_word()
	return true


func set_targeted(targeted: bool) -> void:
	is_targeted = targeted
	_update_ui()


func set_typing_progress(text: String) -> void:
	typing_progress_text = text
	_update_ui()


func clear_typing_feedback() -> void:
	typing_progress_text = ""
	_update_ui()


# ---------------------------
# Word handling
# ---------------------------

func _assign_new_word() -> void:
	current_word = _get_random_word_from_pool(word_pool, used_words)


func _get_random_word_from_pool(all_words: Array[String], used_word_list: Array[String]) -> String:
	if all_words.is_empty():
		return "spark"

	var available_words: Array[String] = []

	for word in all_words:
		if not used_word_list.has(word):
			available_words.append(word)

	if available_words.is_empty():
		used_word_list.clear()
		available_words = all_words.duplicate()

	var chosen_word: String = available_words[randi() % available_words.size()]
	used_word_list.append(chosen_word)
	return chosen_word


# ---------------------------
# UI
# ---------------------------

func _update_ui() -> void:
	if word_label != null:
		word_label.clear()
		word_label.append_text(_build_word_bbcode(typing_progress_text))
		word_label.visible = true

	if progress_bar != null:
		progress_bar.max_value = max_display_time
		progress_bar.value = clamp(active_time_remaining, 0.0, max_display_time)


func _build_word_bbcode(input_text: String) -> String:
	if current_word.is_empty():
		return ""

	var bbcode: String = "[center]"

	for i in range(current_word.length()):
		var target_char: String = current_word.substr(i, 1)

		if i < input_text.length():
			var typed_char: String = input_text.substr(i, 1)

			if typed_char.to_lower() == target_char.to_lower():
				bbcode += "[color=#C9A6FF]" + _escape_bbcode(target_char) + "[/color]"
			else:
				bbcode += "[color=#FF9C9C]" + _escape_bbcode(target_char) + "[/color]"
		else:
			bbcode += "[color=#FFFFFF]" + _escape_bbcode(target_char) + "[/color]"

	bbcode += "[/center]"
	return bbcode


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")


# ---------------------------
# Attack
# ---------------------------

func _fire_lightning_burst() -> void:
	var burst_targets: Array[Node2D] = _get_targets_for_burst(targets_per_burst)
	if burst_targets.is_empty():
		return

	_play_lightning_burst_sequence(burst_targets)


func _play_lightning_burst_sequence(burst_targets: Array[Node2D]) -> void:
	if shoot_sfx != null:
		shoot_sfx.play()

	if animation_player != null and animation_player.has_animation("shoot"):
		animation_player.play("shoot")

	if lightning_sfx != null:
		lightning_sfx.play()

	for target in burst_targets:
		if not is_instance_valid(target):
			continue

		if projectile_container != null and LIGHTNING_PROJECTILE_SCENE != null:
			var projectile = LIGHTNING_PROJECTILE_SCENE.instantiate()
			projectile_container.add_child(projectile)

			if projectile.has_method("fire"):
				projectile.fire(target.global_position, target)

		if target.has_method("take_damage"):
			target.take_damage(damage)
		elif target.has_method("apply_damage"):
			target.apply_damage(damage)


func _get_targets_for_burst(max_targets: int) -> Array[Node2D]:
	_cleanup_targets()

	var valid_targets: Array[Node2D] = []
	var origin: Vector2 = global_position

	if projectile_spawn != null:
		origin = projectile_spawn.global_position

	for target in targets_in_range:
		if not is_instance_valid(target):
			continue
		if target.has_method("is_enemy_dead") and target.is_enemy_dead():
			continue

		var dist := origin.distance_to(target.global_position)
		if dist > portal_range:
			continue

		valid_targets.append(target)

	valid_targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return origin.distance_to(a.global_position) < origin.distance_to(b.global_position)
	)

	if valid_targets.size() <= max_targets:
		return valid_targets

	return valid_targets.slice(0, max_targets)


# ---------------------------
# Range / target tracking
# ---------------------------

func _cleanup_targets() -> void:
	for i in range(targets_in_range.size() - 1, -1, -1):
		var target := targets_in_range[i]

		if not is_instance_valid(target):
			targets_in_range.remove_at(i)
			continue

		if target.has_method("is_enemy_dead") and target.is_enemy_dead():
			targets_in_range.remove_at(i)


func _update_range_shape() -> void:
	if range_area != null:
		var shape_node: CollisionShape2D = range_area.get_node_or_null("CollisionShape2D")
		if shape_node != null:
			var circle := shape_node.shape as CircleShape2D
			if circle == null:
				circle = CircleShape2D.new()
				shape_node.shape = circle

			circle.radius = portal_range

	queue_redraw()


func _draw() -> void:
	if not show_range_outline:
		return

	var dash_angle := TAU / float(range_dash_count)

	for i in range(range_dash_count):
		var start_angle := float(i) * dash_angle
		var end_angle := start_angle + dash_angle * range_dash_fill

		var start_pos := Vector2(cos(start_angle), sin(start_angle)) * portal_range
		var end_pos := Vector2(cos(end_angle), sin(end_angle)) * portal_range

		draw_line(start_pos, end_pos, Color(1, 1, 1, 0.85), range_outline_width)


func _refresh_targets_from_overlaps() -> void:
	targets_in_range.clear()

	if range_area == null:
		return

	for body in range_area.get_overlapping_bodies():
		_try_add_target(body)

	for area in range_area.get_overlapping_areas():
		_try_add_target(area)


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
