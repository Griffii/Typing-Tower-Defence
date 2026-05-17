# res://scripts/game/enemies/training_dummy.gd
class_name TrainingDummy
extends Enemy

@onready var body: AnimatedSprite2D = %Body
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var death_sfx: AudioStreamPlayer2D = %"death-sfx"
@onready var hit_sfx: AudioStreamPlayer2D = %"hit-sfx"

# Word/typing nodes removed from Enemy, so TrainingDummy owns them directly.
@onready var label_root: Node2D = %LabelRoot
@onready var label_anchor: Marker2D = %LabelAnchor
@onready var word_label_controller: WordLabelController = %WordLabelController


var marker_id: String = ""
var is_finishing_death: bool = false

var current_word: String = ""
var is_targeted: bool = false
var word_completion_damage: int = 10


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("training_dummies")
	add_to_group("typing_targets")

	max_hp = 30
	current_hp = 30
	move_speed = 0.0
	reward_score = 15
	reward_gold = 15
	base_attack_damage = 0
	base_attack_interval = 999.0
	word_completion_damage = 10

	if word_label_controller != null:
		word_label_controller.set_anchor(label_anchor)

	_update_labels()
	_play_spawn_animation()


func setup_enemy(enemy_data: Dictionary) -> void:
	enemy_data_store = enemy_data.duplicate(true)

	enemy_type = str(enemy_data.get("enemy_type", "training_dummy"))
	enemy_id = str(enemy_data.get("enemy_id", ""))
	marker_id = str(enemy_data.get("marker_id", ""))

	max_hp = int(enemy_data.get("max_hp", 30))
	current_hp = max_hp

	reward_score = int(enemy_data.get("reward_score", 15))
	reward_gold = int(enemy_data.get("reward_gold", 15))
	word_completion_damage = int(enemy_data.get("word_completion_damage", 10))

	move_speed = 0.0
	base_attack_damage = 0
	base_attack_interval = 999.0

	current_word = str(enemy_data.get("word", ""))

	path_points = PackedVector2Array()
	path_index = 0
	has_reached_base = false
	is_dead = false
	is_finishing_death = false
	is_targeted = false
	is_attack_anim_active = false
	is_damage_anim_active = false
	base_attack_timer = 0.0

	if word_label_controller != null:
		word_label_controller.set_anchor(label_anchor)

	_update_labels()
	_play_spawn_animation()


func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO


# ---------------------------
# Typing target interface
# ---------------------------

func get_current_word() -> String:
	return current_word


func can_accept_word() -> bool:
	return not is_dead and not current_word.is_empty()


func complete_current_word() -> void:
	if not can_accept_word():
		return

	clear_typing_feedback()
	take_damage(word_completion_damage)


func set_word(new_word: String) -> void:
	current_word = new_word
	clear_typing_feedback()


func assign_new_word(new_word: String) -> void:
	set_word(new_word)


func set_targeted(targeted: bool) -> void:
	is_targeted = targeted

	if word_label_controller != null:
		word_label_controller.set_targeted(targeted)

	clear_typing_feedback()


func set_typing_progress(typed_text: String) -> void:
	if word_label_controller != null:
		word_label_controller.set_typing_progress(typed_text)


func clear_typing_feedback() -> void:
	_update_labels()


# ---------------------------
# UI
# ---------------------------

func _update_labels() -> void:
	if word_label_controller != null:
		word_label_controller.set_word(current_word)
		word_label_controller.set_targeted(is_targeted)



# ---------------------------
# Animations
# ---------------------------

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

	if body != null:
		body.visible = true
		body.modulate = Color.WHITE
		body.play("hit")

		if not body.animation_finished.is_connected(_on_body_animation_finished):
			body.animation_finished.connect(_on_body_animation_finished)

	if animation_player != null and animation_player.has_animation("hit"):
		animation_player.play("hit")

	if hit_sfx != null:
		hit_sfx.play()


func play_attack_animation() -> void:
	pass


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_finishing_death = false
	velocity = Vector2.ZERO
	clear_typing_feedback()

	_spawn_coin_burst_effect()

	if body != null:
		body.pause()

	if death_sfx != null:
		death_sfx.play()

	if animation_player != null and animation_player.has_animation("die"):
		animation_player.stop()
		animation_player.play("die")

	if body != null and body.sprite_frames != null and body.sprite_frames.has_animation("die"):
		body.play("die")

		if not body.animation_finished.is_connected(_on_die_animation_finished):
			body.animation_finished.connect(_on_die_animation_finished)
	else:
		_wait_for_animation_player_death_or_finish()


func _wait_for_animation_player_death_or_finish() -> void:
	if animation_player != null and animation_player.has_animation("die"):
		await animation_player.animation_finished

	_finish_death()


func _on_body_animation_finished() -> void:
	if is_dead:
		return

	if body != null:
		body.play("idle")


func _on_die_animation_finished() -> void:
	if animation_player != null and animation_player.has_animation("die"):
		if animation_player.is_playing():
			await animation_player.animation_finished

	_finish_death()


func _finish_death() -> void:
	if is_finishing_death:
		return

	is_finishing_death = true
	enemy_died.emit(self)
	queue_free()


func _apply_visuals() -> void:
	pass


func _apply_facing() -> void:
	if visual_root != null:
		visual_root.scale.x = 1.0

	if label_root != null:
		label_root.scale.x = 1.0
