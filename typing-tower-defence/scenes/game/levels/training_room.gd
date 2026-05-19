# res://scripts/game/levels/training_room_level.gd
class_name TrainingRoomLevel
extends Node2D

signal tower_finished_firing(slot_id: String)
signal training_dummy_died(dummy: Node, marker_id: String)

const DEFAULT_TOWER_SCENE: PackedScene = preload("uid://ciwqq06h6kavx")
const ARROW_TOWER_SCENE: PackedScene = preload("uid://ciwqq06h6kavx")


@export var training_dummy_scene: PackedScene
@export var enemy_scale: Vector2 = Vector2.ONE
@export var allowed_tower_types: Array[String] = ["basic_magic_turret"] 

@onready var dummy_marker_1: Marker2D = %DummyMarker1
@onready var dummy_marker_2: Marker2D = %DummyMarker2
@onready var enemy_container: Node2D = %EnemyContainer
@onready var tower_container: Node = %TowerContainer
@onready var player_character: PlayerCharacter = %Player

var projectile_container: Node = null
var tower_nodes: Dictionary = {}
var tower_scene_map: Dictionary = {}

var dummy_markers: Dictionary = {}
var active_dummies: Dictionary = {}
var respawn_enabled: bool = false
var current_word_pool: Array[String] = []


func _ready() -> void:
	dummy_markers = {
		"DummyMarker1": dummy_marker_1,
		"DummyMarker2": dummy_marker_2,
	}


# ---------------------------
# LEVEL INTERFACE
# ---------------------------

func setup_level(shared_projectile_container: Node) -> void:
	projectile_container = shared_projectile_container


func reset_level_state() -> void:
	respawn_enabled = false
	clear_dummies()
	clear_all_towers()


func get_player_character() -> PlayerCharacter:
	return player_character


func get_enemy_container() -> Node2D:
	return enemy_container


func get_enemy_scale() -> Vector2:
	return enemy_scale


func get_tower_container() -> Node:
	return tower_container


func get_tower_slot_ids() -> Array[String]:
	var result: Array[String] = []

	if tower_container == null:
		return result

	for child in tower_container.get_children():
		if child is Marker2D:
			result.append(child.name)

	return result


func get_tower_slots() -> Array[Marker2D]:
	var result: Array[Marker2D] = []

	if tower_container == null:
		return result

	for child in tower_container.get_children():
		if child is Marker2D:
			result.append(child)

	return result


func get_allowed_tower_types() -> Array[String]:
	return allowed_tower_types.duplicate()


# ---------------------------
# WORD SYSTEM
# ---------------------------

func set_word_pool(words: Array[String]) -> void:
	current_word_pool = words.duplicate()

func get_replacement_word_for_enemy(_enemy: Node) -> String:
	return _get_random_word()

func _get_random_word() -> String:
	if current_word_pool.is_empty():
		return "magic"

	return current_word_pool.pick_random()


# ---------------------------
# DUMMY CONTROL
# ---------------------------

func set_respawn_enabled(enabled: bool) -> void:
	respawn_enabled = enabled


func spawn_one_dummy() -> void:
	clear_dummies()
	spawn_dummy("DummyMarker1")


func spawn_two_dummies() -> void:
	clear_dummies()
	spawn_dummy("DummyMarker1")
	spawn_dummy("DummyMarker2")


func spawn_dummy(marker_id: String) -> TrainingDummy:
	if training_dummy_scene == null:
		push_error("TrainingRoomLevel: training_dummy_scene is not assigned.")
		return null

	if not dummy_markers.has(marker_id):
		push_error("TrainingRoomLevel: Missing marker id: " + marker_id)
		return null

	var marker: Marker2D = dummy_markers[marker_id]

	if marker == null:
		return null

	var dummy: TrainingDummy = training_dummy_scene.instantiate() as TrainingDummy

	if dummy == null:
		push_error("TrainingRoomLevel: training_dummy_scene does not use TrainingDummy.")
		return null

	var parent_node: Node = enemy_container
	if parent_node == null:
		parent_node = self

	parent_node.add_child(dummy)
	dummy.global_position = marker.global_position
	dummy.scale = enemy_scale

	dummy.setup_enemy({
		"enemy_type": "training_dummy",
		"enemy_id": "training_dummy_%s_%d" % [marker_id, Time.get_ticks_msec()],
		"marker_id": marker_id,
		"word": _get_random_word(),
		"max_hp": 30,
		"reward_score": 15,
		"reward_gold": 15,
	})

	if not dummy.enemy_died.is_connected(_on_dummy_died):
		dummy.enemy_died.connect(_on_dummy_died)

	active_dummies[marker_id] = dummy

	return dummy


func clear_dummies() -> void:
	for marker_id: String in active_dummies.keys():
		var dummy: Node = active_dummies[marker_id]

		if dummy != null and is_instance_valid(dummy):
			dummy.queue_free()

	active_dummies.clear()


func reset_dummies_with_word_pool(words: Array[String], spawn_count: int = 2) -> void:
	set_word_pool(words)
	clear_dummies()

	if spawn_count <= 0:
		return

	spawn_dummy("DummyMarker1")

	if spawn_count >= 2:
		spawn_dummy("DummyMarker2")


func _on_dummy_died(dummy: Node) -> void:
	if dummy == null:
		return

	var marker_id: String = ""

	if dummy is TrainingDummy:
		marker_id = dummy.marker_id

	if marker_id.is_empty():
		return

	active_dummies.erase(marker_id)

	training_dummy_died.emit(dummy, marker_id)

	if respawn_enabled:
		_respawn_after_delay(marker_id)


func _respawn_after_delay(marker_id: String) -> void:
	await get_tree().create_timer(3.0).timeout

	if not respawn_enabled:
		return

	if active_dummies.has(marker_id):
		return

	spawn_dummy(marker_id)


# ---------------------------
# TOWER CONTROL
# ---------------------------

func clear_all_towers() -> void:
	for slot_id in tower_nodes.keys():
		var tower: Node = tower_nodes.get(slot_id, null)

		if tower != null and is_instance_valid(tower):
			tower.queue_free()

	tower_nodes.clear()


func refresh_all_towers(combat_manager: Node) -> void:
	if combat_manager == null:
		return

	if tower_container == null:
		return

	if projectile_container == null:
		push_warning("TrainingRoomLevel: projectile_container is null. Call setup_level(projectile_container) before refreshing towers.")
		return

	var valid_slot_ids: Array[String] = []

	if not ("tower_levels" in combat_manager):
		return

	for slot_id_variant in combat_manager.tower_levels.keys():
		var slot_id: String = str(slot_id_variant)
		valid_slot_ids.append(slot_id)

		var level: int = 0

		if combat_manager.has_method("get_tower_level"):
			level = int(combat_manager.get_tower_level(slot_id))
		else:
			level = int(combat_manager.tower_levels.get(slot_id, 0))

		if level <= 0:
			if tower_nodes.has(slot_id):
				var old_tower: Node = tower_nodes.get(slot_id, null)

				if old_tower != null and is_instance_valid(old_tower):
					old_tower.queue_free()

				tower_nodes.erase(slot_id)

			continue

		var tower: Node2D = tower_nodes.get(slot_id, null)

		if tower == null or not is_instance_valid(tower):
			var marker: Marker2D = tower_container.get_node_or_null(slot_id)

			if marker == null:
				continue

			var tower_scene: PackedScene = get_tower_scene_for_slot(slot_id, level, combat_manager)

			if tower_scene == null:
				continue

			tower = tower_scene.instantiate() as Node2D

			if tower == null:
				continue

			tower_container.add_child(tower)
			tower.global_position = marker.global_position
			tower_nodes[slot_id] = tower

		if tower.has_method("setup_tower"):
			tower.setup_tower(slot_id, combat_manager, projectile_container)
			
			if tower.has_method("set_override_range"):
				tower.set_override_range(999.0)
			
			if tower.has_signal("tower_finished_firing"):
				if not tower.tower_finished_firing.is_connected(_on_tower_finished_firing):
					tower.tower_finished_firing.connect(_on_tower_finished_firing)

	var stale_slots: Array[String] = []

	for existing_slot_id_variant in tower_nodes.keys():
		var existing_slot_id: String = str(existing_slot_id_variant)

		if not valid_slot_ids.has(existing_slot_id):
			stale_slots.append(existing_slot_id)

	for stale_slot_id in stale_slots:
		var stale_tower: Node = tower_nodes.get(stale_slot_id, null)

		if stale_tower != null and is_instance_valid(stale_tower):
			stale_tower.queue_free()

		tower_nodes.erase(stale_slot_id)



func get_tower_scene_for_slot(_slot_id: String, _level: int, _combat_manager: Node = null) -> PackedScene:
	return DEFAULT_TOWER_SCENE


func _on_tower_finished_firing(slot_id: String) -> void:
	tower_finished_firing.emit(slot_id)
