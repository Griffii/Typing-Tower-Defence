extends Node2D
class_name SoldierUnit

@onready var body_sprite: Sprite2D = $Body
@onready var weapon_sprite: Sprite2D = $Weapon
@onready var shield_sprite: Sprite2D = $Shield

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
var current_target_id: String = ""

var move_interp_speed: float = 10.0
var base_position_y: float = 0.0

var move_wobble_time: float = 0.0
var move_wobble_speed: float = 7.0
var move_wobble_amount: float = 0.10

var attack_anim_timer: float = 0.0
var attack_anim_duration: float = 0.14
var attack_anim_start_rotation: float = 0.0
var attack_anim_target_rotation: float = 0.0

var damage_flash_timer: float = 0.0
var damage_flash_duration: float = 0.10

var death_started: bool = false
var death_hop_duration: float = 0.14
var death_fall_duration: float = 0.20

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


func _process(delta: float) -> void:
	if death_started:
		return

	position.x = lerp(position.x, target_x, min(1.0, delta * move_interp_speed))

	if current_state == "moving":
		move_wobble_time += delta
		rotation = sin(move_wobble_time * move_wobble_speed) * move_wobble_amount
	else:
		if attack_anim_timer <= 0.0:
			rotation = lerp(rotation, 0.0, min(1.0, delta * 12.0))

	_update_attack_animation(delta)
	_update_damage_flash(delta)


func apply_server_state(data: Dictionary) -> void:
	target_x = float(data.get("x", position.x))
	current_hp = int(data.get("hp", current_hp))
	current_state = str(data.get("state", current_state))
	current_target_id = str(data.get("targetId", ""))


func play_attack_animation() -> void:
	attack_anim_timer = attack_anim_duration
	attack_anim_start_rotation = rotation

	if side == "left":
		attack_anim_target_rotation = deg_to_rad(70.0)
	else:
		attack_anim_target_rotation = deg_to_rad(-70.0)


func play_damage_flash() -> void:
	damage_flash_timer = damage_flash_duration


func play_death_and_remove() -> void:
	if death_started:
		return

	death_started = true
	rotation = 0.0

	var tween: Tween = create_tween()

	tween.tween_property(self, "position:y", base_position_y - 14.0, death_hop_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		self,
		"rotation",
		deg_to_rad(-90.0 if side == "left" else 90.0),
		death_hop_duration + death_fall_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "position:y", base_position_y + 10.0, death_fall_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, death_fall_duration)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)

	await tween.finished
	queue_free()


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


func _update_attack_animation(delta: float) -> void:
	if attack_anim_timer <= 0.0:
		return
	
	attack_anim_timer = max(0.0, attack_anim_timer - delta)
	var progress: float = 1.0 - (attack_anim_timer / attack_anim_duration)
	
	if progress < 0.45:
		var t1: float = progress / 0.45
		rotation = lerp(attack_anim_start_rotation, attack_anim_target_rotation, t1)
	else:
		var t2: float = (progress - 0.45) / 0.55
		rotation = lerp(attack_anim_target_rotation, 0.0, t2)


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
