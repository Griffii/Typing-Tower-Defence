## shop_mennu_overlay.gd
## Script for the in game shop that appears between waves and gives access to the build mode

extends CanvasLayer

signal next_wave_requested
signal purchase_requested(upgrade_id: String)
signal build_mode_requested

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel

@onready var repair_button: Button = %RepairButton
@onready var build_mode_button: Button = %BuildModeButton
@onready var word_damage_button: Button = %WordDamageButton
@onready var special_damage_button: Button = %SpecialDamageButton
@onready var special_meter_button: Button = %SpecialMeterButton
@onready var gold_gain_button: Button = %GoldGainButton
@onready var next_wave_button: Button = %NextWaveButton

@onready var card_root_word_damage: Control = %CardRoot_WordDamage
@onready var card_root_special_damage: Control = %CardRoot_SpecialDamage
@onready var card_root_special_meter: Control = %CardRoot_SpecialMeter
@onready var card_root_gold_gain: Control = %CardRoot_GoldGain

@onready var card_hover_sfx: AudioStreamPlayer2D = %CardHoverSfx
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var current_shop_state: Dictionary = {}
var current_upgrade_defs: Dictionary = {}

var animated_cards: Array[Control] = []
var animated_buttons: Array[Button] = []

var base_positions: Dictionary = {}
var hover_offsets: Dictionary = {}
var hover_targets: Dictionary = {}
var sway_speeds: Dictionary = {}
var sway_phases: Dictionary = {}

var button_base_scales: Dictionary = {}
var button_hovered: Dictionary = {}

var next_wave_base_position: Vector2 = Vector2.ZERO
var next_wave_sway_speed: float = 1.5
var next_wave_sway_phase: float = 0.0
var next_wave_wiggle_offset: float = 0.0

const HOVER_LIFT_Y: float = -15.0
const HOVER_LERP_SPEED: float = 50.0
const BOB_AMPLITUDE: float = 2.0
const ROTATION_AMPLITUDE: float = 0.02
const HOVER_Z_INDEX: int = 10
const NORMAL_Z_INDEX: int = 0

const BUTTON_HOVER_SCALE: Vector2 = Vector2(1.06, 1.06)
const BUTTON_SCALE_LERP_SPEED: float = 18.0

const NEXT_WAVE_BOB_AMPLITUDE: float = 3.0
const NEXT_WAVE_ROTATION_AMPLITUDE: float = 0.025
const NEXT_WAVE_WIGGLE_AMOUNT: float = 0.12
const NEXT_WAVE_WIGGLE_TIME: float = 0.16


func _ready() -> void:
	visible = false
	description_label.text = ""

	repair_button.pressed.connect(_on_repair_pressed)
	build_mode_button.pressed.connect(_on_build_mode_pressed)
	word_damage_button.pressed.connect(_on_word_damage_pressed)
	special_damage_button.pressed.connect(_on_special_damage_pressed)
	special_meter_button.pressed.connect(_on_special_meter_pressed)
	gold_gain_button.pressed.connect(_on_gold_gain_pressed)
	next_wave_button.pressed.connect(_on_next_wave_pressed)

	_setup_card_animations()
	_setup_button_hover_effects()
	_setup_next_wave_animation()


func _process(delta: float) -> void:
	if not visible:
		return

	var time_now: float = Time.get_ticks_msec() / 1000.0

	for card in animated_cards:
		if not is_instance_valid(card):
			continue

		var current_hover: float = float(hover_offsets.get(card, 0.0))
		var target_hover: float = float(hover_targets.get(card, 0.0))

		current_hover = move_toward(
			current_hover,
			target_hover,
			HOVER_LERP_SPEED * delta
		)

		hover_offsets[card] = current_hover

		var speed: float = float(sway_speeds.get(card, 1.0))
		var phase: float = float(sway_phases.get(card, 0.0))

		var bob_y: float = sin(time_now * speed + phase) * BOB_AMPLITUDE
		var rot: float = sin(time_now * speed * 0.8 + phase) * ROTATION_AMPLITUDE

		var base_pos: Vector2 = base_positions.get(card, card.position)

		card.position = base_pos + Vector2(
			0.0,
			current_hover + bob_y
		)

		card.rotation = rot

	_update_button_scales(delta)
	_update_next_wave_motion(time_now)


func show_overlay(shop_state: Dictionary, upgrade_defs: Dictionary) -> void:
	current_shop_state = shop_state.duplicate(true)
	current_upgrade_defs = upgrade_defs.duplicate(true)

	visible = true
	_update_ui()

	if animation_player != null and animation_player.has_animation("open_menu"):
		animation_player.play("open_menu")


func hide_overlay() -> void:
	if animation_player != null and animation_player.has_animation("close_menu"):
		animation_player.play("close_menu")
		await animation_player.animation_finished

	visible = false

	current_shop_state.clear()
	current_upgrade_defs.clear()

	description_label.text = ""

	for card in animated_cards:
		if not is_instance_valid(card):
			continue

		card.rotation = 0.0
		card.position = base_positions.get(card, card.position)
		card.z_index = NORMAL_Z_INDEX

		hover_offsets[card] = 0.0
		hover_targets[card] = 0.0

	for button in animated_buttons:
		if not is_instance_valid(button):
			continue

		button.scale = button_base_scales.get(button, Vector2.ONE)
		button_hovered[button] = false

	if next_wave_button != null:
		next_wave_button.position = next_wave_base_position
		next_wave_button.rotation = 0.0


func refresh_shop(shop_state: Dictionary, upgrade_defs: Dictionary) -> void:
	current_shop_state = shop_state.duplicate(true)
	current_upgrade_defs = upgrade_defs.duplicate(true)

	if visible:
		_update_ui()


func set_next_wave_button_visible(enabled: bool) -> void:
	if next_wave_button == null:
		return

	next_wave_button.visible = enabled
	next_wave_button.disabled = not enabled


func _setup_card_animations() -> void:
	animated_cards = [
		card_root_word_damage,
		card_root_special_damage,
		card_root_special_meter,
		card_root_gold_gain,
	]

	for card in animated_cards:
		if card == null:
			continue

		base_positions[card] = card.position
		hover_offsets[card] = 0.0
		hover_targets[card] = 0.0

		sway_speeds[card] = randf_range(1.2, 2.0)
		sway_phases[card] = randf_range(0.0, TAU)

		card.z_index = NORMAL_Z_INDEX

	word_damage_button.mouse_entered.connect(func() -> void:
		_on_card_hover_entered(card_root_word_damage)
	)

	word_damage_button.mouse_exited.connect(func() -> void:
		_on_card_hover_exited(card_root_word_damage)
	)

	special_damage_button.mouse_entered.connect(func() -> void:
		_on_card_hover_entered(card_root_special_damage)
	)

	special_damage_button.mouse_exited.connect(func() -> void:
		_on_card_hover_exited(card_root_special_damage)
	)

	special_meter_button.mouse_entered.connect(func() -> void:
		_on_card_hover_entered(card_root_special_meter)
	)

	special_meter_button.mouse_exited.connect(func() -> void:
		_on_card_hover_exited(card_root_special_meter)
	)

	gold_gain_button.mouse_entered.connect(func() -> void:
		_on_card_hover_entered(card_root_gold_gain)
	)

	gold_gain_button.mouse_exited.connect(func() -> void:
		_on_card_hover_exited(card_root_gold_gain)
	)


func _setup_button_hover_effects() -> void:
	animated_buttons = [
		repair_button,
		build_mode_button,
		next_wave_button,
	]

	for button in animated_buttons:
		if button == null:
			continue

		button.pivot_offset = button.size * 0.5

		button_base_scales[button] = button.scale
		button_hovered[button] = false

		button.mouse_entered.connect(func() -> void:
			_on_button_hover_entered(button)
		)

		button.mouse_exited.connect(func() -> void:
			_on_button_hover_exited(button)
		)


func _setup_next_wave_animation() -> void:
	if next_wave_button == null:
		return

	next_wave_base_position = next_wave_button.position
	next_wave_sway_speed = randf_range(1.2, 1.8)
	next_wave_sway_phase = randf_range(0.0, TAU)


func _update_button_scales(delta: float) -> void:
	for button in animated_buttons:
		if button == null or not is_instance_valid(button):
			continue

		var base_scale: Vector2 = button_base_scales.get(button, Vector2.ONE)

		var target_scale: Vector2 = (
			base_scale * BUTTON_HOVER_SCALE
			if bool(button_hovered.get(button, false))
			else base_scale
		)

		button.scale = button.scale.lerp(
			target_scale,
			clampf(BUTTON_SCALE_LERP_SPEED * delta, 0.0, 1.0)
		)


func _update_next_wave_motion(time_now: float) -> void:
	if next_wave_button == null:
		return

	var bob_y: float = sin(
		time_now * next_wave_sway_speed + next_wave_sway_phase
	) * NEXT_WAVE_BOB_AMPLITUDE

	var rot: float = sin(
		time_now * next_wave_sway_speed * 0.8 + next_wave_sway_phase
	) * NEXT_WAVE_ROTATION_AMPLITUDE

	next_wave_button.position = next_wave_base_position + Vector2(0.0, bob_y)
	next_wave_button.rotation = rot + next_wave_wiggle_offset


func _on_button_hover_entered(button: Button) -> void:
	if button == null:
		return

	button_hovered[button] = true

	if button == next_wave_button:
		_play_next_wave_wiggle_once()


func _on_button_hover_exited(button: Button) -> void:
	if button == null:
		return

	button_hovered[button] = false


func _play_next_wave_wiggle_once() -> void:
	if next_wave_button == null:
		return

	var tween := create_tween()

	tween.tween_property(
		self,
		"next_wave_wiggle_offset",
		NEXT_WAVE_WIGGLE_AMOUNT,
		NEXT_WAVE_WIGGLE_TIME
	)

	tween.tween_property(
		self,
		"next_wave_wiggle_offset",
		-NEXT_WAVE_WIGGLE_AMOUNT,
		NEXT_WAVE_WIGGLE_TIME
	)

	tween.tween_property(
		self,
		"next_wave_wiggle_offset",
		0.0,
		NEXT_WAVE_WIGGLE_TIME
	)


func _on_card_hover_entered(card_root: Control) -> void:
	if not is_instance_valid(card_root):
		return

	hover_targets[card_root] = HOVER_LIFT_Y
	card_root.z_index = HOVER_Z_INDEX

	if card_hover_sfx != null:
		card_hover_sfx.play()


func _on_card_hover_exited(card_root: Control) -> void:
	if not is_instance_valid(card_root):
		return

	hover_targets[card_root] = 0.0
	card_root.z_index = NORMAL_Z_INDEX


func _update_ui() -> void:
	repair_button.text = _build_repair_button_text()

	word_damage_button.text = _build_upgrade_button_text("word_damage")
	special_damage_button.text = _build_upgrade_button_text("special_damage")
	special_meter_button.text = _build_upgrade_button_text("special_meter_gain")
	gold_gain_button.text = _build_upgrade_button_text("gold_gain")

	build_mode_button.text = "Build Mode"
	next_wave_button.text = "Next Wave"

	repair_button.disabled = not _can_afford("repair_base")
	word_damage_button.disabled = _is_upgrade_disabled("word_damage")
	special_damage_button.disabled = _is_upgrade_disabled("special_damage")
	special_meter_button.disabled = _is_upgrade_disabled("special_meter_gain")
	gold_gain_button.disabled = _is_upgrade_disabled("gold_gain")

	description_label.text = _build_description_text()
	description_label.size = description_label.get_combined_minimum_size()


func _build_repair_button_text() -> String:
	if not current_upgrade_defs.has("repair_base"):
		return "Repair"

	var def: Dictionary = current_upgrade_defs["repair_base"]

	var value: int = int(def.get("value_per_level", 0))
	var cost: int = int(_get_upgrade_cost("repair_base"))

	return "Repair +%d HP\n($%d)" % [value, cost]


func _build_upgrade_button_text(upgrade_id: String) -> String:
	if not current_upgrade_defs.has(upgrade_id):
		return upgrade_id

	var def: Dictionary = current_upgrade_defs[upgrade_id]

	var display_name: String = String(def.get("display_name", upgrade_id))
	var level: int = int(_get_upgrade_level(upgrade_id))
	var cost: int = int(_get_upgrade_cost(upgrade_id))
	var max_level: int = int(def.get("max_level", -1))

	if max_level >= 0 and level >= max_level:
		return "%s Lv.%d\n(MAX)" % [display_name, level]

	return "%s Lv.%d\n($%d)" % [
		display_name,
		level,
		cost
	]


func _build_description_text() -> String:
	var base_hp: int = int(current_shop_state.get("base_hp", 0))
	var base_hp_max: int = int(current_shop_state.get("base_hp_max", 0))

	var word_damage: int = int(current_shop_state.get("word_damage", 0))
	var special_damage: int = int(current_shop_state.get("special_damage", 0))

	var special_gain: float = float(
		current_shop_state.get("special_meter_gain_per_word", 0.0)
	)

	var gold_multiplier: float = float(
		current_shop_state.get("gold_gain_multiplier", 1.0)
	)

	return "Base HP: %d / %d\nWord Damage: %d\nSpecial Damage: %d\nSpecial Charge/Word: %.1f\nGold Multiplier: x%.2f" % [
		base_hp,
		base_hp_max,
		word_damage,
		special_damage,
		special_gain,
		gold_multiplier
	]


func _get_upgrade_level(upgrade_id: String) -> int:
	var levels: Dictionary = current_shop_state.get("upgrade_levels", {})
	return int(levels.get(upgrade_id, 0))


func _get_upgrade_cost(upgrade_id: String) -> int:
	if not current_upgrade_defs.has(upgrade_id):
		return 999999

	var def: Dictionary = current_upgrade_defs[upgrade_id]
	var level: int = _get_upgrade_level(upgrade_id)

	return int(def.get("base_cost", 0)) + level * int(def.get("cost_scaling", 0))


func _can_afford(upgrade_id: String) -> bool:
	var gold: int = int(current_shop_state.get("gold", 0))
	return gold >= _get_upgrade_cost(upgrade_id)


func _is_upgrade_disabled(upgrade_id: String) -> bool:
	if not current_upgrade_defs.has(upgrade_id):
		return true

	var def: Dictionary = current_upgrade_defs[upgrade_id]

	var level: int = _get_upgrade_level(upgrade_id)
	var max_level: int = int(def.get("max_level", -1))

	if max_level >= 0 and level >= max_level:
		return true

	return not _can_afford(upgrade_id)


func _on_repair_pressed() -> void:
	purchase_requested.emit("repair_base")


func _on_build_mode_pressed() -> void:
	build_mode_requested.emit()


func _on_word_damage_pressed() -> void:
	purchase_requested.emit("word_damage")


func _on_special_damage_pressed() -> void:
	purchase_requested.emit("special_damage")


func _on_special_meter_pressed() -> void:
	purchase_requested.emit("special_meter_gain")


func _on_gold_gain_pressed() -> void:
	purchase_requested.emit("gold_gain")


func _on_next_wave_pressed() -> void:
	next_wave_requested.emit()
