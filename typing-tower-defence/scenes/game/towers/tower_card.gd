extends Control
class_name TowerCard

signal tower_selected(tower_type: String)

@export var card_size: Vector2 = Vector2(150, 210)
@export var hover_scale: Vector2 = Vector2(1.06, 1.06)
@export var selected_border_padding: float = 4.0
@export var selected_border_color: Color = Color(1.0, 0.88, 0.2, 0.9)

@onready var info_card: PanelContainer = %InfoCard
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var cost_label: Label = %CostLabel
@onready var stats_label: Label = %StatsLabel
@onready var icon_texture: TextureRect = %IconTexture
@onready var select_button: BaseButton = %SelectButton
@onready var selected_border: ColorRect = %SelectedBorder

var tower_type: String = ""
var tower_data: Dictionary = {}

var current_gold: int = 0
var can_afford: bool = true
var is_selected: bool = false

var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_base_scale = scale

	custom_minimum_size = card_size
	size = card_size
	pivot_offset = card_size * 0.5

	_setup_card_size()
	_setup_button()
	_setup_labels()
	_setup_selected_border()

	_apply_card_data()
	_refresh_afford_state()
	_refresh_selection_visuals()
	_start_info_card_float()


func setup_card(new_tower_type: String, new_tower_data: Dictionary) -> void:
	tower_type = new_tower_type
	tower_data = new_tower_data.duplicate(true)

	if is_node_ready():
		_apply_card_data()
		_refresh_afford_state()
		_refresh_selection_visuals()


func refresh_card(new_current_gold: int, new_can_afford: bool) -> void:
	current_gold = new_current_gold
	can_afford = new_can_afford

	if is_node_ready():
		_refresh_afford_state()


func set_selected(new_is_selected: bool) -> void:
	is_selected = new_is_selected

	if is_node_ready():
		_refresh_selection_visuals()


func _setup_card_size() -> void:
	if info_card != null:
		info_card.custom_minimum_size = card_size
		info_card.size = card_size
		info_card.position = Vector2.ZERO
		info_card.z_index = 1
		info_card.modulate.a = 1.0

	if selected_border != null:
		selected_border.z_index = 0

	if icon_texture != null:
		icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _setup_button() -> void:
	if select_button == null:
		return

	select_button.custom_minimum_size = card_size
	select_button.size = card_size
	select_button.position = Vector2.ZERO
	select_button.focus_mode = Control.FOCUS_NONE
	select_button.modulate.a = 0.0
	select_button.z_index = 50
	select_button.disabled = false

	if not select_button.pressed.is_connected(_on_select_pressed):
		select_button.pressed.connect(_on_select_pressed)

	if not select_button.mouse_entered.is_connected(_on_button_hovered):
		select_button.mouse_entered.connect(_on_button_hovered)

	if not select_button.mouse_exited.is_connected(_on_button_unhovered):
		select_button.mouse_exited.connect(_on_button_unhovered)


func _setup_labels() -> void:
	_configure_label(name_label, 14)
	_configure_label(description_label, 9)
	_configure_label(cost_label, 12)
	_configure_label(stats_label, 10)


func _configure_label(label: Label, font_size: int) -> void:
	if label == null:
		return

	label.visible = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("line_spacing", -2)


func _setup_selected_border() -> void:
	if selected_border == null:
		return

	selected_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_border.color = selected_border_color
	selected_border.visible = false
	_update_selected_border_size()


func _update_selected_border_size() -> void:
	if selected_border == null or info_card == null:
		return

	selected_border.position = info_card.position - Vector2(selected_border_padding, selected_border_padding)
	selected_border.size = info_card.size + Vector2(selected_border_padding * 2.0, selected_border_padding * 2.0)


func _apply_card_data() -> void:
	if tower_type.is_empty():
		return

	if name_label != null:
		name_label.text = str(tower_data.get("display_name", tower_type))

	if description_label != null:
		description_label.text = str(tower_data.get("description", ""))

	if cost_label != null:
		var cost: int = int(tower_data.get("cost", -1))
		cost_label.text = "Cost: %d" % cost if cost >= 0 else "Unavailable"

	if stats_label != null:
		stats_label.text = _build_stats_text()

	if icon_texture != null:
		icon_texture.texture = tower_data.get("icon", null)


func _refresh_afford_state() -> void:
	if info_card != null:
		info_card.modulate.a = 1.0

	if cost_label != null:
		var cost: int = int(tower_data.get("cost", -1))
		if cost < 0:
			cost_label.text = "Unavailable"
		elif can_afford:
			cost_label.text = "Cost: %d" % cost
		else:
			cost_label.text = "Cost: %d\nNeed gold" % cost


func _refresh_selection_visuals() -> void:
	if selected_border != null:
		selected_border.visible = is_selected
		_update_selected_border_size()


func _build_stats_text() -> String:
	var effect: String = str(tower_data.get("effect", ""))
	var damage: int = int(tower_data.get("damage", 0))
	var attack_interval: float = float(tower_data.get("attack_interval", 0.0))
	var tower_range: int = int(tower_data.get("range", 0.0))

	match effect:
		"single_target_projectile":
			return "Single Target\nDMG: %d\nRate: %.2fs\nRange: %d" % [
				damage,
				attack_interval,
				tower_range
			]

		"chain_lightning":
			return "Chain Lightning\nDMG: %d\nTargets: %d\nRate: %.2fs\nRange: %d" % [
				damage,
				int(tower_data.get("max_chain_targets", 1)),
				attack_interval,
				tower_range
			]

		"area_slow":
			var slow_multiplier: float = float(tower_data.get("slow_multiplier", 1.0))
			var slow_percent: int = int(round((1.0 - slow_multiplier) * 100.0))
			return "Area Slow\nSlow: %d%%\nRange: %d" % [
				slow_percent,
				tower_range
			]

		_:
			return "Effect: %s\nDMG: %d\nRange: %d" % [
				effect,
				damage,
				tower_range
			]


func _on_select_pressed() -> void:
	if tower_type.is_empty():
		return
	if not can_afford:
		return

	tower_selected.emit(tower_type)


func _on_button_hovered() -> void:
	_kill_tree_meta_tween("hover_tween")

	var tween := create_tween()
	tween.tween_property(self, "scale", _base_scale * hover_scale, 0.12)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	set_meta("hover_tween", tween)


func _on_button_unhovered() -> void:
	_kill_tree_meta_tween("hover_tween")

	var tween := create_tween()
	tween.tween_property(self, "scale", _base_scale, 0.12)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	set_meta("hover_tween", tween)


func _start_info_card_float() -> void:
	if info_card == null:
		return

	_kill_meta_tween(info_card, "float_tween")

	var base_pos: Vector2 = info_card.position
	info_card.set_meta("base_pos", base_pos)

	var tween := create_tween()
	tween.set_loops()

	tween.tween_property(info_card, "position", base_pos + Vector2(0, -3), 1.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(info_card, "position", base_pos + Vector2(0, 2), 1.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(info_card, "position", base_pos, 1.0)\
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
