extends CanvasLayer

signal return_to_shop_requested
signal tower_purchase_requested(slot_id: String, tower_type: String)

const TowerDefinitions = preload("res://data/towers/tower_definitions.gd")

const TOWER_BUILD_LOCATION_NODE_SCENE: PackedScene = preload("res://scenes/game/towers/tower_build_location_node.tscn")
const TOWER_CARD_SCENE: PackedScene = preload("res://scenes/game/towers/tower_card.tscn")

@onready var return_button: Button = %ReturnToShopButton
@onready var slot_node_container: Node2D = %SlotNodeContainer

@onready var tower_card_container: HBoxContainer = %TowerCardContainer
@onready var selected_card_holder: Control = %SelectedCardHolder
@onready var selected_card_marker: Marker2D = %SelectedCardMarker

var _current_level: Node = null

var _slot_markers: Dictionary = {}
var _slot_nodes: Dictionary = {}

var _tower_card_nodes: Dictionary = {}
var _card_original_indices: Dictionary = {}

var _selected_card_node: Control = null

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

	if slot_node_container != null:
		slot_node_container.visible = true

	_current_build_state = build_state.duplicate(true)

	_rebuild_slot_nodes()

	if _tower_card_nodes.is_empty():
		_rebuild_tower_cards()

	_refresh_slot_node_positions()
	refresh_build(_current_build_state)


func hide_overlay() -> void:
	if _selected_card_node != null and is_instance_valid(_selected_card_node):
		_return_card_to_hbox(_selected_card_node)

	visible = false
	set_process(false)

	_selected_tower_type = ""
	_selected_card_node = null

	_refresh_build_location_states()


func refresh_build(build_state: Dictionary) -> void:
	_current_build_state = build_state.duplicate(true)
	_current_gold = int(build_state.get("gold", 0))

	_refresh_tower_cards()
	_refresh_build_location_states()


func _process(_delta: float) -> void:
	if visible:
		_refresh_slot_node_positions()


func _rebuild_slot_nodes() -> void:
	_clear_slot_nodes()
	_slot_markers.clear()

	if slot_node_container == null:
		return

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

		if slot_node is CanvasItem:
			(slot_node as CanvasItem).visible = true


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

		var card: Control = TOWER_CARD_SCENE.instantiate() as Control
		tower_card_container.add_child(card)

		_card_original_indices[tower_type] = tower_card_container.get_child_count() - 1

		var tower_data: Dictionary = TowerDefinitions.get_tower_data(tower_type)

		if card.has_method("setup_card"):
			card.setup_card(tower_type, tower_data)

		if card.has_signal("tower_selected"):
			card.tower_selected.connect(_on_tower_card_selected)

		_tower_card_nodes[tower_type] = card

	_selected_tower_type = ""

	_refresh_tower_cards()


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
	_card_original_indices.clear()


func _refresh_slot_node_positions() -> void:
	for slot_id in _slot_markers.keys():
		var marker: Marker2D = _slot_markers[slot_id]
		var slot_node: Node = _slot_nodes.get(slot_id, null)

		if marker == null or not is_instance_valid(marker):
			continue

		if slot_node == null or not is_instance_valid(slot_node):
			continue

		var screen_position: Vector2 = _world_to_screen(marker.global_position)

		if slot_node.has_method("set_screen_position"):
			slot_node.set_screen_position(screen_position)


func _refresh_tower_cards() -> void:
	for tower_type in _tower_card_nodes.keys():
		var card: Node = _tower_card_nodes[tower_type]

		if card == null or not is_instance_valid(card):
			continue

		var cost: int = TowerDefinitions.get_cost(tower_type)
		var can_afford: bool = cost >= 0 and _current_gold >= cost

		if card.has_method("refresh_card"):
			card.refresh_card(_current_gold, can_afford)


func _refresh_build_location_states() -> void:
	var slots: Dictionary = _current_build_state.get("slots", {})

	var has_selected_tower: bool = not _selected_tower_type.is_empty()

	var selected_cost: int = TowerDefinitions.get_cost(_selected_tower_type)

	var can_afford_selected: bool = (
		has_selected_tower
		and selected_cost >= 0
		and _current_gold >= selected_cost
	)

	for slot_id in _slot_nodes.keys():
		var slot_node: Node = _slot_nodes[slot_id]

		if slot_node == null or not is_instance_valid(slot_node):
			continue

		var slot_data: Dictionary = {}

		if slots.has(slot_id) and slots[slot_id] is Dictionary:
			slot_data = slots[slot_id]

		var built_tower_type: String = str(slot_data.get("tower_type", ""))

		var is_occupied: bool = not built_tower_type.is_empty()

		var can_build: bool = (
			has_selected_tower
			and can_afford_selected
			and not is_occupied
		)

		if slot_node.has_method("refresh_slot_state"):
			slot_node.refresh_slot_state(
				slot_data,
				can_build,
				_selected_tower_type
			)


func _world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position


func _on_tower_card_selected(tower_type: String) -> void:
	if not _allowed_tower_types.has(tower_type):
		return

	if not TowerDefinitions.has_tower_type(tower_type):
		return

	if _selected_tower_type == tower_type:
		_deselect_current_card()
		return

	var new_card: Control = _tower_card_nodes.get(tower_type, null) as Control

	if new_card == null or not is_instance_valid(new_card):
		return

	if _selected_card_node != null and is_instance_valid(_selected_card_node):
		_return_card_to_hbox(_selected_card_node)

	_selected_tower_type = tower_type
	_selected_card_node = new_card

	_move_card_to_selected_marker(new_card)

	_refresh_build_location_states()


func _deselect_current_card() -> void:
	if _selected_card_node != null and is_instance_valid(_selected_card_node):
		_return_card_to_hbox(_selected_card_node)

	_selected_tower_type = ""
	_selected_card_node = null

	_refresh_build_location_states()


func _move_card_to_selected_marker(card: Control) -> void:
	if selected_card_holder == null:
		return

	if selected_card_marker == null:
		return

	_kill_card_tween(card)

	var global_start: Vector2 = card.global_position

	if card.get_parent() != selected_card_holder:
		card.get_parent().remove_child(card)
		selected_card_holder.add_child(card)

	card.global_position = global_start


	var target_global_position: Vector2 = selected_card_marker.global_position

	var tween := create_tween()

	tween.tween_property(
		card,
		"global_position",
		target_global_position,
		0.22
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	card.set_meta("move_tween", tween)


func _return_card_to_hbox(card: Control) -> void:
	if tower_card_container == null:
		return

	_kill_card_tween(card)

	var global_start: Vector2 = card.global_position
	var tower_type: String = ""

	if card.has_method("get_tower_type"):
		tower_type = card.get_tower_type()
	else:
		for key in _tower_card_nodes.keys():
			if _tower_card_nodes[key] == card:
				tower_type = key
				break

	if card.get_parent() != tower_card_container:
		card.get_parent().remove_child(card)
		tower_card_container.add_child(card)

		if _card_original_indices.has(tower_type):
			tower_card_container.move_child(
				card,
				int(_card_original_indices[tower_type])
			)

	card.global_position = global_start

	await get_tree().process_frame

	var target_global_position: Vector2 = card.global_position

	card.global_position = global_start

	var tween := create_tween()

	tween.tween_property(
		card,
		"global_position",
		target_global_position,
		0.18
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	card.set_meta("move_tween", tween)


func _kill_card_tween(card: Control) -> void:
	if card == null:
		return

	if not card.has_meta("move_tween"):
		return

	var tween = card.get_meta("move_tween")

	if tween != null and is_instance_valid(tween):
		tween.kill()

	card.remove_meta("move_tween")


func _on_build_location_pressed(slot_id: String) -> void:
	if _selected_tower_type.is_empty():
		return

	if not TowerDefinitions.has_tower_type(_selected_tower_type):
		return

	var cost: int = TowerDefinitions.get_cost(_selected_tower_type)

	if cost < 0:
		return

	if _current_gold < cost:
		return

	tower_purchase_requested.emit(
		slot_id,
		_selected_tower_type
	)


func _on_return_pressed() -> void:
	return_to_shop_requested.emit()
