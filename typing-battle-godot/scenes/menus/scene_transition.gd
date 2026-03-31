extends Control

signal fade_out_finished
signal fade_in_finished

@onready var fade_rect: ColorRect = %FadeRect
@onready var loading_label: Label = %LoadingLabel

func _ready() -> void:
	visible = false
	fade_rect.modulate.a = 0.0
	loading_label.visible = false


func fade_out(duration: float = 0.25, show_loading: bool = true) -> void:
	visible = true
	loading_label.visible = show_loading
	
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	fade_out_finished.emit()


func fade_in(duration: float = 0.25) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	loading_label.visible = false
	visible = false
	fade_in_finished.emit()
