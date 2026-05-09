# res://scripts/game/enemies/training_dummy.gd
class_name TrainingDummy
extends Enemy

@onready var body: AnimatedSprite2D = %Body
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var marker_id: String = ""


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("training_dummies")

	max_hp = 50
	current_hp = 50
	move_speed = 0.0
	reward_score = 10
	reward_gold = 10
	base_attack_damage = 0
	base_attack_interval = 999.0

	if word_label_controller != null:
		word_label_controller.set_anchor(label_anchor)

	_update_labels()
	_play_spawn_animation()


func setup_enemy(enemy_data: Dictionary) -> void:
	enemy_data_store = enemy_data.duplicate(true)

	enemy_type = str(enemy_data.get("enemy_type", "training_dummy"))
	enemy_id = str(enemy_data.get("enemy_id", ""))
	marker_id = str(enemy_data.get("marker_id", ""))

	max_hp = int(enemy_data.get("max_hp", 50))
	current_hp = max_hp

	reward_score = int(enemy_data.get("reward_score", 10))
	reward_gold = int(enemy_data.get("reward_gold", 10))

	move_speed = 0.0
	base_attack_damage = 0
	base_attack_interval = 999.0

	current_word = str(enemy_data.get("word", ""))

	path_points = PackedVector2Array()
	path_index = 0
	has_reached_base = false
	is_dead = false
	is_targeted = false
	is_attack_anim_active = false
	is_damage_anim_active = false
	base_attack_timer = 0.0
	current_target = null
	targets_in_range.clear()

	if word_label_controller != null:
		word_label_controller.set_anchor(label_anchor)

	_update_labels()
	_play_spawn_animation()


func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO


func _play_spawn_animation() -> void:
	if animation_player != null and animation_player.has_animation("spawn"):
		animation_player.play("spawn")

	if body != null:
		body.play("idle")


func _play_walk_animation() -> void:
	if body != null and not is_dead:
		if body.animation != "idle":
			body.play("idle")


func play_take_damage_animation() -> void:
	if is_dead:
		return

	if body == null:
		return

	body.play("hit")

	if not body.animation_finished.is_connected(_on_body_animation_finished):
		body.animation_finished.connect(_on_body_animation_finished)


func play_attack_animation() -> void:
	pass


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	clear_typing_feedback()

	current_target = null
	targets_in_range.clear()

	_spawn_coin_burst_effect()

	if body != null and body.sprite_frames != null and body.sprite_frames.has_animation("die"):
		body.play("die")

		if not body.animation_finished.is_connected(_on_die_animation_finished):
			body.animation_finished.connect(_on_die_animation_finished)
	else:
		_finish_death()


func _on_body_animation_finished() -> void:
	if is_dead:
		return

	if body != null:
		body.play("idle")


func _on_die_animation_finished() -> void:
	_finish_death()


func _finish_death() -> void:
	enemy_died.emit(self)
	queue_free()


func _apply_visuals() -> void:
	pass


func _apply_facing() -> void:
	if visual_root != null:
		visual_root.scale.x = 1.0

	if label_root != null:
		label_root.scale.x = 1.0
