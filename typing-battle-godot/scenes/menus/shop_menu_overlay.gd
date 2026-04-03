extends CanvasLayer

signal next_wave_requested
signal purchase_requested(upgrade_id: String)
signal build_mode_requested

@onready var title_label: Label = %TitleLabel
@onready var gold_label: Label = %GoldLabel
@onready var description_label: Label = %DescriptionLabel

@onready var repair_button: Button = %RepairButton
@onready var build_mode_button: Button = %BuildModeButton
@onready var word_damage_button: Button = %WordDamageButton
@onready var arrow_damage_button: Button = %ArrowDamageButton
@onready var arrow_meter_button: Button = %ArrowMeterButton
@onready var gold_gain_button: Button = %GoldGainButton
@onready var next_wave_button: Button = %NextWaveButton

@onready var card_root_word_damage: Control = %CardRoot_WordDamage
@onready var card_root_arrow_damage: Control = %CardRoot_ArrowDamage
@onready var card_root_arrow_meter: Control = %CardRoot_ArrowMeter
@onready var card_root_gold_gain: Control = %CardRoot_GoldGain

@onready var card_hover_sfx: AudioStreamPlayer2D = %CardHoverSfx

var current_shop_state: Dictionary = {}
var current_upgrade_defs: Dictionary = {}

var animated_cards: Array[Control] = []
var base_positions: Dictionary = {}
var hover_offsets: Dictionary = {}
var hover_targets: Dictionary = {}
var sway_speeds: Dictionary = {}
var sway_phases: Dictionary = {}

const HOVER_LIFT_Y: float = -15.0
const HOVER_LERP_SPEED: float = 50.0
const BOB_AMPLITUDE: float = 2.0
const ROTATION_AMPLITUDE: float = 0.02
const HOVER_Z_INDEX: int = 10
const NORMAL_Z_INDEX: int = 0


func _ready() -> void:
	visible = false
	description_label.text = ""

	repair_button.pressed.connect(_on_repair_pressed)
	build_mode_button.pressed.connect(_on_build_mode_pressed)
	word_damage_button.pressed.connect(_on_word_damage_pressed)
	arrow_damage_button.pressed.connect(_on_arrow_damage_pressed)
	arrow_meter_button.pressed.connect(_on_arrow_meter_pressed)
	gold_gain_button.pressed.connect(_on_gold_gain_pressed)
	next_wave_button.pressed.connect(_on_next_wave_pressed)

	_setup_card_animations()


func _process(delta: float) -> void:
	if not visible:
		return

	var time_now: float = Time.get_ticks_msec() / 1000.0

	for card in animated_cards:
		if not is_instance_valid(card):
			continue

		var current_hover: float = float(hover_offsets.get(card, 0.0))
		var target_hover: float = float(hover_targets.get(card, 0.0))
		current_hover = move_toward(current_hover, target_hover, HOVER_LERP_SPEED * delta)
		hover_offsets[card] = current_hover

		var speed: float = float(sway_speeds.get(card, 1.0))
		var phase: float = float(sway_phases.get(card, 0.0))

		var bob_y: float = sin(time_now * speed + phase) * BOB_AMPLITUDE
		var rot: float = sin(time_now * speed * 0.8 + phase) * ROTATION_AMPLITUDE

		var base_pos: Vector2 = base_positions.get(card, card.position)
		card.position = base_pos + Vector2(0.0, current_hover + bob_y)
		card.rotation = rot


func show_overlay(shop_state: Dictionary, upgrade_defs: Dictionary) -> void:
	current_shop_state = shop_state.duplicate(true)
	current_upgrade_defs = upgrade_defs.duplicate(true)

	visible = true
	_update_ui()


func hide_overlay() -> void:
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


func refresh_shop(shop_state: Dictionary, upgrade_defs: Dictionary) -> void:
	current_shop_state = shop_state.duplicate(true)
	current_upgrade_defs = upgrade_defs.duplicate(true)

	if visible:
		_update_ui()


func _setup_card_animations() -> void:
	animated_cards = [
		card_root_word_damage,
		card_root_arrow_damage,
		card_root_arrow_meter,
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

	# Hover is driven by the buttons, visual motion is applied to the roots.
	word_damage_button.mouse_entered.connect(func() -> void:
		_on_card_hover_entered(card_root_word_damage)
	)
	word_damage_button.mouse_exited.connect(func() -> void:
		_on_card_hover_exited(card_root_word_damage)
	)

	arrow_damage_button.mouse_entered.connect(func() -> void:
		_on_card_hover_entered(card_root_arrow_damage)
	)
	arrow_damage_button.mouse_exited.connect(func() -> void:
		_on_card_hover_exited(card_root_arrow_damage)
	)

	arrow_meter_button.mouse_entered.connect(func() -> void:
		_on_card_hover_entered(card_root_arrow_meter)
	)
	arrow_meter_button.mouse_exited.connect(func() -> void:
		_on_card_hover_exited(card_root_arrow_meter)
	)

	gold_gain_button.mouse_entered.connect(func() -> void:
		_on_card_hover_entered(card_root_gold_gain)
	)
	gold_gain_button.mouse_exited.connect(func() -> void:
		_on_card_hover_exited(card_root_gold_gain)
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
	var gold: int = int(current_shop_state.get("gold", 0))
	gold_label.text = "Gold: %d" % gold

	repair_button.text = _build_repair_button_text()
	word_damage_button.text = _build_upgrade_button_text("word_damage")
	arrow_damage_button.text = _build_upgrade_button_text("arrow_damage")
	arrow_meter_button.text = _build_upgrade_button_text("arrow_meter_gain")
	gold_gain_button.text = _build_upgrade_button_text("gold_gain")

	build_mode_button.text = "Build Mode"
	next_wave_button.text = "Next Wave"

	repair_button.disabled = not _can_afford("repair_base")
	word_damage_button.disabled = _is_upgrade_disabled("word_damage")
	arrow_damage_button.disabled = _is_upgrade_disabled("arrow_damage")
	arrow_meter_button.disabled = _is_upgrade_disabled("arrow_meter_gain")
	gold_gain_button.disabled = _is_upgrade_disabled("gold_gain")

	description_label.text = _build_description_text()


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

	return "%s Lv.%d\n($%d)" % [display_name, level, cost]


func _build_description_text() -> String:
	var base_hp: int = int(current_shop_state.get("base_hp", 0))
	var base_hp_max: int = int(current_shop_state.get("base_hp_max", 0))
	var word_damage: int = int(current_shop_state.get("word_damage", 0))
	var arrow_damage: int = int(current_shop_state.get("arrow_damage", 0))
	var arrow_gain: float = float(current_shop_state.get("arrow_meter_gain_per_word", 0.0))
	var gold_multiplier: float = float(current_shop_state.get("gold_gain_multiplier", 1.0))

	return "Base HP: %d / %d\nWord Damage: %d\nArrow Damage: %d\nArrow Charge/Word: %.1f\nGold Multiplier: x%.2f" % [
		base_hp,
		base_hp_max,
		word_damage,
		arrow_damage,
		arrow_gain,
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


func _on_arrow_damage_pressed() -> void:
	purchase_requested.emit("arrow_damage")


func _on_arrow_meter_pressed() -> void:
	purchase_requested.emit("arrow_meter_gain")


func _on_gold_gain_pressed() -> void:
	purchase_requested.emit("gold_gain")


func _on_next_wave_pressed() -> void:
	next_wave_requested.emit()
