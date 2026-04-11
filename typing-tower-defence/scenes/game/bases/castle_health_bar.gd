extends Control

@onready var progress_bar: TextureProgressBar = %ProgressBar
@onready var hp_label: Label = %HpLabel


func _ready() -> void:
	if progress_bar != null:
		progress_bar.min_value = 0
		progress_bar.max_value = 1
		progress_bar.value = 1


func set_base_hp(current_hp: int, max_hp: int) -> void:
	var safe_max_hp: int = max(1, max_hp)
	var clamped_hp: int = clamp(current_hp, 0, safe_max_hp)

	if progress_bar != null:
		progress_bar.max_value = safe_max_hp
		progress_bar.value = clamped_hp

	if hp_label != null:
		hp_label.text = "%d / %d" % [clamped_hp, safe_max_hp]
