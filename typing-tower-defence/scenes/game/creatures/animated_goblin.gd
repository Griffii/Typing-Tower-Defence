extends AnimatedSprite2D

const IDLE_ANIM := "idle"
const BURST_ANIM := "burst"

var rng := RandomNumberGenerator.new()
var playing_burst := false


func _ready() -> void:
	rng.randomize()

	if not animation_finished.is_connected(_on_animation_finished):
		animation_finished.connect(_on_animation_finished)

	_play_idle()
	_schedule_next_burst()


func _play_idle() -> void:
	playing_burst = false
	play(IDLE_ANIM)


func _play_burst() -> void:
	playing_burst = true
	play(BURST_ANIM)


func _schedule_next_burst() -> void:
	var delay := rng.randf_range(2.0, 5.0)
	get_tree().create_timer(delay).timeout.connect(_on_burst_timer_timeout)


func _on_burst_timer_timeout() -> void:
	if playing_burst:
		return

	_play_burst()


func _on_animation_finished() -> void:
	if animation == BURST_ANIM:
		_play_idle()
		_schedule_next_burst()
