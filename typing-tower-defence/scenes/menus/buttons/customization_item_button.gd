# res://scripts/ui/customization/customization_item_button.gd
class_name CustomizationItemButton
extends Button

signal item_selected(slot_id: String, item_id: String)

@onready var item_icon: TextureRect = %ItemIcon
@onready var preview_holder: Control = %PreviewHolder
@onready var name_label: Label = %NameLabel

var slot_id: String = ""
var item_id: String = ""
var is_unlocked: bool = false
var unlock_hint: String = ""
var preview_instance: Node = null

var pending_item_data: Dictionary = {}
var pending_equipped: bool = false
var is_ready: bool = false


func _ready() -> void:
	is_ready = true

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	if not pending_item_data.is_empty():
		_apply_setup_data()


func setup(new_slot_id: String, new_item_id: String, item_data: Dictionary, equipped: bool) -> void:
	slot_id = new_slot_id
	item_id = new_item_id
	pending_item_data = item_data.duplicate(true)
	pending_equipped = equipped

	if not is_ready:
		return

	_apply_setup_data()


func _apply_setup_data() -> void:
	is_unlocked = bool(pending_item_data.get("unlocked", false))
	unlock_hint = str(pending_item_data.get("unlock_hint", ""))

	var display_name: String = str(pending_item_data.get("display_name", item_id))
	var item_icon_texture: Texture2D = pending_item_data.get("item_icon", null)
	var preview_scene: PackedScene = pending_item_data.get("preview_scene", null)

	if name_label != null:
		name_label.visible = true
		name_label.text = display_name

	_clear_preview()

	if preview_scene != null:
		_show_preview_scene(preview_scene)
	elif item_icon_texture != null:
		_show_item_icon(item_icon_texture)
	else:
		_hide_visual()

	disabled = not is_unlocked
	button_pressed = pending_equipped

	if is_unlocked:
		tooltip_text = display_name
	else:
		tooltip_text = unlock_hint if not unlock_hint.is_empty() else "Locked"


func _show_item_icon(texture: Texture2D) -> void:
	if preview_holder != null:
		preview_holder.visible = false

	if item_icon == null:
		return

	item_icon.visible = true
	item_icon.texture = texture
	item_icon.modulate = Color.WHITE if is_unlocked else Color.BLACK


func _show_preview_scene(scene: PackedScene) -> void:
	if item_icon != null:
		item_icon.visible = false
		item_icon.texture = null

	if preview_holder == null:
		return

	preview_holder.visible = true

	preview_instance = scene.instantiate()
	if preview_instance == null:
		return

	preview_holder.add_child(preview_instance)

	if preview_instance is Node2D:
		(preview_instance as Node2D).position = preview_holder.size * 0.5
		(preview_instance as Node2D).scale = Vector2(0.75, 0.75)

	if not is_unlocked and preview_instance is CanvasItem:
		(preview_instance as CanvasItem).modulate = Color.BLACK


func _hide_visual() -> void:
	if item_icon != null:
		item_icon.visible = false
		item_icon.texture = null

	if preview_holder != null:
		preview_holder.visible = false

	if name_label != null:
		name_label.visible = true


func _clear_preview() -> void:
	if preview_instance != null and is_instance_valid(preview_instance):
		preview_instance.queue_free()

	preview_instance = null

	if preview_holder != null:
		for child in preview_holder.get_children():
			child.queue_free()


func _on_pressed() -> void:
	if not is_unlocked:
		return

	item_selected.emit(slot_id, item_id)
