extends Node2D

const TOWER_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/lightning_projectile.tscn")
const WordLists = preload("res://data/words/word_lists.gd")


enum TowerState {
	IDLE,
	ACTIVE,
	COOLDOWN
}

@onready var projectile_spawn: Marker2D = %ProjectileSpawn
@onready var range_area: Area2D = %RangeArea
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var word_label: RichTextLabel = %WordLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx
@onready var lightning_sfx: AudioStreamPlayer2D = %LightningSfx

var slot_id: String = ""
var combat_manager: Node = null
var projectile_container: Node = null

var damage: int = 12
var attack_interval: float = 0.0
var projectile_speed: float = 0.0
var range: float = 99999.0

var charge_required: int = 5
var active_duration: float = 1.5
var cooldown_duration: float = 4.5
var effect_type: String = "lightning_burst"
var targets_per_burst: int = 5

var attack_performed: bool = false
var targets_in_range: Array[Node2D] = []

var tower_state: TowerState = TowerState.IDLE
var current_word: String = ""
var current_charge: int = 0
var state_timer: float = 0.0

var used_tower_words: Array[String] = []
var is_targeted: bool = false
var typing_progress_text: String = ""


func _ready() -> void:
	if range_area != null:
		range_area.body_entered.connect(_on_range_body_entered)
		range_area.body_exited.connect(_on_range_body_exited)

	if word_label != null:
		word_label.bbcode_enabled = true
		word_label.fit_content = true
		word_label.scroll_active = false
		word_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	_assign_new_word()
	_update_ui()
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
	charge_required = int(stats.get("charge_required", charge_required))
	active_duration = float(stats.get("duration", active_duration))
	cooldown_duration = float(stats.get("cooldown", cooldown_duration))
	effect_type = String(stats.get("effect", effect_type))
	targets_per_burst = int(stats.get("targets_per_burst", targets_per_burst))

	_update_range_shape()
	await get_tree().physics_frame
	_refresh_targets_from_overlaps()

	if current_word.is_empty() and tower_state == TowerState.IDLE:
		_assign_new_word()

	_update_ui()
	set_process(damage > 0)


func _process(delta: float) -> void:
	if damage <= 0:
		return

	_cleanup_targets()

	match tower_state:
		TowerState.IDLE:
			pass

		TowerState.ACTIVE:
			state_timer -= delta

			if not attack_performed:
				attack_performed = true
				_fire_lightning_burst()

			if state_timer <= 0.0:
				_enter_cooldown_state()
			else:
				_update_ui()

		TowerState.COOLDOWN:
			state_timer -= delta

			if state_timer <= 0.0:
				_enter_idle_state()
			else:
				_update_ui()


func get_current_word() -> String:
	if tower_state != TowerState.IDLE:
		return ""
	return current_word


func can_accept_word() -> bool:
	return tower_state == TowerState.IDLE and not current_word.is_empty()


func try_charge_with_word(typed_word: String) -> bool:
	if not can_accept_word():
		return false

	if typed_word.strip_edges().to_lower() != current_word.to_lower():
		return false

	complete_current_word()
	return true


func complete_current_word() -> void:
	if not can_accept_word():
		return

	current_charge += 1
	typing_progress_text = ""

	if current_charge >= charge_required:
		_activate_tower()
	else:
		_assign_new_word()

	_update_ui()


func _activate_tower() -> void:
	tower_state = TowerState.ACTIVE
	state_timer = active_duration
	attack_performed = false
	current_word = ""
	typing_progress_text = ""
	_update_ui()


func _enter_cooldown_state() -> void:
	tower_state = TowerState.COOLDOWN
	state_timer = cooldown_duration
	attack_performed = false
	current_word = ""
	typing_progress_text = ""
	_update_ui()


func _enter_idle_state() -> void:
	tower_state = TowerState.IDLE
	state_timer = 0.0
	current_charge = 0
	attack_performed = false
	typing_progress_text = ""
	_assign_new_word()
	_update_ui()


func _assign_new_word() -> void:
	var pool: Array[String] = _get_tower_word_pool()
	current_word = _get_random_word_from_pool(pool, used_tower_words)


func _get_tower_word_pool() -> Array[String]:
	return WordLists.TOWER_WORDS


func _get_random_word_from_pool(all_words: Array[String], used_words: Array[String]) -> String:
	if all_words.is_empty():
		return "spark"

	var available_words: Array[String] = []

	for word in all_words:
		if not used_words.has(word):
			available_words.append(word)

	if available_words.is_empty():
		used_words.clear()
		available_words = all_words.duplicate()

	var chosen_word: String = available_words[randi() % available_words.size()]
	used_words.append(chosen_word)
	return chosen_word


func _build_word_bbcode(input_text: String) -> String:
	if current_word.is_empty():
		return ""

	var bbcode: String = "[center]"

	for i in range(current_word.length()):
		var target_char: String = current_word.substr(i, 1)

		if i < input_text.length():
			var typed_char: String = input_text.substr(i, 1)

			if typed_char == target_char:
				bbcode += "[color=#C9A6FF]" + _escape_bbcode(target_char) + "[/color]"
			else:
				bbcode += "[color=#FF9C9C]" + _escape_bbcode(target_char) + "[/color]"
		else:
			bbcode += "[color=#FFFFFF]" + _escape_bbcode(target_char) + "[/color]"

	bbcode += "[/center]"
	return bbcode


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")


func _update_ui() -> void:
	if progress_bar == null:
		return

	match tower_state:
		TowerState.IDLE:
			if word_label != null:
				word_label.clear()
				word_label.append_text(_build_word_bbcode(typing_progress_text))
				word_label.visible = true

			progress_bar.modulate = Color(0.85, 0.75, 1.0, 1.0)
			progress_bar.max_value = float(charge_required)
			progress_bar.value = float(current_charge)

		TowerState.ACTIVE:
			if word_label != null:
				word_label.visible = false

			progress_bar.modulate = Color(0.75, 0.65, 1.0, 1.0)
			progress_bar.max_value = active_duration
			progress_bar.value = max(state_timer, 0.0)

		TowerState.COOLDOWN:
			if word_label != null:
				word_label.visible = false

			progress_bar.modulate = Color(0.75, 0.65, 1.0, 0.35)
			progress_bar.max_value = cooldown_duration
			progress_bar.value = max(state_timer, 0.0)


func _cleanup_targets() -> void:
	for i in range(targets_in_range.size() - 1, -1, -1):
		var target := targets_in_range[i]
		if not is_instance_valid(target):
			targets_in_range.remove_at(i)
			continue

		if target.has_method("is_enemy_dead") and target.is_enemy_dead():
			targets_in_range.remove_at(i)


func _get_targets_for_burst(max_targets: int) -> Array[Node2D]:
	var valid_targets: Array[Node2D] = []
	var origin: Vector2 = global_position

	for target in targets_in_range:
		if not is_instance_valid(target):
			continue
		if target.has_method("is_enemy_dead") and target.is_enemy_dead():
			continue

		valid_targets.append(target)

	valid_targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return origin.distance_to(a.global_position) < origin.distance_to(b.global_position)
	)

	if valid_targets.size() <= max_targets:
		return valid_targets

	return valid_targets.slice(0, max_targets)


func _fire_lightning_burst() -> void:
	if projectile_container == null or combat_manager == null:
		return

	var burst_targets: Array[Node2D] = _get_targets_for_burst(targets_per_burst)
	if burst_targets.is_empty():
		return

	_play_lightning_burst_sequence(burst_targets)


func _play_lightning_burst_sequence(burst_targets: Array[Node2D]) -> void:
	if shoot_sfx != null:
		shoot_sfx.play()

	await get_tree().create_timer(0.5).timeout

	if tower_state != TowerState.ACTIVE:
		return

	if animation_player != null and animation_player.has_animation("shoot"):
		animation_player.play("shoot")

	if lightning_sfx != null:
		lightning_sfx.play()

	for target in burst_targets:
		if not is_instance_valid(target):
			continue

		if projectile_container != null:
			var projectile = TOWER_PROJECTILE_SCENE.instantiate()
			projectile_container.add_child(projectile)

			if projectile.has_method("fire"):
				projectile.fire(target.global_position, target)

		if combat_manager.has_method("apply_tower_hit"):
			combat_manager.apply_tower_hit(target, damage)


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


func set_targeted(targeted: bool) -> void:
	is_targeted = targeted
	_update_ui()


func set_typing_progress(text: String) -> void:
	typing_progress_text = text
	_update_ui()


func clear_typing_feedback() -> void:
	typing_progress_text = ""
	_update_ui()
