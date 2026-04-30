# res://scripts/game/player/player_avatar.gd
class_name PlayerAvatar
extends Node2D

const CustomizationDefinitions = preload("res://data/player/customization_definitions.gd")

@export var default_body: String = "body_01"
@export var default_body_color: String = "skin_01"

@export var default_undies: String = "boy_undies"
@export var default_undies_color: String = "white"

@export var default_clothes: String = "robe_white"
@export var default_clothes_color: String = "blue"

@export var default_hair: String = "hair_01"
@export var default_hair_color: String = "brown"

@export var default_hat: String = "wizard_hat"
@export var default_hat_color: String = "blue"

@export var default_wand: String = "wand_01"
@export var default_wand_color: String = ""

@onready var body_sprite: Sprite2D = %BodySprite
@onready var undies_sprite: Sprite2D = %UndiesSprite
@onready var clothes_sprite: Sprite2D = %ClothesSprite
@onready var hair_sprite: Sprite2D = %HairSprite
@onready var hat_sprite: Sprite2D = %HatSprite
@onready var wand_sprite: Sprite2D = %WandSprite
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var equipped_body: String = ""
var equipped_body_color: String = ""

var equipped_undies: String = ""
var equipped_undies_color: String = ""

var equipped_clothes: String = ""
var equipped_clothes_color: String = ""

var equipped_hair: String = ""
var equipped_hair_color: String = ""

var equipped_hat: String = ""
var equipped_hat_color: String = ""

var equipped_wand: String = ""
var equipped_wand_color: String = ""


func _ready() -> void:
	equipped_body = default_body
	equipped_body_color = default_body_color

	equipped_undies = default_undies
	equipped_undies_color = default_undies_color

	equipped_clothes = default_clothes
	equipped_clothes_color = default_clothes_color

	equipped_hair = default_hair
	equipped_hair_color = default_hair_color

	equipped_hat = default_hat
	equipped_hat_color = default_hat_color

	equipped_wand = default_wand
	equipped_wand_color = default_wand_color

	refresh_visuals()
	play_idle()


func apply_loadout(loadout: Dictionary) -> void:
	equipped_body = str(loadout.get("body", equipped_body))
	equipped_body_color = str(loadout.get("body_color", equipped_body_color))

	equipped_undies = str(loadout.get("undies", equipped_undies))
	equipped_undies_color = str(loadout.get("undies_color", equipped_undies_color))

	equipped_clothes = str(loadout.get("clothes", equipped_clothes))
	equipped_clothes_color = str(loadout.get("clothes_color", equipped_clothes_color))

	equipped_hair = str(loadout.get("hair", equipped_hair))
	equipped_hair_color = str(loadout.get("hair_color", equipped_hair_color))

	equipped_hat = str(loadout.get("hat", equipped_hat))
	equipped_hat_color = str(loadout.get("hat_color", equipped_hat_color))

	equipped_wand = str(loadout.get("wand", equipped_wand))
	equipped_wand_color = str(loadout.get("wand_color", equipped_wand_color))

	refresh_visuals()


func get_loadout() -> Dictionary:
	return {
		"body": equipped_body,
		"body_color": equipped_body_color,

		"undies": equipped_undies,
		"undies_color": equipped_undies_color,

		"clothes": equipped_clothes,
		"clothes_color": equipped_clothes_color,

		"hair": equipped_hair,
		"hair_color": equipped_hair_color,

		"hat": equipped_hat,
		"hat_color": equipped_hat_color,

		"wand": equipped_wand,
		"wand_color": equipped_wand_color,
	}


func equip_part(slot_id: String, item_id: String) -> void:
	match slot_id:
		"body":
			equipped_body = item_id
		"body_color":
			equipped_body_color = item_id

		"undies":
			equipped_undies = item_id
		"undies_color":
			equipped_undies_color = item_id

		"clothes":
			equipped_clothes = item_id
		"clothes_color":
			equipped_clothes_color = item_id

		"hair":
			equipped_hair = item_id
		"hair_color":
			equipped_hair_color = item_id

		"hat":
			equipped_hat = item_id
		"hat_color":
			equipped_hat_color = item_id

		"wand":
			equipped_wand = item_id
		"wand_color":
			equipped_wand_color = item_id

		_:
			push_warning("PlayerAvatar: Unknown slot_id: " + slot_id)
			return

	refresh_visuals()


func refresh_visuals() -> void:
	_apply_part(body_sprite, "body", equipped_body, equipped_body_color, true)
	_apply_part(undies_sprite, "undies", equipped_undies, equipped_undies_color)
	_apply_part(clothes_sprite, "clothes", equipped_clothes, equipped_clothes_color)
	_apply_part(hair_sprite, "hair", equipped_hair, equipped_hair_color)
	_apply_part(hat_sprite, "hat", equipped_hat, equipped_hat_color)
	_apply_part(wand_sprite, "wand", equipped_wand, equipped_wand_color)


func play_idle() -> void:
	if animation_player == null:
		return

	if animation_player.has_animation("idle"):
		animation_player.play("idle")


func play_cast() -> void:
	if animation_player == null:
		return

	if animation_player.has_animation("cast"):
		animation_player.play("cast")


func _apply_part(sprite: Sprite2D, slot_id: String, item_id: String, color_id: String, required: bool = false) -> void:
	if sprite == null:
		return

	if item_id.is_empty() or item_id == "none":
		sprite.visible = required
		if not required:
			sprite.texture = null
		return

	var texture: Texture2D = CustomizationDefinitions.get_texture(slot_id, item_id)

	if texture == null:
		sprite.visible = false
		sprite.texture = null
		push_warning("PlayerAvatar: Missing texture for %s / %s" % [slot_id, item_id])
		return

	sprite.texture = texture
	sprite.visible = true

	if slot_id == "body":
		sprite.modulate = CustomizationDefinitions.get_body_color(color_id)
	else:
		sprite.modulate = CustomizationDefinitions.get_dye_color(color_id)
