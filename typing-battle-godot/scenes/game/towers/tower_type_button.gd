extends Button
class_name TowerTypeButton

signal tower_type_selected(tower_type: String)

const TowerDefinitions = preload("res://data/towers/tower_definitions.gd")

var tower_type: String = ""


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	if not toggled.is_connected(_on_toggled):
		toggled.connect(_on_toggled)

	mouse_filter = Control.MOUSE_FILTER_STOP
	toggle_mode = true


func setup_button(new_tower_type: String, group: ButtonGroup) -> void:
	tower_type = new_tower_type
	button_group = group
	_apply_icon()
	_on_toggled(button_pressed)


func set_selected(is_selected: bool) -> void:
	button_pressed = is_selected
	_on_toggled(is_selected)


func _apply_icon() -> void:
	if icon == null:
		return
	
	icon = TowerDefinitions.get_icon(tower_type)


func _on_pressed() -> void:
	if not button_pressed:
		return

	if tower_type.is_empty():
		return

	tower_type_selected.emit(tower_type)


func _on_toggled(is_pressed: bool) -> void:
	modulate.a = 1.0 if is_pressed else 0.65
