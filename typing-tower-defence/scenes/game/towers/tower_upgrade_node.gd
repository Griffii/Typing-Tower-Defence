extends Node2D
class_name TowerUpgradeNode

signal purchase_requested(slot_id: String, tower_type: String)

const TowerDefinitions = preload("res://data/towers/tower_definitions.gd")
const TOWER_TYPE_BUTTON_SCENE: PackedScene = preload("res://scenes/game/towers/tower_type_button.tscn")

@onready var tower_type_buttons: VBoxContainer = %TowerTypeButtons
@onready var area_ring: Sprite2D = %AreaRing
@onready var info_card: PanelContainer = %InfoCard
@onready var cost_label: Label = %CostLabel
@onready var stats_label: Label = %StatsLabel
@onready var purchase_button: TextureButton = %PurchaseButton
@onready var build_sfx: AudioStreamPlayer2D = %BuildSfx
@onready var upgrade_sfx: AudioStreamPlayer2D = %UpgradeSfx

var slot_id: String = ""
var allowed_tower_types: Array[String] = []
var selected_tower_type: String = ""

var _tower_type_button_group: ButtonGroup = ButtonGroup.new()
var _type_button_nodes: Dictionary = {}
var _last_level: int = 0
var _last_built_tower_type: String = ""
var _current_slot_data: Dictionary = {}
var _current_gold: int = 0


func _ready() -> void:
	_tower_type_button_group.allow_unpress = false

	if purchase_button != null:
		if not purchase_button.pressed.is_connected(_on_purchase_pressed):
			purchase_button.pressed.connect(_on_purchase_pressed)

		if not purchase_button.mouse_entered.is_connected(_on_button_hovered):
			purchase_button.mouse_entered.connect(_on_button_hovered)

		if not purchase_button.mouse_exited.is_connected(_on_button_unhovered):
			purchase_button.mouse_exited.connect(_on_button_unhovered)

		purchase_button.scale = Vector2.ONE
		purchase_button.modulate.a = 0.35
		purchase_button.pivot_offset = purchase_button.size * 0.5

	if info_card != null:
		info_card.visible = false
		info_card.pivot_offset = info_card.size * 0.5
		_start_info_card_float()


func setup_slot(new_slot_id: String, new_allowed_tower_types: Array[String] = []) -> void:
	slot_id = new_slot_id
	allowed_tower_types.clear()

	for tower_type in new_allowed_tower_types:
		var tower_type_str := str(tower_type)
		if TowerDefinitions.has_tower_type(tower_type_str):
			allowed_tower_types.append(tower_type_str)

	if allowed_tower_types.is_empty():
		allowed_tower_types = ["arrow"]

	if selected_tower_type.is_empty() or not allowed_tower_types.has(selected_tower_type):
		selected_tower_type = allowed_tower_types[0]

	_rebuild_type_buttons()
	_refresh_type_button_selection()
	_refresh_type_button_visibility()
	_refresh_info_panel()
	_refresh_purchase_button_state()


func set_screen_position(screen_position: Vector2) -> void:
	global_position = screen_position


func set_info_card_visible(is_visible: bool) -> void:
	if info_card != null:
		info_card.visible = is_visible


func refresh_slot_state(slot_data: Variant, current_gold: int) -> void:
	_current_gold = current_gold

	if slot_data == null:
		_current_slot_data = {}
		_set_unavailable_state()
		return

	_current_slot_data = slot_data as Dictionary

	var level: int = int(_current_slot_data.get("level", 0))
	var built_tower_type: String = str(_current_slot_data.get("tower_type", ""))

	_play_purchase_sfx_if_needed(level, built_tower_type)

	if level > 0 and not built_tower_type.is_empty():
		selected_tower_type = built_tower_type
	elif selected_tower_type.is_empty() and not allowed_tower_types.is_empty():
		selected_tower_type = allowed_tower_types[0]

	_refresh_type_button_visibility()
	_refresh_type_button_selection()
	_refresh_info_panel()
	_refresh_purchase_button_state()

	if info_card != null:
		info_card.visible = false

	_last_level = level
	_last_built_tower_type = built_tower_type


func _rebuild_type_buttons() -> void:
	for child in tower_type_buttons.get_children():
		child.queue_free()

	_type_button_nodes.clear()
	_tower_type_button_group = ButtonGroup.new()
	_tower_type_button_group.allow_unpress = false

	for tower_type in allowed_tower_types:
		var button = TOWER_TYPE_BUTTON_SCENE.instantiate()
		tower_type_buttons.add_child(button)

		if button.has_method("setup_button"):
			button.setup_button(tower_type, _tower_type_button_group)

		if button.has_signal("tower_type_selected"):
			button.tower_type_selected.connect(_on_tower_type_selected)

		_type_button_nodes[tower_type] = button


func _refresh_type_button_visibility() -> void:
	var level: int = int(_current_slot_data.get("level", 0))
	var show_type_buttons: bool = level <= 0

	if tower_type_buttons != null:
		tower_type_buttons.visible = show_type_buttons

	if area_ring != null:
		area_ring.visible = level <= 0


func _refresh_type_button_selection() -> void:
	for tower_type in _type_button_nodes.keys():
		var button = _type_button_nodes[tower_type]
		if button != null and is_instance_valid(button) and button.has_method("set_selected"):
			button.set_selected(tower_type == selected_tower_type)


func _on_tower_type_selected(tower_type: String) -> void:
	_select_tower_type(tower_type)


func _select_tower_type(tower_type: String) -> void:
	var level: int = int(_current_slot_data.get("level", 0))
	if level > 0:
		return

	if not allowed_tower_types.has(tower_type):
		return

	selected_tower_type = tower_type
	_refresh_type_button_selection()
	_refresh_info_panel()
	_refresh_purchase_button_state()


func _refresh_info_panel() -> void:
	var level: int = int(_current_slot_data.get("level", 0))
	var max_level: int = int(_current_slot_data.get("max_level", 0))
	var current_stats: Dictionary = _current_slot_data.get("current_stats", {})

	var tower_type_to_show := _get_display_tower_type()
	if tower_type_to_show.is_empty():
		_set_unavailable_state()
		return

	if area_ring != null:
		area_ring.visible = level <= 0

	if level > 0:
		if cost_label != null:
			var next_cost_built: int = int(_current_slot_data.get("next_cost", -1))
			if next_cost_built < 0:
				cost_label.text = "Max Level"
			else:
				cost_label.text = "%d" % next_cost_built

		if stats_label != null:
			var damage: int = int(current_stats.get("damage", 0))
			var charge_required: int = int(current_stats.get("charge_required", 0))
			var duration: float = float(current_stats.get("duration", 0.0))
			var cooldown: float = float(current_stats.get("cooldown", 0.0))
			var attack_interval: float = float(current_stats.get("attack_interval", 0.0))
			var range: float = float(current_stats.get("range", 0.0))

			stats_label.text = (
				"LV %d / %d\n"
				+ "DMG: %d\n"
				+ "Charge: %d\n"
				+ "Duration: %.1fs\n"
				+ "Cooldown: %.1fs\n"
				+ "Rate: %.2fs\n"
				+ "Range: %d"
			) % [
				level,
				max_level,
				damage,
				charge_required,
				duration,
				cooldown,
				attack_interval,
				int(range)
			]
		return

	var preview_next_cost: int = TowerDefinitions.get_next_cost(tower_type_to_show, 0)
	var preview_data: Dictionary = TowerDefinitions.get_next_level_data(tower_type_to_show, 0)
	var preview_max_level: int = TowerDefinitions.get_max_level(tower_type_to_show)

	if cost_label != null:
		if preview_next_cost < 0:
			cost_label.text = "Unavailable"
		else:
			cost_label.text = "%d" % preview_next_cost

	if stats_label != null:
		if preview_data.is_empty():
			stats_label.text = "Unavailable"
		else:
			var damage_preview: int = int(preview_data.get("damage", 0))
			var charge_required_preview: int = int(preview_data.get("charge_required", 0))
			var duration_preview: float = float(preview_data.get("duration", 0.0))
			var cooldown_preview: float = float(preview_data.get("cooldown", 0.0))
			var attack_interval_preview: float = float(preview_data.get("attack_interval", 0.0))
			var range_preview: float = float(preview_data.get("range", 0.0))

			stats_label.text = (
				"LV 1 / %d\n"
				+ "DMG: %d\n"
				+ "Words to Charge: %d\n"
				+ "Duration: %.1fs\n"
				+ "Cooldown: %.1fs\n"
				+ "Rate: %.2fs\n"
				+ "Range: %d"
			) % [
				preview_max_level,
				damage_preview,
				charge_required_preview,
				duration_preview,
				cooldown_preview,
				attack_interval_preview,
				int(range_preview)
			]


func _refresh_purchase_button_state() -> void:
	if purchase_button == null:
		return

	var level: int = int(_current_slot_data.get("level", 0))
	var next_cost: int = -1

	if level > 0:
		next_cost = int(_current_slot_data.get("next_cost", -1))
	else:
		if selected_tower_type.is_empty():
			next_cost = -1
		else:
			next_cost = TowerDefinitions.get_next_cost(selected_tower_type, 0)

	var has_selected_type: bool = not selected_tower_type.is_empty()
	var can_afford: bool = next_cost >= 0 and _current_gold >= next_cost
	var can_buy: bool = has_selected_type and can_afford

	purchase_button.disabled = not can_buy
	purchase_button.modulate.a = 0.82 if can_buy else 0.35


func _get_display_tower_type() -> String:
	var built_tower_type: String = str(_current_slot_data.get("tower_type", ""))
	var level: int = int(_current_slot_data.get("level", 0))

	if level > 0 and not built_tower_type.is_empty():
		return built_tower_type

	return selected_tower_type


func _set_unavailable_state() -> void:
	if purchase_button != null:
		purchase_button.disabled = true
		purchase_button.modulate.a = 0.35

	if cost_label != null:
		cost_label.text = ""

	if stats_label != null:
		stats_label.text = "Unavailable"

	if area_ring != null:
		area_ring.visible = false

	if tower_type_buttons != null:
		tower_type_buttons.visible = false

	if info_card != null:
		info_card.visible = false


func _on_purchase_pressed() -> void:
	if slot_id.is_empty():
		return

	if selected_tower_type.is_empty():
		return

	purchase_requested.emit(slot_id, selected_tower_type)


func _on_button_hovered() -> void:
	if purchase_button == null:
		return

	var tween_key := "hover_tween_%s" % purchase_button.get_instance_id()
	_kill_tree_meta_tween(tween_key)

	var target_alpha := 0.35 if purchase_button.disabled else 1.0
	var target_scale := Vector2.ONE if purchase_button.disabled else Vector2(1.08, 1.08)

	var tween := create_tween()
	tween.tween_property(purchase_button, "scale", target_scale, 0.12)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(purchase_button, "modulate:a", target_alpha, 0.12)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	set_meta(tween_key, tween)

	if info_card != null:
		info_card.visible = true


func _on_button_unhovered() -> void:
	if purchase_button != null:
		var tween_key := "hover_tween_%s" % purchase_button.get_instance_id()
		_kill_tree_meta_tween(tween_key)

		var target_alpha := 0.35 if purchase_button.disabled else 0.82

		var tween := create_tween()
		tween.tween_property(purchase_button, "scale", Vector2.ONE, 0.12)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(purchase_button, "modulate:a", target_alpha, 0.12)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		set_meta(tween_key, tween)

	if info_card != null:
		info_card.visible = false


func _play_purchase_sfx_if_needed(new_level: int, built_tower_type: String) -> void:
	if new_level <= _last_level:
		return

	if _last_level <= 0 and new_level >= 1:
		if build_sfx != null:
			build_sfx.play()
	else:
		if upgrade_sfx != null:
			upgrade_sfx.play()

	_last_built_tower_type = built_tower_type


func _start_info_card_float() -> void:
	if info_card == null:
		return

	_kill_meta_tween(info_card, "float_tween")

	var base_pos: Vector2 = info_card.position
	info_card.set_meta("base_pos", base_pos)
	info_card.rotation_degrees = 0.0

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(info_card, "position", base_pos + Vector2(0, -4), 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(info_card, "rotation_degrees", 1.2, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(info_card, "position", base_pos + Vector2(0, 3), 1.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(info_card, "rotation_degrees", -1.0, 1.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(info_card, "position", base_pos, 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(info_card, "rotation_degrees", 0.4, 1.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(info_card, "rotation_degrees", 0.0, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	info_card.set_meta("float_tween", tween)


func _kill_meta_tween(node: Node, key: String) -> void:
	if node == null or not node.has_meta(key):
		return

	var tween = node.get_meta(key)
	if tween != null and is_instance_valid(tween):
		tween.kill()

	node.remove_meta(key)


func _kill_tree_meta_tween(key: String) -> void:
	if not has_meta(key):
		return

	var tween = get_meta(key)
	if tween != null and is_instance_valid(tween):
		tween.kill()

	remove_meta(key)
