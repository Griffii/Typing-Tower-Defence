extends CanvasLayer

signal countdown_finished

@export var fade_in_time: float = 0.25
@export var hold_time: float = 0.35
@export var fade_out_time: float = 0.25
@export var dim_alpha: float = 0.65

@onready var get_ready_label: Label = %GetReadyLabel
@onready var dim_rect: ColorRect = %DimRect


func _ready() -> void:
	visible = false

	if dim_rect != null:
		dim_rect.modulate.a = 0.0

	if get_ready_label != null:
		get_ready_label.modulate.a = 0.0


func play_countdown(_start_number: int = 3, _step_time: float = 1.0) -> void:
	visible = true

	if dim_rect != null:
		dim_rect.modulate.a = 0.0

	if get_ready_label != null:
		get_ready_label.modulate.a = 0.0
		get_ready_label.visible = true

	var fade_in_tween: Tween = create_tween()
	if dim_rect != null:
		fade_in_tween.parallel().tween_property(dim_rect, "modulate:a", dim_alpha, fade_in_time)
	if get_ready_label != null:
		fade_in_tween.parallel().tween_property(get_ready_label, "modulate:a", 1.0, fade_in_time)

	await fade_in_tween.finished

	await get_tree().create_timer(hold_time).timeout

	var fade_out_tween: Tween = create_tween()
	if dim_rect != null:
		fade_out_tween.parallel().tween_property(dim_rect, "modulate:a", 0.0, fade_out_time)
	if get_ready_label != null:
		fade_out_tween.parallel().tween_property(get_ready_label, "modulate:a", 0.0, fade_out_time)

	await fade_out_tween.finished

	visible = false
	countdown_finished.emit()
