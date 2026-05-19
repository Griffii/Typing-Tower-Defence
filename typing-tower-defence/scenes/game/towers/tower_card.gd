extends Control
class_name TowerCard

signal tower_selected(tower_type: String)

@export var hover_scale: Vector2 = Vector2(1.04, 1.04)
@export var hover_y_offset: float = -10.0
@export var float_amount: float = 3.0
@export var float_speed_min: float = 1.2
@export var float_speed_max: float = 2.0

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var cost_label: Label = %CostLabel
@onready var stats_label: Label = %StatsLabel
@onready var icon_texture: TextureRect = %IconTexture
@onready var select_button: Button = %SelectButton
@onready var info_card: PanelContainer = %InfoCard

var tower_type: String = ""
var tower_data: Dictionary = {}

var is_hovered: bool = false
var is_selected: bool = false

var _base_info_pos: Vector2 = Vector2.ZERO
var _float_time: float = 0.0
var _float_speed: float = 1.5
var _float_phase: float = 0.0


func _ready() -> void:
	_float_speed = randf_range(float_speed_min, float_speed_max)
	_float_phase = randf_range(0.0, TAU)

	if info_card != null:
		_base_info_pos = info_card.position

	if select_button != null:
		if not select_button.pressed.is_connected(_on_select_pressed):
			select_button.pressed.connect(_on_select_pressed)

		if not select_button.mouse_entered.is_connected(_on_mouse_entered):
			select_button.mouse_entered.connect(_on_mouse_entered)

		if not select_button.mouse_exited.is_connected(_on_mouse_exited):
			select_button.mouse_exited.connect(_on_mouse_exited)

	_apply_card_data()
	set_process(true)


func setup_card(new_tower_type: String, new_tower_data: Dictionary) -> void:
	tower_type = new_tower_type
	tower_data = new_tower_data.duplicate(true)

	if is_node_ready():
		_apply_card_data()


func refresh_card(_current_gold: int, _can_afford: bool) -> void:
	pass


func set_selected(new_is_selected: bool) -> void:
	is_selected = new_is_selected


func get_tower_type() -> String:
	return tower_type


func _process(delta: float) -> void:
	_float_time += delta

	var bob_y: float = sin(_float_time * _float_speed + _float_phase) * float_amount
	var hover_y: float = hover_y_offset if is_hovered and not is_selected else 0.0

	if info_card != null:
		info_card.position = _base_info_pos + Vector2(0.0, bob_y + hover_y)

	scale = hover_scale if is_hovered else Vector2.ONE


func _apply_card_data() -> void:
	if tower_type.is_empty() or tower_data.is_empty():
		return

	if name_label != null:
		name_label.text = str(tower_data.get("display_name", tower_type))

	if description_label != null:
		description_label.text = str(tower_data.get("description", ""))

	if cost_label != null:
		cost_label.text = "Cost: %d" % int(tower_data.get("cost", 0))

	if stats_label != null:
		stats_label.text = _get_stats_text()

	if icon_texture != null:
		icon_texture.texture = tower_data.get("icon", null)


func _get_stats_text() -> String:
	var effect: String = str(tower_data.get("effect", ""))
	var damage: int = int(tower_data.get("damage", 0))
	var rate: float = float(tower_data.get("attack_interval", 0.0))
	var tower_range: int = int(tower_data.get("range", 0))

	match effect:
		"single_target_projectile":
			return "Single Target\nDMG: %d\nRate: %.2fs\nRange: %d" % [damage, rate, tower_range]

		"chain_lightning":
			return "Chain Lightning\nDMG: %d\nTargets: %d\nRate: %.2fs\nRange: %d" % [
				damage,
				int(tower_data.get("max_chain_targets", 1)),
				rate,
				tower_range
			]

		"area_slow":
			var slow: int = int(round((1.0 - float(tower_data.get("slow_multiplier", 1.0))) * 100.0))
			return "Area Slow\nSlow: %d%%\nRange: %d" % [slow, tower_range]

	return "DMG: %d\nRange: %d" % [damage, tower_range]


func _on_select_pressed() -> void:
	if tower_type.is_empty():
		return

	tower_selected.emit(tower_type)


func _on_mouse_entered() -> void:
	is_hovered = true


func _on_mouse_exited() -> void:
	is_hovered = false
