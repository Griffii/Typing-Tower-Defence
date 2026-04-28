extends CanvasLayer

signal transition_midpoint_reached
signal transition_finished

@onready var animation_player: AnimationPlayer = %AnimationPlayer

var _midpoint_emitted: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	if animation_player != null and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)


func play_transition(animation_name: String = "black_swipe") -> void:
	_midpoint_emitted = false
	visible = true

	if animation_player == null:
		_emit_midpoint()
		transition_finished.emit()
		return

	if not animation_player.has_animation(animation_name):
		push_warning("SceneTransition: missing animation '%s'." % animation_name)
		_emit_midpoint()
		transition_finished.emit()
		return

	animation_player.stop()
	animation_player.play(animation_name)


func _on_transition_midpoint() -> void:
	_emit_midpoint()


func _emit_midpoint() -> void:
	if _midpoint_emitted:
		return

	_midpoint_emitted = true
	transition_midpoint_reached.emit()


func _on_animation_finished(_anim_name: StringName) -> void:
	if not _midpoint_emitted:
		_emit_midpoint()

	visible = false
	transition_finished.emit()
