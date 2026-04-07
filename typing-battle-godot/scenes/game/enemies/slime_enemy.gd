# res://scripts/game/enemies/slime_enemy.gd
class_name SlimeEnemy
extends Enemy

const SLIME_COLORS: Array[String] = [
	"blue",
	"grey",
	"green",
	"yellow",
	"orange",
	"red",
	"pink",
]

@onready var slime_sprite: AnimatedSprite2D = %Body
@onready var hit_sfx: AudioStreamPlayer2D = %HitSfx
@onready var attack_sfx: AudioStreamPlayer2D = %AttackSfx
@onready var die_sfx: AudioStreamPlayer2D = %DieSfx

var slime_color: String = "blue"


func _apply_visuals() -> void:
	var hash_source: String = enemy_id
	if hash_source.is_empty():
		hash_source = "%s_%s_%d" % [enemy_type, current_word, get_instance_id()]

	var hash_value: int = abs(hash_source.hash())
	slime_color = SLIME_COLORS[hash_value % SLIME_COLORS.size()]

	if slime_sprite == null:
		return

	var idle_anim := "%s_idle" % slime_color
	if slime_sprite.sprite_frames != null and slime_sprite.sprite_frames.has_animation(idle_anim):
		slime_sprite.play(idle_anim)


func _play_walk_animation() -> void:
	if slime_sprite == null:
		return
	if is_dead or has_reached_base or is_attack_anim_active or is_damage_anim_active:
		return

	var anim_name := "%s_walk" % slime_color
	if slime_sprite.sprite_frames == null or not slime_sprite.sprite_frames.has_animation(anim_name):
		return

	if slime_sprite.animation != anim_name or not slime_sprite.is_playing():
		slime_sprite.play(anim_name)


func play_take_damage_animation() -> void:
	if slime_sprite == null:
		return
	if is_dead:
		return
	if is_damage_anim_active:
		return

	var anim_name := "%s_hit" % slime_color
	if slime_sprite.sprite_frames == null or not slime_sprite.sprite_frames.has_animation(anim_name):
		return

	is_damage_anim_active = true

	if hit_sfx != null:
		hit_sfx.play()

	slime_sprite.play(anim_name)

	var duration := _get_current_animation_duration(slime_sprite, anim_name)
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	else:
		await get_tree().process_frame

	is_damage_anim_active = false

	if is_dead:
		return

	if not has_reached_base:
		_play_walk_animation()
	else:
		_play_idle_animation()


func play_attack_animation() -> void:
	if slime_sprite == null:
		return
	if is_dead or is_attack_anim_active or is_damage_anim_active:
		return

	var anim_name := "%s_attack" % slime_color
	if slime_sprite.sprite_frames == null or not slime_sprite.sprite_frames.has_animation(anim_name):
		return

	is_attack_anim_active = true

	if attack_sfx != null:
		attack_sfx.play()

	slime_sprite.play(anim_name)

	var duration := _get_current_animation_duration(slime_sprite, anim_name)
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	else:
		await get_tree().process_frame

	is_attack_anim_active = false

	if is_dead:
		return

	if not has_reached_base:
		_play_walk_animation()
	else:
		_play_idle_animation()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	clear_typing_feedback()

	current_target = null
	targets_in_range.clear()
	
	_spawn_coin_burst_effect()
	
	if slime_sprite != null:
		var anim_name := "%s_die" % slime_color
		if slime_sprite.sprite_frames != null and slime_sprite.sprite_frames.has_animation(anim_name):
			if die_sfx != null:
				die_sfx.play()

			slime_sprite.play(anim_name)

			var duration := _get_current_animation_duration(slime_sprite, anim_name)
			if duration > 0.0:
				await get_tree().create_timer(duration).timeout
			else:
				await get_tree().process_frame

	enemy_died.emit(self)
	queue_free()


func _spawn_hit_burst_effect() -> void:
	if not use_hit_burst_effect:
		return

	var effect: Node2D = HIT_BURST_EFFECT_SCENE.instantiate() as Node2D
	if effect == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	parent_node.add_child(effect)
	effect.global_position = _get_effect_spawn_position()


func _play_idle_animation() -> void:
	if slime_sprite == null:
		return
	if is_dead or is_attack_anim_active or is_damage_anim_active:
		return

	var anim_name := "%s_idle" % slime_color
	if slime_sprite.sprite_frames == null or not slime_sprite.sprite_frames.has_animation(anim_name):
		return

	if slime_sprite.animation != anim_name or not slime_sprite.is_playing():
		slime_sprite.play(anim_name)


func _apply_facing() -> void:
	if visual_root != null:
		visual_root.scale.x = -1.0

	if label_root != null:
		label_root.scale.x = 1.0


func _get_current_animation_duration(sprite: AnimatedSprite2D, anim_name: String) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return 0.0
	if not sprite.sprite_frames.has_animation(anim_name):
		return 0.0

	var frame_count := sprite.sprite_frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return 0.0

	var anim_fps := sprite.sprite_frames.get_animation_speed(anim_name)
	if anim_fps <= 0.0:
		anim_fps = 5.0

	return float(frame_count) / anim_fps
