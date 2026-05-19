extends CanvasLayer

signal return_to_shop_requested
signal tower_purchase_requested(slot_id: String, tower_type: String)

const TowerDefinitions = preload("res://data/towers/tower_definitions.gd")

const TOWER_BUILD_LOCATION_NODE_SCENE: PackedScene = preload("res://scenes/game/towers/tower_build_location_node.tscn")
const TOWER_CARD_SCENE: PackedScene = preload("res://scenes/game/towers/tower_card.tscn")

@onready var return_button: Button = %ReturnToShopButton
@onready var slot_node_container: Node2D = %SlotNodeContainer
@onready var tower_card_container: HBoxContainer = %TowerCardContainer

var _current_level: Node = null
var _slot_markers: Dictionary = {}
var _slot_nodes: Dictionary = {}
var _tower_card_nodes: Dictionary = {}

var _current_build_state: Dictionary = {}
var _current_gold: int = 0
var _allowed_tower_types: Array[String] = []
var _selected_tower_type: String = ""


func _ready() -> void:
	visible = false
	set_process(false)

	if return_button != null and not return_button.pressed.is_connected(_on_return_pressed):
		return_button.pressed.connect(_on_return_pressed)


func set_level(level: Node) -> void:
	_current_level = level
	_rebuild_slot_nodes()
	_rebuild_tower_cards()

	if visible and not _current_build_state.is_empty():
		refresh_build(_current_build_state)


func show_overlay(build_state: Dictionary) -> void:
	visible = true
	set_process(true)

	_current_build_state = build_state.duplicate(true)

	if _slot_nodes.is_empty():
		_rebuild_slot_nodes()

	if _tower_card_nodes.is_empty():
		_rebuild_tower_cards()

	_refresh_slot_node_positions()
	refresh_build(_current_build_state)


func hide_overlay() -> void:
	visible = false
	set_process(false)
	_selected_tower_type = ""

	_refresh_tower_card_selection()
	_refresh_build_location_states()


func refresh_build(build_state: Dictionary) -> void:
	_current_build_state = build_state.duplicate(true)
	_current_gold = int(build_state.get("gold", 0))

	_refresh_tower_cards()
	_refresh_tower_card_selection()
	_refresh_build_location_states()


func _process(_delta: float) -> void:
	if visible:
		_refresh_slot_node_positions()


func _rebuild_slot_nodes() -> void:
	_clear_slot_nodes()
	_slot_markers.clear()

	if _current_level == null:
		return
	if not _current_level.has_method("get_tower_slots"):
		return

	var markers: Array[Marker2D] = _current_level.get_tower_slots()

	for marker in markers:
		if marker == null or not is_instance_valid(marker):
			continue

		var slot_id: String = marker.name
		_slot_markers[slot_id] = marker

		var slot_node: Node = TOWER_BUILD_LOCATION_NODE_SCENE.instantiate()
		slot_node_container.add_child(slot_node)

		if slot_node.has_method("setup_slot"):
			slot_node.setup_slot(slot_id)

		if slot_node.has_signal("build_location_pressed"):
			slot_node.build_location_pressed.connect(_on_build_location_pressed)

		_slot_nodes[slot_id] = slot_node

	_refresh_slot_node_positions()


func _rebuild_tower_cards() -> void:
	_clear_tower_cards()
	_allowed_tower_types = _get_allowed_tower_types_for_level()

	if tower_card_container == null:
		return

	for tower_type in _allowed_tower_types:
		if not TowerDefinitions.has_tower_type(tower_type):
			continue

		var card: Node = TOWER_CARD_SCENE.instantiate()
		tower_card_container.add_child(card)

		var tower_data: Dictionary = TowerDefinitions.get_tower_data(tower_type)

		if card.has_method("setup_card"):
			card.setup_card(tower_type, tower_data)

		if card.has_signal("tower_selected"):
			card.tower_selected.connect(_on_tower_card_selected)

		_tower_card_nodes[tower_type] = card

	# Do not auto-select. User must click one.
	_selected_tower_type = ""

	_refresh_tower_cards()
	_refresh_tower_card_selection()


func _get_allowed_tower_types_for_level() -> Array[String]:
	if _current_level != null and _current_level.has_method("get_allowed_tower_types"):
		return _current_level.get_allowed_tower_types()

	return TowerDefinitions.get_all_tower_types()


func _clear_slot_nodes() -> void:
	for slot_node in _slot_nodes.values():
		if slot_node != null and is_instance_valid(slot_node):
			slot_node.queue_free()

	_slot_nodes.clear()


func _clear_tower_cards() -> void:
	for card in _tower_card_nodes.values():
		if card != null and is_instance_valid(card):
			card.queue_free()

	_tower_card_nodes.clear()


func _refresh_slot_node_positions() -> void:
	for slot_id in _slot_markers.keys():
		var marker: Marker2D = _slot_markers[slot_id]
		var slot_node: Node = _slot_nodes.get(slot_id, null)

		if marker == null or not is_instance_valid(marker):
			continue
		if slot_node == null or not is_instance_valid(slot_node):
			continue

		if slot_node.has_method("set_screen_position"):
			slot_node.set_screen_position(_world_to_screen(marker.global_position))


func _refresh_tower_cards() -> void:
	for tower_type in _tower_card_nodes.keys():
		var card: Node = _tower_card_nodes[tower_type]
		if card == null or not is_instance_valid(card):
			continue

		var cost: int = TowerDefinitions.get_cost(tower_type)
		var can_afford: bool = cost >= 0 and _current_gold >= cost

		if card.has_method("refresh_card"):
			card.refresh_card(_current_gold, can_afford)


func _refresh_tower_card_selection() -> void:
	for tower_type in _tower_card_nodes.keys():
		var card: Node = _tower_card_nodes[tower_type]
		if card == null or not is_instance_valid(card):
			continue

		if card.has_method("set_selected"):
			card.set_selected(tower_type == _selected_tower_type)


func _refresh_build_location_states() -> void:
	var slots: Dictionary = _current_build_state.get("slots", {})
	var has_selected_tower: bool = not _selected_tower_type.is_empty()
	var selected_cost: int = TowerDefinitions.get_cost(_selected_tower_type)

	var slots_to_remove: Array[String] = []

	for slot_id in _slot_nodes.keys():
		var slot_node: Node = _slot_nodes[slot_id]
		if slot_node == null or not is_instance_valid(slot_node):
			slots_to_remove.append(slot_id)
			continue

		var slot_data: Dictionary = {}
		if slots.has(slot_id) and slots[slot_id] is Dictionary:
			slot_data = slots[slot_id]

		var built_tower_type: String = str(slot_data.get("tower_type", ""))
		var is_occupied: bool = not built_tower_type.is_empty()

		if is_occupied:
			slot_node.queue_free()
			slots_to_remove.append(slot_id)
			continue

		var can_afford_selected: bool = has_selected_tower and selected_cost >= 0 and _current_gold >= selected_cost
		var can_build: bool = has_selected_tower and can_afford_selected

		if slot_node.has_method("refresh_slot_state"):
			slot_node.refresh_slot_state(slot_data, can_build, _selected_tower_type)

	for slot_id in slots_to_remove:
		_slot_nodes.erase(slot_id)


func _world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position


func _on_tower_card_selected(tower_type: String) -> void:
	if not _allowed_tower_types.has(tower_type):
		return
	if not TowerDefinitions.has_tower_type(tower_type):
		return

	_selected_tower_type = tower_type

	_refresh_tower_card_selection()
	_refresh_build_location_states()


func _on_build_location_pressed(slot_id: String) -> void:
	if _selected_tower_type.is_empty():
		return
	if not TowerDefinitions.has_tower_type(_selected_tower_type):
		return

	var cost: int = TowerDefinitions.get_cost(_selected_tower_type)
	if cost < 0 or _current_gold < cost:
		return

	tower_purchase_requested.emit(slot_id, _selected_tower_type)


func _on_return_pressed() -> void:
	return_to_shop_requested.emit()
