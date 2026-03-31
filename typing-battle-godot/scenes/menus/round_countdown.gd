extends Control

signal countdown_finished

@onready var number_label: Label = %NumberLabel
@onready var dim_rect: ColorRect = %DimRect

var base_number_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	visible = false
	dim_rect.modulate.a = 0.0
	number_label.modulate.a = 0.0
	call_deferred("_store_base_position")


func _store_base_position() -> void:
	base_number_position = number_label.position


func play_countdown(start_number: int = 3, step_time: float = 1.0) -> void:
	visible = true

	if base_number_position == Vector2.ZERO:
		base_number_position = number_label.position

	number_label.text = ""
	number_label.modulate.a = 0.0
	dim_rect.modulate.a = 0.0

	var fade_in_tween: Tween = create_tween()
	fade_in_tween.tween_property(dim_rect, "modulate:a", 0.65, 0.18)
	await fade_in_tween.finished

	for i: int in range(start_number, 0, -1):
		await _play_single_number(str(i), step_time)

	number_label.text = ""

	var fade_out_tween: Tween = create_tween()
	fade_out_tween.parallel().tween_property(dim_rect, "modulate:a", 0.0, 0.16)
	fade_out_tween.parallel().tween_property(number_label, "modulate:a", 0.0, 0.10)
	await fade_out_tween.finished

	visible = false
	countdown_finished.emit()


func _play_single_number(text_value: String, step_time: float) -> void:
	number_label.text = text_value
	number_label.modulate.a = 1.0
	number_label.scale = Vector2.ONE

	var start_pos: Vector2 = base_number_position + Vector2(0.0, -140.0)
	var overshoot_pos: Vector2 = base_number_position + Vector2(0.0, 18.0)

	number_label.position = start_pos

	var drop_time: float = step_time * 0.45
	var settle_time: float = step_time * 0.18
	var hold_time: float = step_time * 0.20
	var fade_time: float = step_time * 0.17

	var tween: Tween = create_tween()
	tween.tween_property(number_label, "position", overshoot_pos, drop_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(number_label, "position", base_number_position, settle_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_time)
	tween.parallel().tween_property(number_label, "modulate:a", 0.0, fade_time)
	await tween.finished
