## build_overlay.gd
# Script for the tower build overlay. Create tower scenes at markers as set by the level scene it is a child of.

extends CanvasLayer

signal return_to_shop_requested
signal tower_purchase_requested(slot_id: String, tower_type: String)

const TOWER_UPGRADE_NODE_SCENE: PackedScene = preload("res://scenes/game/towers/tower_upgrade_node.tscn")


@onready var return_button: Button = %ReturnToShopButton
@onready var slot_node_container: Node2D = %SlotNodeContainer

var _current_level: BattlefieldLevel = null
var _slot_markers: Dictionary = {}
var _slot_nodes: Dictionary = {}
var _current_build_state: Dictionary = {}
var _current_gold: int = 0


func _ready() -> void:
	visible = false
	set_process(false)

	if return_button != null and not return_button.pressed.is_connected(_on_return_pressed):
		return_button.pressed.connect(_on_return_pressed)


func set_level(level: BattlefieldLevel) -> void:
	print("[BuildOverlay] set_level() level=", level, " class=", level.get_class() if level != null else "null")

	_current_level = level
	_rebuild_slot_nodes()

	if visible and not _current_build_state.is_empty():
		refresh_build(_current_build_state)


func show_overlay(build_state: Dictionary) -> void:
	visible = true
	set_process(true)

	_current_build_state = build_state.duplicate(true)

	if _slot_nodes.is_empty():
		_rebuild_slot_nodes()

	_refresh_slot_node_positions()
	refresh_build(_current_build_state)


func hide_overlay() -> void:
	visible = false
	set_process(false)

	for slot_node in _slot_nodes.values():
		if slot_node != null and is_instance_valid(slot_node) and slot_node.has_method("set_info_card_visible"):
			slot_node.set_info_card_visible(false)


func refresh_build(build_state: Dictionary) -> void:
	_current_build_state = build_state.duplicate(true)
	_current_gold = int(build_state.get("gold", 0))

	var slots: Dictionary = build_state.get("slots", {})

	for slot_id in _slot_nodes.keys():
		var slot_node = _slot_nodes[slot_id]
		if slot_node == null or not is_instance_valid(slot_node):
			continue

		var slot_data: Variant = null
		if slots.has(slot_id):
			slot_data = slots[slot_id]

		if slot_node.has_method("refresh_slot_state"):
			slot_node.refresh_slot_state(slot_data, _current_gold)


func _process(_delta: float) -> void:
	if not visible:
		return

	_refresh_slot_node_positions()


func _rebuild_slot_nodes() -> void:
	_clear_slot_nodes()
	_slot_markers.clear()

	print("[BuildOverlay] _rebuild_slot_nodes() _current_level=", _current_level, " class=", _current_level.get_class() if _current_level != null else "null")

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

		var slot_node = TOWER_UPGRADE_NODE_SCENE.instantiate()
		slot_node_container.add_child(slot_node)

		var allowed_types: Array[String] = ["arrow"]
		if _current_level.has_method("get_allowed_tower_types_for_slot"):
			allowed_types = _current_level.get_allowed_tower_types_for_slot(slot_id)

		if slot_node.has_method("setup_slot"):
			slot_node.setup_slot(slot_id, allowed_types)

		if slot_node.has_signal("purchase_requested"):
			slot_node.purchase_requested.connect(_on_slot_purchase_requested)

		_slot_nodes[slot_id] = slot_node

	_refresh_slot_node_positions()


func _clear_slot_nodes() -> void:
	for slot_node in _slot_nodes.values():
		if slot_node != null and is_instance_valid(slot_node):
			slot_node.queue_free()

	_slot_nodes.clear()


func _refresh_slot_node_positions() -> void:
	for slot_id in _slot_markers.keys():
		var marker: Marker2D = _slot_markers[slot_id]
		var slot_node = _slot_nodes.get(slot_id, null)

		if marker == null or not is_instance_valid(marker):
			continue
		if slot_node == null or not is_instance_valid(slot_node):
			continue

		var screen_position: Vector2 = _world_to_screen(marker.global_position)

		if slot_node.has_method("set_screen_position"):
			slot_node.set_screen_position(screen_position)


func _world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position


func _on_slot_purchase_requested(slot_id: String, tower_type: String) -> void:
	tower_purchase_requested.emit(slot_id, tower_type)


func _on_return_pressed() -> void:
	return_to_shop_requested.emit()
