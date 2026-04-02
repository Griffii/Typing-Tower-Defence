extends Node2D

signal impact_reached(target_enemy: Node)
signal projectile_finished

@onready var arrow_sprite: Sprite2D = %ArrowSprite
@onready var hit_particles: GPUParticles2D = %HitParticles
@onready var hit_sfx: AudioStreamPlayer2D = %HitSfx
@onready var shoot_sfx: AudioStreamPlayer2D = %ShootSfx


var start_pos: Vector2
var end_pos: Vector2
var control_pos: Vector2
var target_enemy: Node = null

var flight_duration: float = 0.35
var arc_height: float = 48.0
var is_flying: bool = false


func _ready() -> void:
	if hit_particles != null:
		hit_particles.emitting = false


func fire(from_pos: Vector2, target: Node, duration: float = 0.45, height: float = 48.0) -> void:
	start_pos = from_pos
	target_enemy = target
	flight_duration = duration
	arc_height = height

	if is_instance_valid(target_enemy) and target_enemy is Node2D:
		end_pos = (target_enemy as Node2D).global_position
	else:
		end_pos = from_pos
	
	if shoot_sfx != null:
		shoot_sfx.play()

	global_position = start_pos
	control_pos = _calculate_control_point(start_pos, end_pos, arc_height)

	is_flying = true
	_play_flight()


func _play_flight() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_update_arc_position, 0.0, 1.0, flight_duration)
	await tween.finished

	is_flying = false
	_on_impact()


func _update_arc_position(t: float) -> void:
	var previous_pos: Vector2 = global_position

	# Ease-out so the arrow slows as it approaches the target.
	var eased_t: float = 1.0 - pow(1.0 - t, 2.0)

	global_position = _quadratic_bezier(start_pos, control_pos, end_pos, eased_t)

	var delta: Vector2 = global_position - previous_pos
	if delta.length() > 0.001:
		# Arrowhead is at the TOP of the sprite.
		rotation = delta.angle() + PI / 2.0


func _on_impact() -> void:
	if arrow_sprite != null:
		arrow_sprite.visible = false

	if hit_particles != null:
		hit_particles.global_position = global_position
		hit_particles.emitting = true

	if hit_sfx != null:
		hit_sfx.play()

	impact_reached.emit(target_enemy)

	var cleanup_delay: float = 0.35
	if hit_particles != null and hit_particles.lifetime > 0.0:
		cleanup_delay = max(cleanup_delay, hit_particles.lifetime)

	var timer := get_tree().create_timer(cleanup_delay)
	await timer.timeout

	projectile_finished.emit()
	queue_free()


func _calculate_control_point(a: Vector2, b: Vector2, height: float) -> Vector2:
	var midpoint: Vector2 = (a + b) * 0.5
	return midpoint + Vector2(0.0, -height)


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return (u * u * a) + (2.0 * u * t * b) + (t * t * c)
