extends CharacterBody2D

signal soldier_died(soldier: Node)

@export var max_hp: int = 25
@export var move_speed: float = 40.0
@export var attack_damage: int = 2
@export var attack_interval: float = 1.0

@onready var visual_root: Node2D = %VisualRoot
@onready var label_root: Node2D = %LabelRoot

@onready var body_sprite: Sprite2D = %Body
@onready var weapon_sprite: Sprite2D = %Weapon
@onready var shield_sprite: Sprite2D = %Shield

@onready var hp_label: Label = %HpLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var detection_area: Area2D = %DetectionArea

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

var current_hp: int = 10
var soldier_id: String = ""

var is_dead: bool = false
var is_attack_anim_active: bool = false
var is_damage_anim_active: bool = false

var current_target: Node = null
var attack_timer: float = 0.0
var targets_in_range: Array[Node] = []


func _ready() -> void:
	add_to_group("soldiers")

	if hp_label != null:
		_update_labels()

	if detection_area != null:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
		detection_area.area_entered.connect(_on_detection_area_entered)
		detection_area.area_exited.connect(_on_detection_area_exited)

	_apply_random_visuals()
	_update_labels()
	_play_walk_animation()


func setup_soldier(soldier_data: Dictionary) -> void:
	soldier_id = str(soldier_data.get("soldier_id", ""))

	max_hp = int(soldier_data.get("max_hp", max_hp))
	move_speed = float(soldier_data.get("move_speed", move_speed))
	attack_damage = int(soldier_data.get("attack_damage", attack_damage))
	attack_interval = float(soldier_data.get("attack_interval", attack_interval))

	current_hp = max_hp
	is_dead = false
	is_attack_anim_active = false
	is_damage_anim_active = false
	current_target = null
	attack_timer = 0.0

	_apply_random_visuals()
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

		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = attack_interval
			play_attack_animation()

			if is_instance_valid(current_target) and current_target.has_method("apply_damage"):
				current_target.apply_damage(attack_damage)
		return

	velocity = Vector2.RIGHT * move_speed
	move_and_slide()
	_play_walk_animation()


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
	if is_dead or is_damage_anim_active:
		return
	if not animation_player.has_animation("take_damage"):
		return

	is_damage_anim_active = true
	animation_player.play("take_damage")
	await animation_player.animation_finished
	is_damage_anim_active = false

	if is_dead:
		return

	if is_instance_valid(current_target):
		play_attack_animation()
	else:
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

	if not is_instance_valid(current_target):
		_play_walk_animation()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	if animation_player != null and animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished

	current_target = null
	targets_in_range.clear()

	soldier_died.emit(self)
	queue_free()


func is_soldier_dead() -> bool:
	return is_dead


func _play_walk_animation() -> void:
	if animation_player == null:
		return
	if is_dead or is_attack_anim_active or is_damage_anim_active:
		return
	if not animation_player.has_animation("walk"):
		return

	if animation_player.current_animation != "walk" or not animation_player.is_playing():
		animation_player.play("walk")


func _update_labels() -> void:
	if hp_label != null:
		hp_label.text = "%d / %d" % [current_hp, max_hp]


func _apply_random_visuals() -> void:
	var hash_source: String = soldier_id
	if hash_source.is_empty():
		hash_source = "soldier_%d" % get_instance_id()

	var hash_value: int = abs(hash_source.hash())

	if body_sprite != null and BODY_TEXTURES.size() > 0:
		body_sprite.texture = load(BODY_TEXTURES[hash_value % BODY_TEXTURES.size()])

	if weapon_sprite != null and WEAPON_TEXTURES.size() > 0:
		weapon_sprite.texture = load(WEAPON_TEXTURES[(hash_value / 5) % WEAPON_TEXTURES.size()])

	if shield_sprite != null:
		shield_sprite.visible = ((hash_value / 11) % 2) == 0


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
	if not candidate.is_in_group("enemies"):
		return
	if candidate.has_method("is_enemy_dead") and candidate.is_enemy_dead():
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
		if target.has_method("is_enemy_dead") and target.is_enemy_dead():
			targets_in_range.remove_at(i)

	if current_target != null:
		if not is_instance_valid(current_target):
			current_target = null
		elif current_target.has_method("is_enemy_dead") and current_target.is_enemy_dead():
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
	attack_timer = 0.0
