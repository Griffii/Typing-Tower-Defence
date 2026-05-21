extends Control

@export var star_count: int = 90
@export var magic_dot_count: int = 35

@export var star_color: Color = Color(0.75, 0.9, 1.0, 0.85)
@export var magic_color: Color = Color(0.25, 0.75, 1.0, 0.75)

@export_group("Background Color Cycle")
@export var background_color_a: Color = Color("#08111f")
@export var background_color_b: Color = Color("#140b24")
@export var background_color_c: Color = Color("#06202a")
@export var background_cycle_speed: float = 0.08

@export var star_speed_min: float = 6.0
@export var star_speed_max: float = 18.0
@export var magic_speed_min: float = 12.0
@export var magic_speed_max: float = 36.0

@export var star_size_min: float = 1.0
@export var star_size_max: float = 2.0
@export var magic_size_min: float = 2.0
@export var magic_size_max: float = 5.0

var stars: Array[Dictionary] = []
var magic_dots: Array[Dictionary] = []
var elapsed_time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_generate_particles()
	set_process(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_generate_particles()


func _generate_particles() -> void:
	stars.clear()
	magic_dots.clear()

	var area_size: Vector2 = size
	if area_size.x <= 0.0 or area_size.y <= 0.0:
		return

	for i in range(star_count):
		stars.append(_make_particle(
			area_size,
			star_speed_min,
			star_speed_max,
			star_size_min,
			star_size_max
		))

	for i in range(magic_dot_count):
		magic_dots.append(_make_particle(
			area_size,
			magic_speed_min,
			magic_speed_max,
			magic_size_min,
			magic_size_max
		))


func _make_particle(
	area_size: Vector2,
	speed_min: float,
	speed_max: float,
	size_min: float,
	size_max: float
) -> Dictionary:
	return {
		"position": Vector2(
			randf_range(0.0, area_size.x),
			randf_range(0.0, area_size.y)
		),
		"speed": randf_range(speed_min, speed_max),
		"radius": randf_range(size_min, size_max),
		"phase": randf_range(0.0, TAU),
		"drift": randf_range(-8.0, 8.0),
		"alpha": randf_range(0.35, 1.0)
	}


func _process(delta: float) -> void:
	elapsed_time += delta

	_update_particles(stars, delta)
	_update_particles(magic_dots, delta)
	queue_redraw()


func _update_particles(particles: Array[Dictionary], delta: float) -> void:
	var area_size: Vector2 = size

	for particle in particles:
		var pos: Vector2 = particle["position"]
		var speed: float = particle["speed"]
		var drift: float = particle["drift"]

		pos.y -= speed * delta
		pos.x += sin(elapsed_time + particle["phase"]) * drift * delta

		if pos.y < -20.0:
			pos.y = area_size.y + randf_range(0.0, 30.0)
			pos.x = randf_range(0.0, area_size.x)

		if pos.x < -20.0:
			pos.x = area_size.x + 20.0
		elif pos.x > area_size.x + 20.0:
			pos.x = -20.0

		particle["position"] = pos


func _get_background_color() -> Color:
	var t: float = elapsed_time * background_cycle_speed

	var weight_a: float = 0.5 + 0.5 * sin(t)
	var weight_b: float = 0.5 + 0.5 * sin(t + TAU / 3.0)
	var weight_c: float = 0.5 + 0.5 * sin(t + TAU * 2.0 / 3.0)

	var total: float = weight_a + weight_b + weight_c

	weight_a /= total
	weight_b /= total
	weight_c /= total

	return (
		background_color_a * weight_a +
		background_color_b * weight_b +
		background_color_c * weight_c
	)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _get_background_color())

	for star in stars:
		var pulse: float = 0.65 + sin(elapsed_time * 2.0 + star["phase"]) * 0.25
		var color := star_color
		color.a *= star["alpha"] * pulse

		draw_circle(star["position"], star["radius"], color)

	for dot in magic_dots:
		var pulse: float = 0.75 + sin(elapsed_time * 3.5 + dot["phase"]) * 0.35
		var color := magic_color
		color.a *= dot["alpha"] * pulse

		draw_circle(dot["position"], dot["radius"], color)

		var glow := magic_color
		glow.a *= 0.12 * pulse
		draw_circle(dot["position"], dot["radius"] * 3.0, glow)
