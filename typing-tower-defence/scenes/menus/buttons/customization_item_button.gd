# res://scripts/ui/customization/customization_item_button.gd
class_name CustomizationItemButton
extends Button

signal item_selected(slot_id: String, item_id: String)

const CustomizationDefinitions = preload("res://data/player/customization_definitions.gd")

@onready var item_icon: TextureRect = %ItemIcon
@onready var preview_holder: Control = %PreviewHolder
@onready var color_swatch: ColorRect = %ColorSwatch
@onready var name_label: Label = %NameLabel
@onready var selected_border: Panel = %SelectedBorder
@onready var locked_panel: Panel = %LockedPanel


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

	if PlayerLoadout.has_signal("loadout_changed"):
		if not PlayerLoadout.loadout_changed.is_connected(_on_loadout_changed):
			PlayerLoadout.loadout_changed.connect(_on_loadout_changed)

	_setup_name_label()

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
	var has_color: bool = pending_item_data.has("color")

	if name_label != null:
		name_label.visible = true
		name_label.text = display_name
		_shrink_label_to_fit(name_label)

	_clear_preview()

	if preview_scene != null:
		_show_preview_scene(preview_scene)
	elif item_icon_texture != null:
		_show_item_icon(item_icon_texture)
	elif has_color:
		_show_color_swatch(pending_item_data.get("color", Color.WHITE))
	else:
		_hide_visual()

	disabled = false
	_update_locked_panel()
	button_pressed = pending_equipped

	_update_selected_border()

	if is_unlocked:
		tooltip_text = display_name
	else:
		tooltip_text = unlock_hint if not unlock_hint.is_empty() else "Locked"


func _update_selected_border() -> void:
	if selected_border == null:
		return

	var is_selected := false

	if _is_color_slot(slot_id):
		is_selected = PlayerLoadout.get_equipped(slot_id) == item_id
	else:
		is_selected = PlayerLoadout.get_equipped(slot_id) == item_id

	selected_border.visible = is_selected


func _setup_name_label() -> void:
	if name_label == null:
		return

	name_label.clip_text = true
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF


func _shrink_label_to_fit(label: Label) -> void:
	if label == null:
		return

	var min_font_size := 8
	var max_font_size := 16
	var available_width := label.size.x

	if available_width <= 0.0:
		await get_tree().process_frame
		available_width = label.size.x

	if available_width <= 0.0:
		return

	var font: Font = label.get_theme_font("font")
	if font == null:
		return

	var text := label.text
	var final_size := max_font_size

	for size in range(max_font_size, min_font_size - 1, -1):
		var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

		if text_width <= available_width:
			final_size = size
			break

	label.add_theme_font_size_override("font_size", final_size)


func _show_item_icon(texture: Texture2D) -> void:
	if preview_holder != null:
		preview_holder.visible = false

	if color_swatch != null:
		color_swatch.visible = false

	if item_icon == null:
		return

	item_icon.visible = true
	item_icon.texture = texture
	item_icon.modulate = _get_icon_modulate()


func _show_color_swatch(color: Color) -> void:
	if preview_holder != null:
		preview_holder.visible = false

	if item_icon != null:
		item_icon.visible = false
		item_icon.texture = null

	if color_swatch == null:
		return

	color_swatch.visible = true
	color_swatch.color = color


func _show_preview_scene(scene: PackedScene) -> void:
	if item_icon != null:
		item_icon.visible = false
		item_icon.texture = null

	if color_swatch != null:
		color_swatch.visible = false

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

	if preview_instance is CanvasItem:
		(preview_instance as CanvasItem).modulate = _get_icon_modulate()


func set_selected_border_visible(is_visible: bool) -> void:
	if selected_border == null:
		await ready
	
	if selected_border != null:
		selected_border.visible = is_visible

func _hide_visual() -> void:
	if item_icon != null:
		item_icon.visible = false
		item_icon.texture = null

	if preview_holder != null:
		preview_holder.visible = false

	if color_swatch != null:
		color_swatch.visible = false

	if name_label != null:
		name_label.visible = true


func _update_locked_panel() -> void:
	if locked_panel == null:
		return
	
	locked_panel.visible = not is_unlocked

func _clear_preview() -> void:
	if preview_instance != null and is_instance_valid(preview_instance):
		preview_instance.queue_free()

	preview_instance = null

	if preview_holder != null:
		for child in preview_holder.get_children():
			child.queue_free()


func _get_icon_modulate() -> Color:
	if pending_item_data.has("color"):
		return pending_item_data.get("color", Color.WHITE)

	var color_id := _get_equipped_color_for_slot(slot_id)

	if color_id.is_empty():
		return Color.WHITE

	if slot_id == "body":
		return CustomizationDefinitions.get_body_color(color_id)

	return CustomizationDefinitions.get_dye_color(color_id)


func _get_equipped_color_for_slot(base_slot_id: String) -> String:
	match base_slot_id:
		"body":
			return PlayerLoadout.get_equipped("body_color")

		"undies":
			return PlayerLoadout.get_equipped("undies_color")

		"clothes":
			return PlayerLoadout.get_equipped("clothes_color")

		"hair":
			return PlayerLoadout.get_equipped("hair_color")

		"hat":
			return PlayerLoadout.get_equipped("hat_color")

		"wand":
			return PlayerLoadout.get_equipped("wand_color")

		_:
			return ""


func _refresh_visual_modulate() -> void:
	if item_icon != null and item_icon.visible:
		item_icon.modulate = _get_icon_modulate()

	if color_swatch != null and color_swatch.visible:
		if pending_item_data.has("color"):
			color_swatch.color = pending_item_data.get("color", Color.WHITE)

	if preview_instance != null and is_instance_valid(preview_instance):
		if preview_instance is CanvasItem:
			(preview_instance as CanvasItem).modulate = _get_icon_modulate()


func _on_loadout_changed(_loadout: Dictionary) -> void:
	_refresh_visual_modulate()
	_update_selected_border()


func _on_pressed() -> void:
	if not is_unlocked:
		return
	
	item_selected.emit(slot_id, item_id)


func _is_color_slot(check_slot_id: String) -> bool:
	return check_slot_id.ends_with("_color")
