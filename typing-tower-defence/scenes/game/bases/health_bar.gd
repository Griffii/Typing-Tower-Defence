extends Control

@onready var progress_bar: TextureProgressBar = %ProgressBar
@onready var hp_label: Label = %HpLabel


func _ready() -> void:
	visible = true
	z_index = 50
	custom_minimum_size = Vector2(48, 10)

	if progress_bar != null:
		progress_bar.visible = true
		progress_bar.min_value = 0
		progress_bar.max_value = 1
		progress_bar.value = 1

	if hp_label != null:
		hp_label.visible = true


func set_base_hp(current_hp: int, max_hp: int) -> void:
	var safe_max_hp: int = max(1, max_hp)
	var clamped_hp: int = clamp(current_hp, 0, safe_max_hp)

	visible = true

	if progress_bar != null:
		progress_bar.visible = true
		progress_bar.min_value = 0
		progress_bar.max_value = safe_max_hp
		progress_bar.value = clamped_hp

	if hp_label != null:
		hp_label.visible = true
		hp_label.text = "%d / %d" % [clamped_hp, safe_max_hp]


func set_hp(current_hp: int, max_hp: int) -> void:
	set_base_hp(current_hp, max_hp)
