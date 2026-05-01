# res://scripts/ui/customization/character_customization_menu.gd
extends Control

signal back_requested

const CustomizationDefinitions = preload("res://data/player/customization_definitions.gd")
const SpellDefinitions = preload("res://data/player/spell_definitions.gd")
const CUSTOMIZATION_ITEM_BUTTON_SCENE: PackedScene = preload("res://scenes/menus/buttons/customization_item_button.tscn")

const DEFAULT_PLAYER_NAME := "Spellicus"
const NORMAL_CATEGORY_SCALE := Vector2.ONE
const SELECTED_CATEGORY_SCALE := Vector2(1.12, 1.12)

@onready var avatar_preview: PlayerAvatar = %PlayerAvatar
@onready var category_buttons: VBoxContainer = %CategoryButtons
@onready var item_grid: GridContainer = %ItemGrid
@onready var color_grid: GridContainer = %ColorGrid
@onready var back_button: Button = %BackButton
@onready var name_label: LineEdit = %NameLabel

var current_slot: String = "clothes"

var categories: Array[String] = [
	"body",
	"undies",
	"clothes",
	"hair",
	"hat",
	"wand",
	"spell"
]

var category_button_map: Dictionary = {}


func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

	if PlayerLoadout.has_signal("loadout_changed"):
		if not PlayerLoadout.loadout_changed.is_connected(_on_loadout_changed):
			PlayerLoadout.loadout_changed.connect(_on_loadout_changed)

	PlayerLoadout.load_loadout()
	
	_setup_name_input()

	_refresh_name_label()
	_bind_existing_category_buttons()

	if avatar_preview != null:
		avatar_preview.apply_loadout(PlayerLoadout.get_loadout())

	_show_slot_items(current_slot)


func _bind_existing_category_buttons() -> void:
	category_button_map.clear()

	if category_buttons == null:
		return

	for slot_id in categories:
		var button := _find_category_button(slot_id)

		if button == null:
			push_warning("CustomizationMenu: Missing existing category button for slot: %s" % slot_id)
			continue

		category_button_map[slot_id] = button

		button.pivot_offset = button.size * 0.5

		if not button.pressed.is_connected(_on_category_pressed.bind(slot_id)):
			button.pressed.connect(_on_category_pressed.bind(slot_id))

	_update_category_button_visuals()


func _find_category_button(slot_id: String) -> Button:
	if category_buttons == null:
		return null

	var expected_names: Array[String] = [
		slot_id,
		slot_id.capitalize(),
		"%sButton" % slot_id.capitalize(),
		"%sButton" % _format_slot_name(slot_id),
	]

	for child in category_buttons.get_children():
		if child is Button:
			var button := child as Button

			if button.name in expected_names:
				return button

			if button.text.strip_edges().to_lower() == _format_slot_name(slot_id).to_lower():
				return button

			if button.text.strip_edges().to_lower() == slot_id.to_lower():
				return button

	return null


func _show_slot_items(slot_id: String) -> void:
	current_slot = slot_id

	_clear_item_grid()
	_clear_color_grid()

	_update_category_button_visuals()

	if _slot_allows_none(slot_id):
		_add_none_button(slot_id)

	var item_ids: Array[String] = _get_item_ids_for_slot(slot_id)

	for item_id in item_ids:
		_add_item_button(slot_id, item_id)

	_refresh_color_grid_for_slot(slot_id)


func _update_category_button_visuals() -> void:
	for slot_id in category_button_map.keys():
		var button: Button = category_button_map[slot_id]

		if button == null:
			continue

		if slot_id == current_slot:
			button.scale = SELECTED_CATEGORY_SCALE
		else:
			button.scale = NORMAL_CATEGORY_SCALE


func _clear_item_grid() -> void:
	if item_grid == null:
		return

	for child in item_grid.get_children():
		child.queue_free()


func _clear_color_grid() -> void:
	if color_grid == null:
		return

	for child in color_grid.get_children():
		child.queue_free()


func _get_item_ids_for_slot(slot_id: String) -> Array[String]:
	var result: Array[String] = []

	if slot_id == "spell":
		for spell_id_variant in PlayerLoadout.unlocked_items.get("spell", []):
			result.append(str(spell_id_variant))
		return result

	var slot_items: Dictionary = CustomizationDefinitions.get_items_for_slot(slot_id)

	for item_id_variant in slot_items.keys():
		result.append(str(item_id_variant))

	return result


func _add_none_button(slot_id: String) -> void:
	var item_data := {
		"display_name": "None",
		"item_icon": null,
		"preview_scene": null,
		"unlock_hint": "",
		"unlocked": true
	}

	var equipped := PlayerLoadout.get_equipped(slot_id).is_empty() or PlayerLoadout.get_equipped(slot_id) == "none"

	var button := _create_item_button(
		slot_id,
		"none",
		item_data,
		equipped
	)

	if button != null:
		item_grid.add_child(button)


func _add_item_button(slot_id: String, item_id: String) -> void:
	var item_data: Dictionary = _get_item_data(slot_id, item_id)

	if item_data.is_empty():
		push_warning("CustomizationMenu: Missing item data for %s / %s" % [slot_id, item_id])
		return

	item_data["unlocked"] = PlayerLoadout.is_unlocked(slot_id, item_id)

	var equipped := PlayerLoadout.get_equipped(slot_id) == item_id

	var button := _create_item_button(
		slot_id,
		item_id,
		item_data,
		equipped
	)

	if button != null:
		item_grid.add_child(button)


func _get_item_data(slot_id: String, item_id: String) -> Dictionary:
	if slot_id == "spell":
		var spell_data: Dictionary = SpellDefinitions.get_spell_data(item_id)
		spell_data["preview_scene"] = SpellDefinitions.get_preview_scene(item_id)
		return spell_data

	return CustomizationDefinitions.get_item_data(slot_id, item_id)


func _create_item_button(
	slot_id: String,
	item_id: String,
	item_data: Dictionary,
	equipped: bool
) -> Button:
	if CUSTOMIZATION_ITEM_BUTTON_SCENE == null:
		push_warning("CustomizationMenu: CUSTOMIZATION_ITEM_BUTTON_SCENE is null.")
		return null

	var button: Node = CUSTOMIZATION_ITEM_BUTTON_SCENE.instantiate()

	if button == null:
		push_warning("CustomizationMenu: Failed to instantiate customization item button.")
		return null

	if not button.has_method("setup"):
		push_warning("CustomizationMenu: Button scene root has no setup() method.")
		button.queue_free()
		return null

	button.setup(slot_id, item_id, item_data, equipped)
	
	if button.has_method("set_selected_border_visible"):
		button.set_selected_border_visible(equipped)

	if button.has_signal("item_selected"):
		if not button.item_selected.is_connected(_on_item_pressed):
			button.item_selected.connect(_on_item_pressed)
	else:
		push_warning("CustomizationMenu: Button scene has no item_selected signal.")

	return button as Button


func _refresh_color_grid_for_slot(slot_id: String) -> void:
	_clear_color_grid()

	if color_grid == null:
		return

	var color_slot_id := _get_color_slot_for_slot(slot_id)

	if color_slot_id.is_empty():
		return

	var equipped_item_id := PlayerLoadout.get_equipped(slot_id)

	if equipped_item_id.is_empty() or equipped_item_id == "none":
		return

	var available_dyes: Array[String] = (
		CustomizationDefinitions.get_available_dyes_for_item(
			slot_id,
			equipped_item_id
		)
	)

	for dye_id in available_dyes:
		_add_color_button(color_slot_id, dye_id)


func _add_color_button(color_slot_id: String, dye_id: String) -> void:
	var dye_data: Dictionary

	if color_slot_id == "body_color":
		dye_data = CustomizationDefinitions.get_item_data("body_color", dye_id)
	else:
		dye_data = CustomizationDefinitions.get_dye_data(dye_id)

	if dye_data.is_empty():
		return

	dye_data["unlocked"] = PlayerLoadout.is_unlocked(color_slot_id, dye_id)

	var equipped := PlayerLoadout.get_equipped(color_slot_id) == dye_id

	var button := _create_item_button(
		color_slot_id,
		dye_id,
		dye_data,
		equipped
	)

	if button != null:
		color_grid.add_child(button)


func _get_color_slot_for_slot(slot_id: String) -> String:
	match slot_id:
		"body":
			return "body_color"

		"undies":
			return "undies_color"

		"clothes":
			return "clothes_color"

		"hair":
			return "hair_color"

		"hat":
			return "hat_color"

		"wand":
			return "wand_color"

		_:
			return ""


func _slot_allows_none(slot_id: String) -> bool:
	return slot_id != "body" and slot_id != "spell"


func _on_category_pressed(slot_id: String) -> void:
	_show_slot_items(slot_id)


func _on_item_pressed(slot_id: String, item_id: String) -> void:
	var equipped := PlayerLoadout.equip(slot_id, item_id)

	if not equipped:
		return

	if avatar_preview != null:
		avatar_preview.apply_loadout(PlayerLoadout.get_loadout())

	if _is_color_slot(slot_id):
		_refresh_color_grid_for_slot(
			_get_base_slot_for_color_slot(slot_id)
		)
	else:
		_show_slot_items(slot_id)


func _on_loadout_changed(loadout: Dictionary) -> void:
	if avatar_preview != null:
		avatar_preview.apply_loadout(loadout)

	_refresh_name_label()


func _refresh_name_label() -> void:
	if name_label == null:
		return

	name_label.text = PlayerLoadout.get_player_name()


func _on_back_pressed() -> void:
	back_requested.emit()


func _is_color_slot(slot_id: String) -> bool:
	return slot_id.ends_with("_color")


func _get_base_slot_for_color_slot(color_slot_id: String) -> String:
	match color_slot_id:
		"body_color":
			return "body"

		"undies_color":
			return "undies"

		"clothes_color":
			return "clothes"

		"hair_color":
			return "hair"

		"hat_color":
			return "hat"

		"wand_color":
			return "wand"

		_:
			return ""


func _format_slot_name(slot_id: String) -> String:
	match slot_id:
		"body":
			return "Body"

		"undies":
			return "Base"

		"clothes":
			return "Clothes"

		"hair":
			return "Hair"

		"hat":
			return "Hat"

		"wand":
			return "Wand"

		"spell":
			return "Spell"

		_:
			return slot_id.capitalize()



func _setup_name_input() -> void:
	if name_label == null:
		return

	name_label.text = PlayerLoadout.get_player_name()
	name_label.focus_exited.connect(_on_name_input_focus_exited)
	name_label.text_submitted.connect(_on_name_input_submitted)


func _on_name_input_focus_exited() -> void:
	_save_name_input()


func _on_name_input_submitted(_new_text: String) -> void:
	_save_name_input()
	name_label.release_focus()


func _save_name_input() -> void:
	if name_label == null:
		return

	var cleaned_name := name_label.text.strip_edges()

	if cleaned_name.is_empty():
		cleaned_name = DEFAULT_PLAYER_NAME

	name_label.text = cleaned_name
	PlayerLoadout.set_player_name(cleaned_name)
