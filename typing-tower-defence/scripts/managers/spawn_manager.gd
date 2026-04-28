extends Node

const GRUNT_SCENE: PackedScene = preload("res://scenes/game/enemies/grunt_enemy.tscn")
const SCOUT_SCENE: PackedScene = preload("res://scenes/game/enemies/scout_enemy.tscn")
const TANK_SCENE: PackedScene = preload("res://scenes/game/enemies/tank_enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/game/enemies/boss_enemy.tscn")
const SLIME_SCENE: PackedScene = preload("res://scenes/game/enemies/slime_enemy.tscn")
const BOSS_SLIME_SCENE: PackedScene = preload("res://scenes/game/enemies/boss_slime_enemy.tscn")

const ENEMY_SCENES := {
	"grunt": GRUNT_SCENE,
	"scout": SCOUT_SCENE,
	"tank": TANK_SCENE,
	"boss": BOSS_SCENE,
	"slime": SLIME_SCENE,
	"boss_slime": BOSS_SLIME_SCENE,
}

@export var spawn_interval_seconds: float = 0.8
@export var minimum_spacing_pixels: float = 72.0

@onready var enemy_container: Node = %EnemyContainer
@onready var wave_manager: Node = %WaveManager
@onready var combat_manager: Node = %CombatManager

var spawn_marker: Marker2D = null
var enemy_path: Path2D = null
var active_enemies: Array[Node] = []
var spawn_queue: Array[Dictionary] = []
var spawn_timer: float = 0.0
var wave_in_progress: bool = false
var waiting_for_wave_enemy_data: bool = false
var current_wave_spawn_interval: float = 0.8
var current_wave_data: Dictionary = {}

var used_words_by_list: Dictionary = {}
var enemy_spawn_serial: int = 0


func _ready() -> void:
	randomize()

	if wave_manager != null:
		if wave_manager.has_signal("wave_started"):
			wave_manager.wave_started.connect(_on_wave_started)
		if wave_manager.has_signal("spawn_enemy_requested"):
			wave_manager.spawn_enemy_requested.connect(_on_spawn_enemy_requested)


func _process(delta: float) -> void:
	if not wave_in_progress:
		return

	_cleanup_invalid_enemies()

	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	if not spawn_queue.is_empty():
		if _can_spawn_next_enemy():
			_spawn_next_enemy_from_queue()
		return

	if waiting_for_wave_enemy_data:
		return

	if wave_manager != null and wave_manager.has_method("has_more_enemies_to_spawn") and wave_manager.has_more_enemies_to_spawn():
		waiting_for_wave_enemy_data = true
		if wave_manager.has_method("request_next_enemy_spawn"):
			wave_manager.request_next_enemy_spawn()
		return

	if wave_manager != null and wave_manager.has_method("notify_spawn_queue_exhausted"):
		wave_manager.notify_spawn_queue_exhausted()

	wave_in_progress = false


func reset_for_new_run() -> void:
	spawn_queue.clear()
	spawn_timer = 0.0
	wave_in_progress = false
	waiting_for_wave_enemy_data = false
	current_wave_spawn_interval = spawn_interval_seconds
	current_wave_data = {}
	used_words_by_list.clear()
	enemy_spawn_serial = 0

	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

	active_enemies.clear()

	if enemy_container != null:
		for child in enemy_container.get_children():
			if is_instance_valid(child):
				child.queue_free()


func set_enemy_spawn_marker(value: Marker2D) -> void:
	spawn_marker = value


func set_enemy_path(value: Path2D) -> void:
	enemy_path = value


func begin_wave(_wave_index: int) -> void:
	spawn_queue.clear()
	spawn_timer = 0.0
	wave_in_progress = true
	waiting_for_wave_enemy_data = false
	current_wave_spawn_interval = spawn_interval_seconds
	current_wave_data = {}
	used_words_by_list.clear()

	if wave_manager != null and wave_manager.has_method("get_current_wave_data"):
		current_wave_data = wave_manager.get_current_wave_data()
		if not current_wave_data.is_empty():
			current_wave_spawn_interval = float(current_wave_data.get("spawn_interval", spawn_interval_seconds))

	_request_next_wave_enemy()


func get_active_enemies() -> Array[Node]:
	_cleanup_invalid_enemies()
	return active_enemies.duplicate()


func get_front_most_enemy() -> Node:
	_cleanup_invalid_enemies()

	var front_most: Node2D = null

	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			continue
		if not (enemy is Node2D):
			continue
		if enemy.has_method("is_enemy_dead") and enemy.is_enemy_dead():
			continue

		var enemy_node: Node2D = enemy as Node2D

		if front_most == null:
			front_most = enemy_node
			continue

		if enemy_node.global_position.x < front_most.global_position.x:
			front_most = enemy_node

	return front_most


func create_enemy_preview_from_data(enemy_data: Dictionary) -> Node:
	var enemy_type: String = str(enemy_data.get("enemy_type", "grunt"))
	var enemy_scene: PackedScene = ENEMY_SCENES.get(enemy_type, GRUNT_SCENE)

	var enemy_instance: Node = enemy_scene.instantiate()
	var final_enemy_data: Dictionary = enemy_data.duplicate(true)

	var resolved_list_ids: Array[String] = _resolve_word_list_ids(final_enemy_data)
	final_enemy_data["resolved_word_list_ids"] = resolved_list_ids

	if not final_enemy_data.has("word") or str(final_enemy_data.get("word", "")).is_empty():
		final_enemy_data["word"] = get_word_for_enemy_data(final_enemy_data)

	enemy_instance.set_meta("spawn_enemy_data", final_enemy_data)

	if enemy_instance.has_method("setup_enemy"):
		final_enemy_data["path_points"] = []
		final_enemy_data["enemy_id"] = "preview_%s" % enemy_type
		enemy_instance.setup_enemy(final_enemy_data)

	return enemy_instance


func _on_wave_started(wave_index: int) -> void:
	begin_wave(wave_index)


func _on_spawn_enemy_requested(enemy_data: Dictionary) -> void:
	waiting_for_wave_enemy_data = false
	spawn_queue.append(enemy_data)

	if spawn_timer <= 0.0 and _can_spawn_next_enemy():
		_spawn_next_enemy_from_queue()


func _request_next_wave_enemy() -> void:
	if wave_manager == null:
		return

	if not wave_manager.has_method("has_more_enemies_to_spawn"):
		return

	if not wave_manager.has_more_enemies_to_spawn():
		return

	waiting_for_wave_enemy_data = true

	if wave_manager.has_method("request_next_enemy_spawn"):
		wave_manager.request_next_enemy_spawn()


func _can_spawn_next_enemy() -> bool:
	if active_enemies.is_empty():
		return true

	if not is_instance_valid(spawn_marker):
		return false

	var spawn_x: float = spawn_marker.global_position.x

	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			continue

		if enemy is Node2D:
			var enemy_node: Node2D = enemy as Node2D
			var distance_from_spawn: float = absf(enemy_node.global_position.x - spawn_x)

			if distance_from_spawn < minimum_spacing_pixels:
				return false

	return true


func _spawn_next_enemy_from_queue() -> void:
	if spawn_queue.is_empty():
		return
	if enemy_container == null or not is_instance_valid(enemy_container):
		return
	if spawn_marker == null or not is_instance_valid(spawn_marker):
		return
	if enemy_path == null or not is_instance_valid(enemy_path):
		return

	var enemy_data: Dictionary = spawn_queue.pop_front()
	var enemy_type: String = str(enemy_data.get("enemy_type", "grunt"))
	var enemy_scene: PackedScene = ENEMY_SCENES.get(enemy_type, GRUNT_SCENE)

	var enemy_instance: Node = enemy_scene.instantiate()
	enemy_container.add_child(enemy_instance)

	if enemy_instance is Node2D:
		var enemy_node: Node2D = enemy_instance as Node2D
		enemy_node.global_position = spawn_marker.global_position

	enemy_spawn_serial += 1

	var final_enemy_data: Dictionary = enemy_data.duplicate(true)
	final_enemy_data["enemy_id"] = "%s_%d" % [enemy_type, enemy_spawn_serial]
	final_enemy_data["path_points"] = enemy_path.curve.get_baked_points()

	var resolved_list_ids: Array[String] = _resolve_word_list_ids(final_enemy_data)
	final_enemy_data["resolved_word_list_ids"] = resolved_list_ids

	if not final_enemy_data.has("word") or str(final_enemy_data.get("word", "")).is_empty():
		final_enemy_data["word"] = get_word_for_enemy_data(final_enemy_data)

	enemy_instance.set_meta("spawn_enemy_data", final_enemy_data)

	if enemy_instance.has_method("setup_enemy"):
		enemy_instance.setup_enemy(final_enemy_data)

	if enemy_instance.has_signal("enemy_died"):
		enemy_instance.enemy_died.connect(_on_enemy_died)

	if enemy_instance.has_signal("enemy_reached_base"):
		enemy_instance.enemy_reached_base.connect(_on_enemy_reached_base)

	active_enemies.append(enemy_instance)
	spawn_timer = current_wave_spawn_interval

	if wave_manager != null and wave_manager.has_method("notify_enemy_spawned"):
		wave_manager.notify_enemy_spawned(enemy_instance)

	if spawn_queue.is_empty():
		_request_next_wave_enemy()


func _resolve_word_list_ids(enemy_data: Dictionary) -> Array[String]:
	var ids: Array[String] = []

	if enemy_data.has("word_list_ids"):
		var raw_ids: Array = enemy_data.get("word_list_ids", [])

		for raw_id in raw_ids:
			var id: String = str(raw_id).strip_edges()
			if not id.is_empty() and not ids.has(id):
				ids.append(id)

	if not ids.is_empty():
		return ids

	if enemy_data.has("word_list"):
		var single_id: String = str(enemy_data.get("word_list", "")).strip_edges()
		if not single_id.is_empty() and not ids.has(single_id):
			ids.append(single_id)

	if not ids.is_empty():
		return ids

	if current_wave_data.has("wave_word_list_ids"):
		var wave_ids: Array = current_wave_data.get("wave_word_list_ids", [])

		for raw_wave_id in wave_ids:
			var wave_id: String = str(raw_wave_id).strip_edges()
			if not wave_id.is_empty() and not ids.has(wave_id):
				ids.append(wave_id)

	if not ids.is_empty():
		return ids

	if current_wave_data.has("wave_word_list"):
		var old_wave_list: String = str(current_wave_data.get("wave_word_list", "")).strip_edges()
		if not old_wave_list.is_empty() and not ids.has(old_wave_list):
			ids.append(old_wave_list)

	return ids


func get_word_for_enemy_data(enemy_data: Dictionary) -> String:
	if enemy_data.has("word"):
		var explicit_word: String = str(enemy_data.get("word", ""))
		if not explicit_word.is_empty():
			return explicit_word

	var list_ids: Array[String] = []

	if enemy_data.has("resolved_word_list_ids"):
		var raw_resolved_ids: Array = enemy_data.get("resolved_word_list_ids", [])
		for raw_id in raw_resolved_ids:
			var id: String = str(raw_id).strip_edges()
			if not id.is_empty() and not list_ids.has(id):
				list_ids.append(id)

	if list_ids.is_empty():
		list_ids = _resolve_word_list_ids(enemy_data)

	if not list_ids.is_empty():
		return get_word_from_list_ids(list_ids)

	return "word"


func get_word_from_list_ids(list_ids: Array[String]) -> String:
	var pool: Array[String] = WordLists.get_combined_words(list_ids, true)

	if pool.is_empty():
		push_warning("SpawnManager: Word pool was empty for list ids: %s" % [list_ids])
		return "word"

	var pool_key: String = "|".join(list_ids)
	return _get_random_word_from_pool(pool, pool_key)


func _get_random_word_from_pool(all_words: Array[String], list_name: String) -> String:
	if all_words.is_empty():
		return "word"

	if not used_words_by_list.has(list_name):
		used_words_by_list[list_name] = [] as Array[String]

	var used_words: Array[String] = used_words_by_list[list_name] as Array[String]
	var available_words: Array[String] = []

	for word in all_words:
		if not used_words.has(word):
			available_words.append(word)

	if available_words.is_empty():
		used_words.clear()
		available_words = all_words.duplicate()

	var chosen_word: String = available_words[randi() % available_words.size()]
	used_words.append(chosen_word)
	used_words_by_list[list_name] = used_words

	return chosen_word


func get_replacement_word_for_enemy(enemy: Node) -> String:
	if enemy == null or not is_instance_valid(enemy):
		return "word"

	var enemy_data: Dictionary = {}

	if enemy.has_method("get_enemy_data"):
		enemy_data = enemy.get_enemy_data()
	elif enemy.has_meta("spawn_enemy_data"):
		enemy_data = enemy.get_meta("spawn_enemy_data")

	if enemy_data.is_empty():
		return "word"

	var list_ids: Array[String] = []

	if enemy_data.has("resolved_word_list_ids"):
		var raw_ids: Array = enemy_data.get("resolved_word_list_ids", [])
		for raw_id in raw_ids:
			var id: String = str(raw_id).strip_edges()
			if not id.is_empty() and not list_ids.has(id):
				list_ids.append(id)

	if list_ids.is_empty():
		list_ids = _resolve_word_list_ids(enemy_data)

	if not list_ids.is_empty():
		var new_word: String = get_word_from_list_ids(list_ids)

		enemy_data["word"] = new_word
		enemy_data["resolved_word_list_ids"] = list_ids

		if enemy.has_meta("spawn_enemy_data"):
			enemy.set_meta("spawn_enemy_data", enemy_data)

		if enemy.has_method("set_enemy_data"):
			enemy.set_enemy_data(enemy_data)

		return new_word

	return "word"


func _on_enemy_reached_base(enemy: Node) -> void:
	if combat_manager != null and combat_manager.has_method("register_enemy_at_base"):
		combat_manager.register_enemy_at_base(enemy)


func _on_enemy_died(enemy: Node) -> void:
	var index: int = active_enemies.find(enemy)
	if index != -1:
		active_enemies.remove_at(index)

	if combat_manager != null and combat_manager.has_method("unregister_enemy_at_base"):
		combat_manager.unregister_enemy_at_base(enemy)

	if wave_manager != null and wave_manager.has_method("notify_enemy_died"):
		wave_manager.notify_enemy_died(enemy)


func _cleanup_invalid_enemies() -> void:
	for i in range(active_enemies.size() - 1, -1, -1):
		if not is_instance_valid(active_enemies[i]):
			active_enemies.remove_at(i)


func debug_force_spawn_all_remaining_enemies() -> Array[Node]:
	var spawned_enemies: Array[Node] = []

	if not wave_in_progress:
		_cleanup_invalid_enemies()
		return active_enemies.duplicate()

	waiting_for_wave_enemy_data = false
	spawn_timer = 0.0

	while true:
		while not spawn_queue.is_empty():
			var before_count: int = active_enemies.size()
			_spawn_next_enemy_from_queue()

			if active_enemies.size() > before_count:
				var newest_enemy: Node = active_enemies[active_enemies.size() - 1]
				if is_instance_valid(newest_enemy):
					spawned_enemies.append(newest_enemy)

		if wave_manager == null:
			break
		if not wave_manager.has_method("has_more_enemies_to_spawn"):
			break
		if not wave_manager.has_more_enemies_to_spawn():
			break

		waiting_for_wave_enemy_data = true
		if wave_manager.has_method("request_next_enemy_spawn"):
			wave_manager.request_next_enemy_spawn()
		waiting_for_wave_enemy_data = false

	spawn_queue.clear()
	waiting_for_wave_enemy_data = false
	spawn_timer = 0.0

	_cleanup_invalid_enemies()
	return active_enemies.duplicate()
