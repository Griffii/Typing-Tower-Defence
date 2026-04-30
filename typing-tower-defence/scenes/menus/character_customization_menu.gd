# res://scripts/ui/customization/character_customization_menu.gd
extends Control

signal back_requested

const CustomizationDefinitions = preload("res://data/player/customization_definitions.gd")
const SpellDefinitions = preload("res://data/player/spell_definitions.gd")
const CUSTOMIZATION_ITEM_BUTTON_SCENE: PackedScene = preload("res://scenes/menus/buttons/customization_item_button.tscn")

@onready var avatar_preview: PlayerAvatar = %PlayerAvatar
@onready var category_buttons: VBoxContainer = %CategoryButtons
@onready var item_grid: GridContainer = %ItemGrid
@onready var back_button: Button = %BackButton

var current_slot: String = "clothes"

var categories: Array[String] = [
	"body_color",
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

	if item_grid == null:
		return

	for child in item_grid.get_children():
		child.queue_free()

	if _slot_allows_none(slot_id):
		_add_none_button(slot_id)

	var item_ids: Array[String] = _get_item_ids_for_slot(slot_id)

	for item_id in item_ids:
		_add_item_button(slot_id, item_id)


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
		"icon": null,
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


func _create_item_button(slot_id: String, item_id: String, item_data: Dictionary, equipped: bool) -> CustomizationItemButton:
	if CUSTOMIZATION_ITEM_BUTTON_SCENE == null:
		return null

	var button := CUSTOMIZATION_ITEM_BUTTON_SCENE.instantiate() as CustomizationItemButton
	if button == null:
		return null

	button.setup(slot_id, item_id, item_data, equipped)

	if not button.item_selected.is_connected(_on_item_pressed):
		button.item_selected.connect(_on_item_pressed)

	return button


func _slot_allows_none(slot_id: String) -> bool:
	return slot_id != "body" and slot_id != "body_color" and slot_id != "spell"


func _on_category_pressed(slot_id: String) -> void:
	_show_slot_items(slot_id)


func _on_item_pressed(slot_id: String, item_id: String) -> void:
	var equipped := PlayerLoadout.equip(slot_id, item_id)
	if not equipped:
		return

	if avatar_preview != null:
		avatar_preview.apply_loadout(PlayerLoadout.get_loadout())

	_show_slot_items(slot_id)


func _on_loadout_changed(loadout: Dictionary) -> void:
	if avatar_preview != null:
		avatar_preview.apply_loadout(loadout)


func _on_back_pressed() -> void:
	back_requested.emit()


func _format_slot_name(slot_id: String) -> String:
	match slot_id:
		"body":
			return "Body"
		"body_color":
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
