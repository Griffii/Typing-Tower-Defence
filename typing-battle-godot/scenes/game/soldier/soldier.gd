extends Node2D
class_name SoldierUnit

@onready var body_sprite: Sprite2D = %Body
@onready var weapon_sprite: Sprite2D = %Weapon
@onready var shield_sprite: Sprite2D = %Shield

@onready var attack_sfx: AudioStreamPlayer2D = %"attack-sfx"
@onready var death_sfx: AudioStreamPlayer2D = %"death-sfx"
@onready var hit_sfx: AudioStreamPlayer2D = %"hit-sfx"

@onready var animation_player: AnimationPlayer = %AnimationPlayer
## Contains anims for 'walk', 'attack', and 'die'


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

var soldier_id: String = ""
var side: String = ""

var target_x: float = 0.0
var current_hp: int = 10
var current_state: String = "moving"
var previous_state: String = "moving"
var current_target_id: String = ""

var move_interp_speed: float = 10.0
var base_position_y: float = 0.0

var damage_flash_timer: float = 0.0
var damage_flash_duration: float = 0.10

var death_started: bool = false
var is_attack_anim_active: bool = false


func setup(new_id: String, new_side: String, start_x: float, lane_y: float) -> void:
	soldier_id = new_id
	side = new_side
	
	position = Vector2(start_x, lane_y)
	base_position_y = lane_y
	target_x = start_x
	
	scale = Vector2.ONE
	modulate = Color.WHITE
	rotation = 0.0
	
	_apply_random_visuals()
	_apply_side_orientation_and_tint()
	_play_walk_if_needed()


func _process(delta: float) -> void:
	if death_started:
		return
	
	position.x = lerp(position.x, target_x, min(1.0, delta * move_interp_speed))
	
	_update_state_driven_animation()
	_update_damage_flash(delta)


func apply_server_state(data: Dictionary) -> void:
	target_x = float(data.get("x", position.x))
	current_hp = int(data.get("hp", current_hp))
	current_state = str(data.get("state", current_state))
	current_target_id = str(data.get("targetId", ""))


func _update_state_driven_animation() -> void:
	if death_started:
		return
	
	var entered_combat := current_state == "combat" and previous_state != "combat"
	var entered_attacking := current_state == "attacking" and previous_state != "attacking"
	
	if entered_combat or entered_attacking:
		play_attack_animation()
	
	if current_state == "moving":
		if not is_attack_anim_active:
			_play_walk_if_needed()
	elif current_state == "combat" or current_state == "attacking":
		if not is_attack_anim_active and not animation_player.is_playing():
			play_attack_animation()
	else:
		if not is_attack_anim_active:
			_play_walk_if_needed()
	
	previous_state = current_state


func play_attack_animation() -> void:
	if death_started or is_attack_anim_active:
		return
	
	is_attack_anim_active = true
	animation_player.play("attack")
	attack_sfx.play()
	
	await animation_player.animation_finished
	
	is_attack_anim_active = false
	
	if death_started:
		return

	if current_state == "moving":
		_play_walk_if_needed()
	elif current_state == "combat" or current_state == "attacking":
		# Stay in the old trigger model: if still in combat after one swing,
		# restart another attack cycle.
		play_attack_animation()
	else:
		_play_walk_if_needed()


func play_damage_flash() -> void:
	damage_flash_timer = damage_flash_duration
	hit_sfx.play()


func play_death_and_remove() -> void:
	if death_started:
		return
	
	death_started = true
	is_attack_anim_active = false
	
	animation_player.play("die")
	death_sfx.play()
	
	await animation_player.animation_finished
	queue_free()


func _play_walk_if_needed() -> void:
	if death_started:
		return
	
	if animation_player.current_animation != "walk" or not animation_player.is_playing():
		animation_player.play("walk")


func _apply_random_visuals() -> void:
	var hash_value: int = abs(soldier_id.hash())
	
	var body_index: int = hash_value % BODY_TEXTURES.size()
	var weapon_index: int = hash_value % WEAPON_TEXTURES.size()
	var shield_visible: bool = ((hash_value / 7) % 2) == 0
	
	body_sprite.texture = load(BODY_TEXTURES[body_index])
	weapon_sprite.texture = load(WEAPON_TEXTURES[weapon_index])
	shield_sprite.visible = shield_visible


func _apply_side_orientation_and_tint() -> void:
	if side == "left":
		scale.x = 1.0
		modulate = Color(0.576, 0.745, 1.0, 1.0)
	else:
		scale.x = -1.0
		modulate = Color(1.0, 0.613, 0.621, 1.0)


func _update_damage_flash(delta: float) -> void:
	if damage_flash_timer > 0.0:
		damage_flash_timer = max(0.0, damage_flash_timer - delta)
	
		if int(Time.get_ticks_msec() / 40) % 2 == 0:
			body_sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)
			weapon_sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)
			shield_sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)
		else:
			body_sprite.modulate = Color.WHITE
			weapon_sprite.modulate = Color.WHITE
			shield_sprite.modulate = Color.WHITE
	else:
		body_sprite.modulate = Color.WHITE
		weapon_sprite.modulate = Color.WHITE
		shield_sprite.modulate = Color.WHITE
