# res://scripts/game/player/player_avatar.gd
class_name PlayerAvatar
extends Node2D

@export var default_body: String = "body_01"
@export var default_undies: String = "boy_undies"
@export var default_clothes: String = "clothes_01"
@export var default_hair: String = "hair_01"
@export var default_hat: String = "hat_01"
@export var default_wand: String = "wand_01"

@export var default_state: String = "idle"

@onready var body_sprite: AnimatedSprite2D = %BodySprite
@onready var undies_sprite: AnimatedSprite2D = %UndiesSprite
@onready var clothes_sprite: AnimatedSprite2D = %ClothesSprite
@onready var hair_sprite: AnimatedSprite2D = %HairSprite
@onready var hat_sprite: AnimatedSprite2D = %HatSprite
@onready var wand_sprite: AnimatedSprite2D = %WandSprite

var equipped_body: String = ""
var equipped_body_color: String = "skin_01"
var equipped_undies: String = ""
var equipped_clothes: String = ""
var equipped_hair: String = ""
var equipped_hat: String = ""
var equipped_wand: String = ""

var current_state: String = "idle"


var body_colors: Dictionary = {
	"skin_01": Color("#ffffff"),
	"skin_02": Color("#f2c7a5"),
	"skin_03": Color("#d99a6c"),
	"skin_04": Color("#9b5f3f"),
	"skin_05": Color("#5c3828")
}


func _ready() -> void:
	equipped_body = default_body
	equipped_undies = default_undies
	equipped_clothes = default_clothes
	equipped_hair = default_hair
	equipped_hat = default_hat
	equipped_wand = default_wand
	current_state = default_state

	refresh_visuals()


# ---------------------------
# Public API
# ---------------------------
func apply_loadout(loadout: Dictionary) -> void:
	equipped_body = str(loadout.get("body", equipped_body))
	equipped_body_color = str(loadout.get("body_color", equipped_body_color))
	equipped_undies = str(loadout.get("undies", equipped_undies))
	equipped_clothes = str(loadout.get("clothes", equipped_clothes))
	equipped_hair = str(loadout.get("hair", equipped_hair))
	equipped_hat = str(loadout.get("hat", equipped_hat))
	equipped_wand = str(loadout.get("wand", equipped_wand))

	refresh_visuals()


func get_loadout() -> Dictionary:
	return {
		"body": equipped_body,
		"body_color": equipped_body_color,
		"undies": equipped_undies,
		"clothes": equipped_clothes,
		"hair": equipped_hair,
		"hat": equipped_hat,
		"wand": equipped_wand,
	}


func equip_part(slot_id: String, item_id: String) -> void:
	match slot_id:
		"body":
			equipped_body = item_id
		"body_color":
			equipped_body_color = item_id
		"undies":
			equipped_undies = item_id
		"clothes":
			equipped_clothes = item_id
		"hair":
			equipped_hair = item_id
		"hat":
			equipped_hat = item_id
		"wand":
			equipped_wand = item_id
		_:
			push_warning("PlayerAvatar: Unknown slot_id: " + slot_id)
			return

	refresh_visuals()


func play_idle() -> void:
	set_state("idle")


func set_state(new_state: String) -> void:
	if new_state.is_empty():
		return

	current_state = new_state
	refresh_visuals()


func refresh_visuals() -> void:
	_play_part_animation(body_sprite, equipped_body, current_state)
	_apply_body_color()
	_play_part_animation(undies_sprite, equipped_undies, current_state)
	_play_part_animation(clothes_sprite, equipped_clothes, current_state)
	_play_part_animation(hair_sprite, equipped_hair, current_state)
	_play_part_animation(hat_sprite, equipped_hat, current_state)
	_play_part_animation(wand_sprite, equipped_wand, current_state)


# ---------------------------
# Internal
# ---------------------------
func _play_part_animation(sprite: AnimatedSprite2D, item_id: String, state: String) -> void:
	if sprite == null:
		return

	if item_id.is_empty() or item_id == "none":
		sprite.stop()
		sprite.visible = false
		return

	var animation_name: String = item_id + "_" + state

	if sprite.sprite_frames == null:
		sprite.stop()
		sprite.visible = false
		return

	if not sprite.sprite_frames.has_animation(animation_name):
		sprite.stop()
		sprite.visible = false
		push_warning("PlayerAvatar: Missing animation: " + animation_name)
		return

	sprite.visible = true
	sprite.play(animation_name)
	sprite.frame = 0
	sprite.frame_progress = 0.0

func _apply_body_color() -> void:
	if body_sprite == null:
		return

	var color: Color = body_colors.get(equipped_body_color, Color.WHITE)
	body_sprite.modulate = color
