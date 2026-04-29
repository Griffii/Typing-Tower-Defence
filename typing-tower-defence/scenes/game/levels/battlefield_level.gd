extends Node2D
class_name BattlefieldLevel

const DEFAULT_TOWER_SCENE: PackedScene = preload("res://scenes/game/towers/arrow_tower.tscn")
const ARROW_TOWER_SCENE: PackedScene = preload("res://scenes/game/towers/arrow_tower.tscn")
const LIGHTNING_TOWER_SCENE: PackedScene = preload("res://scenes/game/towers/lightning_tower.tscn")

@onready var castle: Node = %Castle
@onready var enemy_path: Path2D = %EnemyPath
@onready var enemy_spawn_marker: Marker2D = %EnemySpawnMarker
@onready var tower_container: Node = %TowerContainer

@onready var player_character: PlayerCharacter = %Player

var projectile_container: Node = null
var tower_nodes: Dictionary = {}
var tower_scene_map: Dictionary = {}

var allowed_tower_types: Array[String] = ["arrow"]


func get_player_character() -> PlayerCharacter:
	return player_character


func setup_level(shared_projectile_container: Node) -> void:
	projectile_container = shared_projectile_container


func reset_level_state() -> void:
	clear_all_towers()


func get_enemy_path() -> Path2D:
	return enemy_path


func get_enemy_spawn_marker() -> Marker2D:
	return enemy_spawn_marker


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


func get_allowed_tower_types_for_slot(_slot_id: String) -> Array[String]:
	return allowed_tower_types.duplicate()



func clear_all_towers() -> void:
	for slot_id in tower_nodes.keys():
		var tower: Node = tower_nodes.get(slot_id, null)
		if tower != null and is_instance_valid(tower):
			tower.queue_free()

	tower_nodes.clear()


func refresh_all_towers(combat_manager: Node) -> void:
	if combat_manager == null or tower_container == null or projectile_container == null:
		return

	var valid_slot_ids: Array[String] = []

	for slot_id_variant in combat_manager.tower_levels.keys():
		var slot_id: String = str(slot_id_variant)
		valid_slot_ids.append(slot_id)

		var level: int = combat_manager.get_tower_level(slot_id)

		if level <= 0:
			if tower_nodes.has(slot_id):
				var existing_tower: Node = tower_nodes.get(slot_id, null)
				if existing_tower != null and is_instance_valid(existing_tower):
					existing_tower.queue_free()
				tower_nodes.erase(slot_id)
			continue

		var tower: Node2D = tower_nodes.get(slot_id, null)

		if tower == null or not is_instance_valid(tower):
			var marker: Marker2D = tower_container.get_node_or_null(slot_id)
			if marker == null:
				continue

			var tower_scene: PackedScene = get_tower_scene_for_slot(slot_id, level, combat_manager)
			tower = tower_scene.instantiate() as Node2D
			if tower == null:
				continue

			tower_container.add_child(tower)
			tower.global_position = marker.global_position
			tower_nodes[slot_id] = tower

		if tower.has_method("setup_tower"):
			tower.setup_tower(slot_id, combat_manager, projectile_container)

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


func get_tower_scene_for_slot(slot_id: String, _level: int, combat_manager: Node = null) -> PackedScene:
	if combat_manager != null and combat_manager.has_method("get_tower_type"):
		var tower_type: String = combat_manager.get_tower_type(slot_id)

		match tower_type:
			"lightning":
				return LIGHTNING_TOWER_SCENE
			"arrow":
				return ARROW_TOWER_SCENE

	return tower_scene_map.get(slot_id, DEFAULT_TOWER_SCENE)
