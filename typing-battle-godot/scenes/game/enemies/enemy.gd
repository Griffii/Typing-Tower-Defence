extends CharacterBody2D

signal enemy_died(enemy: Node)
signal enemy_reached_base(enemy: Node)

const ENEMY_STATS := {
	"grunt": {
		"move_speed": 50.0,
		"max_hp": 22,
		"reward_gold": 8,
		"base_attack_damage": 2,
		"base_attack_interval": 1.5,
	},
	"scout": {
		"move_speed": 80.0,
		"max_hp": 11,
		"reward_gold": 10,
		"base_attack_damage": 1,
		"base_attack_interval": 1.0,
	},
	"tank": {
		"move_speed": 30.0,
		"max_hp": 60,
		"reward_gold": 15,
		"base_attack_damage": 3,
		"base_attack_interval": 2.0,
	},
	"boss": {
		"move_speed": 20.0,
		"max_hp": 1000,
		"reward_gold": 100,
		"base_attack_damage": 10,
		"base_attack_interval": 3.0,
	},
}

const BODY_TEXTURES: Array[String] = [
	"res://assets/images/soldiers/soldier_01.png",
	"res://assets/images/soldiers/soldier_02.png",
	"res://assets/images/soldiers/soldier_03.png",
]

const WEAPON_TEXTURES: Array[String] = [
	"res://assets/images/soldiers/weapon_01.png",
	"res://assets/images/soldiers/weapon_02.png",
	"res://assets/images/soldiers/weapon_03.png",
	"res://assets/images/soldiers/weapon_04.png",
]

@export var base_reach_distance: float = 8.0

@onready var visual_root: Node2D = %VisualRoot
@onready var label_root: Node2D = %LabelRoot

@onready var body_sprite: Sprite2D = %Body
@onready var weapon_sprite: Sprite2D = %Weapon
@onready var shield_sprite: Sprite2D = %Shield

@onready var word_label: RichTextLabel = %WordLabel
@onready var hp_label: Label = %HpLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer


var move_speed: float = 40.0
var max_hp: int = 10
var reward_score: int = 10
var reward_gold: int = 1
var base_attack_damage: int = 1
var base_attack_interval: float = 1.0

var current_hp: int = 10
var current_word: String = ""
var enemy_type: String = ""
var enemy_id: String = ""

var is_dead: bool = false
var has_reached_base: bool = false
var is_targeted: bool = false
var is_attack_anim_active: bool = false
var is_damage_anim_active: bool = false

var base_target: Node2D = null
var base_attack_timer: float = 0.0

# For attacking things - Not used since we removed soldiers
var current_target: Node = null
var targets_in_range: Array[Node] = []

# Setting the pathing to the castle
var path_points: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var path_reach_distance: float = 6.0


func _ready() -> void:
	if word_label != null:
		word_label.bbcode_enabled = true
		word_label.fit_content = true
		word_label.scroll_active = false
	
	add_to_group("enemies")
	
	_apply_random_visuals()
	_apply_facing()
	_update_labels()
	_play_walk_animation()


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_cleanup_targets()

	if is_instance_valid(current_target):
		velocity = Vector2.ZERO
		move_and_slide()

		base_attack_timer -= delta
		if base_attack_timer <= 0.0:
			base_attack_timer = base_attack_interval
			play_attack_animation()

			if is_instance_valid(current_target) and current_target.has_method("apply_damage"):
				current_target.apply_damage(base_attack_damage)
		return

	if has_reached_base:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if path_points.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# If we've reached the final point → treat as base reached
	if path_index >= path_points.size():
		has_reached_base = true
		velocity = Vector2.ZERO
		move_and_slide()
		base_attack_timer = 0.0
		play_attack_animation()
		enemy_reached_base.emit(self)
		return

	var target_point: Vector2 = path_points[path_index]
	var to_point: Vector2 = target_point - global_position
	var distance: float = to_point.length()

	# Advance to next point
	if distance <= path_reach_distance:
		path_index += 1
		return

	var direction: Vector2 = to_point.normalized()
	velocity = direction * move_speed
	move_and_slide()

	_play_walk_animation()


func setup_enemy(enemy_data: Dictionary) -> void:
	enemy_type = str(enemy_data.get("enemy_type", ""))
	enemy_id = str(enemy_data.get("enemy_id", ""))
	
	_apply_type_stats(enemy_type)
	
	current_word = str(enemy_data.get("word", ""))
	
	var raw_points: Variant = enemy_data.get("path_points", PackedVector2Array())
	if raw_points is PackedVector2Array:
		path_points = raw_points
	
	current_hp = max_hp
	has_reached_base = false
	is_dead = false
	is_targeted = false
	is_attack_anim_active = false
	is_damage_anim_active = false
	base_attack_timer = 0.0
	path_index = 0
	
	_apply_random_visuals()
	_apply_facing()
	_update_labels()
	_play_walk_animation()


func _apply_type_stats(type_name: String) -> void:
	var stats: Dictionary = ENEMY_STATS.get(type_name, ENEMY_STATS["grunt"])

	move_speed = float(stats.get("move_speed", 40.0))
	max_hp = int(stats.get("max_hp", 10))
	reward_score = int(stats.get("reward_score", 10))
	reward_gold = int(stats.get("reward_gold", 1))
	base_attack_damage = int(stats.get("base_attack_damage", 1))
	base_attack_interval = float(stats.get("base_attack_interval", 1.0))


func process_base_attack(delta: float, combat_manager: Node) -> void:
	if is_dead:
		return

	if not has_reached_base:
		return

	base_attack_timer -= delta
	if base_attack_timer > 0.0:
		return

	base_attack_timer = base_attack_interval
	play_attack_animation()

	if combat_manager != null and combat_manager.has_method("apply_base_damage"):
		combat_manager.apply_base_damage(base_attack_damage)


func set_base_target(target: Node2D) -> void:
	base_target = target


func set_word(new_word: String) -> void:
	current_word = new_word
	clear_typing_feedback()


func assign_new_word(new_word: String) -> void:
	set_word(new_word)


func set_targeted(targeted: bool) -> void:
	is_targeted = targeted
	clear_typing_feedback()


func set_typing_progress(typed_text: String) -> void:
	if word_label == null:
		return

	word_label.text = _build_word_bbcode(typed_text)


func clear_typing_feedback() -> void:
	_update_labels()


func apply_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp = max(0, current_hp - amount)
	_update_labels()

	if current_hp <= 0:
		die()
		return

	play_take_damage_animation()


func play_take_damage_animation() -> void:
	if animation_player == null:
		return
	if is_dead:
		return
	if is_damage_anim_active:
		return
	if not animation_player.has_animation("take_damage"):
		return
	
	is_damage_anim_active = true
	animation_player.play("take_damage")
	await animation_player.animation_finished
	is_damage_anim_active = false
	
	if is_dead:
		return
	
	if not has_reached_base:
		_play_walk_animation()


func play_attack_animation() -> void:
	if animation_player == null:
		return
	if is_dead or is_attack_anim_active or is_damage_anim_active:
		return
	if not animation_player.has_animation("attack"):
		return

	is_attack_anim_active = true
	animation_player.play("attack")
	await animation_player.animation_finished
	is_attack_anim_active = false

	if is_dead:
		return

	if not has_reached_base:
		_play_walk_animation()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	clear_typing_feedback()

	if animation_player != null and animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	
	current_target = null
	targets_in_range.clear()
	
	enemy_died.emit(self)
	queue_free()


func is_enemy_dead() -> bool:
	return is_dead


func has_reached_base_target() -> bool:
	return has_reached_base


func get_current_word() -> String:
	return current_word


func get_enemy_type() -> String:
	return enemy_type


func get_reward_score() -> int:
	return reward_score


func get_reward_gold() -> int:
	return reward_gold


func _update_labels() -> void:
	if word_label != null:
		word_label.text = _build_word_bbcode("")

	if hp_label != null:
		hp_label.text = "%d / %d" % [current_hp, max_hp]


func _build_word_bbcode(input_text: String) -> String:
	if current_word.is_empty():
		return ""

	var bbcode: String = "[center]"

	for i in range(current_word.length()):
		var target_char: String = current_word.substr(i, 1)

		if i < input_text.length():
			var typed_char: String = input_text.substr(i, 1)

			if typed_char == target_char:
				bbcode += "[color=#9CFF9C]" + _escape_bbcode(target_char) + "[/color]"
			else:
				bbcode += "[color=#FF9C9C]" + _escape_bbcode(target_char) + "[/color]"
		else:
			bbcode += "[color=#FFFFFF]" + _escape_bbcode(target_char) + "[/color]"

	bbcode += "[/center]"
	return bbcode


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")


func _play_walk_animation() -> void:
	if animation_player == null:
		return
	if is_dead or has_reached_base or is_attack_anim_active or is_damage_anim_active:
		return
	if not animation_player.has_animation("walk"):
		return

	if animation_player.current_animation != "walk" or not animation_player.is_playing():
		animation_player.play("walk")


func _apply_random_visuals() -> void:
	var hash_source: String = enemy_id
	if hash_source.is_empty():
		hash_source = "%s_%s_%d" % [enemy_type, current_word, get_instance_id()]

	var hash_value: int = abs(hash_source.hash())

	if body_sprite != null and BODY_TEXTURES.size() > 0:
		var body_index: int = hash_value % BODY_TEXTURES.size()
		body_sprite.texture = load(BODY_TEXTURES[body_index])

	if weapon_sprite != null and WEAPON_TEXTURES.size() > 0:
		var weapon_index: int = (hash_value / 5) % WEAPON_TEXTURES.size()
		weapon_sprite.texture = load(WEAPON_TEXTURES[weapon_index])

	if shield_sprite != null:
		var shield_visible: bool = ((hash_value / 11) % 2) == 0
		shield_sprite.visible = shield_visible


func _apply_facing() -> void:
	if visual_root != null:
		visual_root.scale.x = -1.0

	if label_root != null:
		label_root.scale.x = 1.0


func _on_detection_body_entered(body: Node) -> void:
	_try_add_target(body)


func _on_detection_body_exited(body: Node) -> void:
	_remove_target(body)


func _on_detection_area_entered(area: Area2D) -> void:
	_try_add_target(area.get_parent())


func _on_detection_area_exited(area: Area2D) -> void:
	_remove_target(area.get_parent())


func _try_add_target(candidate: Node) -> void:
	if is_dead:
		return
	if candidate == null or not is_instance_valid(candidate):
		return
	if not candidate.is_in_group("soldiers"):
		return
	if candidate.has_method("is_soldier_dead") and candidate.is_soldier_dead():
		return
	if targets_in_range.has(candidate):
		return

	targets_in_range.append(candidate)
	_try_set_next_target()


func _remove_target(candidate: Node) -> void:
	var idx: int = targets_in_range.find(candidate)
	if idx != -1:
		targets_in_range.remove_at(idx)

	if candidate == current_target:
		current_target = null
		_try_set_next_target()


func _cleanup_targets() -> void:
	for i in range(targets_in_range.size() - 1, -1, -1):
		var target: Node = targets_in_range[i]
		if not is_instance_valid(target):
			targets_in_range.remove_at(i)
			continue
		if target.has_method("is_soldier_dead") and target.is_soldier_dead():
			targets_in_range.remove_at(i)

	if current_target != null:
		if not is_instance_valid(current_target):
			current_target = null
		elif current_target.has_method("is_soldier_dead") and current_target.is_soldier_dead():
			current_target = null

	if current_target == null:
		_try_set_next_target()


func _try_set_next_target() -> void:
	if current_target != null and is_instance_valid(current_target):
		return

	if targets_in_range.is_empty():
		current_target = null
		return

	current_target = targets_in_range[0]
	base_attack_timer = 0.0
