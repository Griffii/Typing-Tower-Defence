extends CharacterBody2D

signal enemy_died(enemy: Node)
signal enemy_reached_base(enemy: Node)

@export var move_speed: float = 50.0
@export var max_hp: int = 22
@export var reward_score: int = 10
@export var reward_gold: int = 1
@export var base_reach_distance: float = 8.0
@export var base_attack_damage: int = 2
@export var base_attack_interval: float = 1.0

@onready var visual_root: Node2D = %VisualRoot
@onready var label_root: Node2D = %LabelRoot

@onready var body_sprite: Sprite2D = %Body
@onready var weapon_sprite: Sprite2D = %Weapon
@onready var shield_sprite: Sprite2D = %Shield

@onready var word_label: RichTextLabel = %WordLabel
@onready var hp_label: Label = %HpLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer

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

var current_hp: int = 22
var current_word: String = ""
var enemy_type: String = "grunt"
var enemy_id: String = ""

var is_dead: bool = false
var has_reached_base: bool = false
var is_targeted: bool = false
var is_attack_anim_active: bool = false
var is_damage_anim_active: bool = false

var base_target: Node2D = null
var base_attack_timer: float = 0.0


func _ready() -> void:
	current_hp = max_hp

	if word_label != null:
		word_label.bbcode_enabled = true
		word_label.fit_content = true
		word_label.scroll_active = false

	_apply_random_visuals()
	_apply_facing()
	_update_labels()
	_play_walk_animation()


func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if has_reached_base:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(base_target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_base: Vector2 = base_target.global_position - global_position
	var distance_to_base: float = to_base.length()

	if distance_to_base <= base_reach_distance:
		has_reached_base = true
		velocity = Vector2.ZERO
		move_and_slide()
		base_attack_timer = 0.0
		play_attack_animation()
		enemy_reached_base.emit(self)
		return

	var direction: Vector2 = to_base.normalized()
	velocity = direction * move_speed
	move_and_slide()

	_play_walk_animation()


func setup_enemy(enemy_data: Dictionary) -> void:
	enemy_type = str(enemy_data.get("enemy_type", "grunt"))
	enemy_id = str(enemy_data.get("enemy_id", ""))

	move_speed = float(enemy_data.get("speed", move_speed))
	max_hp = int(enemy_data.get("max_hp", max_hp))
	reward_score = int(enemy_data.get("reward_score", reward_score))
	reward_gold = int(enemy_data.get("reward_gold", reward_gold))
	current_word = str(enemy_data.get("word", ""))

	var base_target_variant: Variant = enemy_data.get("base_target", null)
	if base_target_variant is Node2D:
		base_target = base_target_variant as Node2D

	current_hp = max_hp
	has_reached_base = false
	is_dead = false
	is_targeted = false
	is_attack_anim_active = false
	is_damage_anim_active = false
	base_attack_timer = 0.0

	_apply_random_visuals()
	_apply_facing()
	_update_labels()
	_play_walk_animation()


func has_reached_base_target() -> bool:
	return has_reached_base

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


func play_attack_animation() -> void:
	if animation_player == null:
		return
	if is_dead or is_attack_anim_active:
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


func play_take_damage_animation() -> void:
	if animation_player == null:
		return
	if is_dead:
		return
	if not animation_player.has_animation("take_damage"):
		return

	# Do not interrupt death.
	# Allow hit reaction to briefly override walk/attack, then return.
	is_damage_anim_active = true
	animation_player.play("take_damage")
	await animation_player.animation_finished
	is_damage_anim_active = false

	if is_dead:
		return

	if has_reached_base:
		play_attack_animation()
	else:
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

	enemy_died.emit(self)
	queue_free()


func is_enemy_dead() -> bool:
	return is_dead


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
