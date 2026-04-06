extends Node2D

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var arrow_spawn_marker: Marker2D = %ArrowSpawnMarker
@onready var base_marker: Marker2D = %BaseMarker

func _ready() -> void:
	if progress_bar != null:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0


func set_arrow_meter(current_value: float, max_value: float) -> void:
	if progress_bar == null:
		return

	progress_bar.max_value = max(0.001, max_value)
	progress_bar.value = clampf(current_value, 0.0, progress_bar.max_value)


func reset_arrow_meter() -> void:
	if progress_bar == null:
		return

	progress_bar.value = 0.0


func get_arrow_spawn_position() -> Vector2:
	if arrow_spawn_marker == null:
		return global_position

	return arrow_spawn_marker.global_position


func get_base_position() -> Vector2:
	if base_marker == null:
		return global_position

	return base_marker.global_position
