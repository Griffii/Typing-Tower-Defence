# res://scripts/game/enemies/soldier_enemy.gd
class_name SoldierEnemy
extends Enemy

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

@onready var body_sprite: Sprite2D = %Body
@onready var weapon_sprite: Sprite2D = %Weapon
@onready var shield_sprite: Sprite2D = %Shield
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _apply_visuals() -> void:
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


func _play_walk_animation() -> void:
	if animation_player == null:
		return
	if is_dead or has_reached_base or is_attack_anim_active or is_damage_anim_active:
		return
	if not animation_player.has_animation("walk"):
		return

	if animation_player.current_animation != "walk" or not animation_player.is_playing():
		animation_player.play("walk")


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

	current_target = null
	targets_in_range.clear()

	_spawn_coin_burst_effect()

	if animation_player != null and animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished

	enemy_died.emit(self)
	queue_free()
