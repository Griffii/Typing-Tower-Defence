# res://scripts/ui/customization/character_customization_menu.gd
extends Control

signal back_requested

const CustomizationDefinitions = preload("res://data/player/customization_definitions.gd")
const SpellDefinitions = preload("res://data/player/spell_definitions.gd")
const CUSTOMIZATION_ITEM_BUTTON_SCENE: PackedScene = preload("res://scenes/menus/buttons/customization_item_button.tscn")

@onready var avatar_preview: PlayerAvatar = %PlayerAvatar
@onready var category_buttons: VBoxContainer = %CategoryButtons
@onready var item_grid: GridContainer = %ItemGrid
@onready var color_grid: GridContainer = %ColorGrid
@onready var back_button: Button = %BackButton

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


func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

	if PlayerLoadout.has_signal("loadout_changed"):
		if not PlayerLoadout.loadout_changed.is_connected(_on_loadout_changed):
			PlayerLoadout.loadout_changed.connect(_on_loadout_changed)

	PlayerLoadout.load_loadout()

	if avatar_preview != null:
		avatar_preview.apply_loadout(PlayerLoadout.get_loadout())

	_build_category_buttons()
	_show_slot_items(current_slot)


func _build_category_buttons() -> void:
	if category_buttons == null:
		return

	for child in category_buttons.get_children():
		child.queue_free()

	for slot_id in categories:
		var button := Button.new()
		button.text = _format_slot_name(slot_id)
		button.pressed.connect(_on_category_pressed.bind(slot_id))
		category_buttons.add_child(button)


func _show_slot_items(slot_id: String) -> void:
	current_slot = slot_id
	_clear_item_grid()
	_clear_color_grid()

	if _slot_allows_none(slot_id):
		_add_none_button(slot_id)

	var item_ids: Array[String] = _get_item_ids_for_slot(slot_id)

	for item_id in item_ids:
		_add_item_button(slot_id, item_id)

	_refresh_color_grid_for_slot(slot_id)


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

	if not PlayerLoadout.unlocked_items.has(slot_id):
		return result

	for item_id_variant in PlayerLoadout.unlocked_items.get(slot_id, []):
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
	var button := _create_item_button(slot_id, "none", item_data, equipped)

	if button != null:
		item_grid.add_child(button)


func _add_item_button(slot_id: String, item_id: String) -> void:
	var item_data: Dictionary = _get_item_data(slot_id, item_id)

	if item_data.is_empty():
		push_warning("CustomizationMenu: Missing item data for %s / %s" % [slot_id, item_id])
		return

	item_data["unlocked"] = PlayerLoadout.is_unlocked(slot_id, item_id)

	var equipped := PlayerLoadout.get_equipped(slot_id) == item_id
	var button := _create_item_button(slot_id, item_id, item_data, equipped)

	if button != null:
		item_grid.add_child(button)


func _get_item_data(slot_id: String, item_id: String) -> Dictionary:
	if slot_id == "spell":
		var spell_data: Dictionary = SpellDefinitions.get_spell_data(item_id)
		spell_data["preview_scene"] = SpellDefinitions.get_preview_scene(item_id)
		return spell_data

	return CustomizationDefinitions.get_item_data(slot_id, item_id)


func _create_item_button(slot_id: String, item_id: String, item_data: Dictionary, equipped: bool) -> Button:
	if CUSTOMIZATION_ITEM_BUTTON_SCENE == null:
		push_warning("CustomizationMenu: CUSTOMIZATION_ITEM_BUTTON_SCENE is null.")
		return null

	var button: Node = CUSTOMIZATION_ITEM_BUTTON_SCENE.instantiate()
	if button == null:
		push_warning("CustomizationMenu: Failed to instantiate customization item button.")
		return null

	if not button.has_method("setup"):
		push_warning("CustomizationMenu: Button scene root has no setup() method. Check script on customization_item_button.tscn root.")
		button.queue_free()
		return null

	button.setup(slot_id, item_id, item_data, equipped)

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

	var available_dyes: Array[String] = CustomizationDefinitions.get_available_dyes_for_item(slot_id, equipped_item_id)

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
	var button := _create_item_button(color_slot_id, dye_id, dye_data, equipped)

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
		_refresh_color_grid_for_slot(_get_base_slot_for_color_slot(slot_id))
	else:
		_show_slot_items(slot_id)


func _on_loadout_changed(loadout: Dictionary) -> void:
	if avatar_preview != null:
		avatar_preview.apply_loadout(loadout)


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
