extends Node2D
class_name TowerBuildLocationNode

signal build_location_pressed(slot_id: String)

@export var idle_alpha: float = 0.65
@export var active_alpha: float = 1.0
@export var occupied_alpha: float = 0.0
@export var hover_scale: Vector2 = Vector2(1.2, 1.2)

@onready var area_ring: Node2D = %AreaRing
@onready var build_button: BaseButton = %BuildButton

var slot_id: String = ""
var can_build: bool = false
var is_occupied: bool = false
var is_hovered: bool = false


func _ready() -> void:
	visible = true

	if area_ring != null:
		area_ring.visible = true

	if build_button != null:

		if not build_button.pressed.is_connected(_on_build_button_pressed):
			build_button.pressed.connect(_on_build_button_pressed)

		if not build_button.mouse_entered.is_connected(_on_build_button_mouse_entered):
			build_button.mouse_entered.connect(_on_build_button_mouse_entered)

		if not build_button.mouse_exited.is_connected(_on_build_button_mouse_exited):
			build_button.mouse_exited.connect(_on_build_button_mouse_exited)

	_refresh_visual_state()


func setup_slot(new_slot_id: String) -> void:
	slot_id = new_slot_id


func set_screen_position(screen_position: Vector2) -> void:
	global_position = screen_position


func refresh_slot_state(slot_data: Dictionary, new_can_build: bool, _selected_tower_type: String) -> void:
	var built_tower_type: String = str(slot_data.get("tower_type", ""))

	is_occupied = not built_tower_type.is_empty()
	can_build = new_can_build and not is_occupied

	_refresh_visual_state()


func _refresh_visual_state() -> void:
	if area_ring != null:
		area_ring.visible = not is_occupied

	if build_button != null:
		build_button.disabled = not can_build

	if is_occupied:
		modulate.a = occupied_alpha
	elif can_build:
		modulate.a = active_alpha
	else:
		modulate.a = idle_alpha

	scale = hover_scale if is_hovered and can_build else Vector2.ONE


func _on_build_button_pressed() -> void:
	if slot_id.is_empty():
		return
	if not can_build:
		return

	build_location_pressed.emit(slot_id)


func _on_build_button_mouse_entered() -> void:
	is_hovered = true
	_refresh_visual_state()


func _on_build_button_mouse_exited() -> void:
	is_hovered = false
	_refresh_visual_state()
