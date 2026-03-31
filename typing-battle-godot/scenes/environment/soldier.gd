extends Node2D
class_name SoldierUnit

@onready var body: ColorRect = $Body

var side: String = ""
var start_position: Vector2 = Vector2.ZERO
var end_position: Vector2 = Vector2.ZERO

var health: int = 10
var damage: int = 5
var attack_cooldown: float = 0.6
var move_speed: float = 80.0

var target: SoldierUnit = null
var is_fighting: bool = false
var is_attacking_castle: bool = false
var attack_timer: float = 0.0

var castle_hit_callback: Callable
var castle_alive_callback: Callable

var attack_anim_timer: float = 0.0
var attack_anim_duration: float = 0.12
var attack_anim_max_rotation: float = 0.22
var attack_anim_direction: float = 1.0

func setup(new_side: String) -> void:
	side = new_side
	position = start_position
	
	body.size = Vector2(18, 18)
	body.position = Vector2(-9, -9)
	body.rotation = 0.0
	
	if side == "left":
		body.color = Color(0.25, 0.8, 0.35)
	else:
		body.color = Color(0.9, 0.35, 0.35)


func _process(delta: float) -> void:
	_update_attack_animation(delta)
	
	if is_fighting:
		_handle_combat(delta)
		return
	
	if is_attacking_castle:
		_handle_castle_attack(delta)
		return
	
	_move_forward(delta)
	_check_for_enemies()
	_check_for_castle_contact()


func _move_forward(delta: float) -> void:
	var direction: float = 1.0
	if side == "right":
		direction = -1.0
	
	position.x += direction * move_speed * delta


func _check_for_enemies() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	
	for child: Node in parent_node.get_children():
		if child == self:
			continue
		if not is_instance_valid(child):
			continue
		if not child is SoldierUnit:
			continue
	
		var other: SoldierUnit = child as SoldierUnit
		if other == null:
			continue
		if other.side == side:
			continue
	
		if position.distance_to(other.position) <= 20.0:
			_start_fight_pair(other)
			return


func _start_fight_pair(enemy: SoldierUnit) -> void:
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	if is_fighting:
		return
	
	is_attacking_castle = false
	target = enemy
	is_fighting = true
	
	var my_distance_to_home: float = distance_to_home_castle()
	var enemy_distance_to_home: float = enemy.distance_to_home_castle()
	
	if my_distance_to_home <= enemy_distance_to_home:
		attack_timer = 0.0
	else:
		attack_timer = attack_cooldown
	
	enemy.start_fight(self)


func start_fight(enemy: SoldierUnit) -> void:
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	
	is_attacking_castle = false
	target = enemy
	is_fighting = true


func _handle_combat(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		is_fighting = false
		target = null
		return
	
	attack_timer -= delta
	
	if attack_timer <= 0.0:
		_play_attack_animation()
	
		if is_instance_valid(target):
			target.take_damage(damage)
	
		attack_timer = attack_cooldown


func _check_for_castle_contact() -> void:
	if not _enemy_castle_alive():
		return
	
	var reached_castle: bool = false
	
	if side == "left":
		if position.x >= end_position.x:
			reached_castle = true
	else:
		if position.x <= end_position.x:
			reached_castle = true
	
	if reached_castle:
		position.x = end_position.x
		is_attacking_castle = true
		is_fighting = false
		target = null
		attack_timer = 0.0


func _handle_castle_attack(delta: float) -> void:
	if not _enemy_castle_alive():
		queue_free()
		return
	
	attack_timer -= delta
	
	if attack_timer <= 0.0:
		_play_attack_animation()
	
		if castle_hit_callback.is_valid():
			castle_hit_callback.call(side, damage)
	
		attack_timer = attack_cooldown


func take_damage(amount: int) -> void:
	health -= amount
	
	if health <= 0:
		queue_free()


func _enemy_castle_alive() -> bool:
	if castle_alive_callback.is_valid():
		return bool(castle_alive_callback.call(side))
	return true


func _play_attack_animation() -> void:
	attack_anim_timer = attack_anim_duration
	
	if side == "left":
		attack_anim_direction = 1.0
	else:
		attack_anim_direction = -1.0


func _update_attack_animation(delta: float) -> void:
	if attack_anim_timer > 0.0:
		attack_anim_timer = max(0.0, attack_anim_timer - delta)
	
		var progress: float = 1.0 - (attack_anim_timer / attack_anim_duration)
		var swing: float = sin(progress * PI) * attack_anim_max_rotation
		body.rotation = swing * attack_anim_direction
	else:
		body.rotation = 0.0


func distance_to_home_castle() -> float:
	return abs(position.x - start_position.x)


func get_side() -> String:
	return side
