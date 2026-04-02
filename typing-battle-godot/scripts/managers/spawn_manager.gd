extends Node

const GRUNT_SCENE: PackedScene = preload("res://scenes/game/enemies/grunt_enemy.tscn")
const SCOUT_SCENE: PackedScene = preload("res://scenes/game/enemies/scout_enemy.tscn")
const TANK_SCENE: PackedScene = preload("res://scenes/game/enemies/tank_enemy.tscn")

const ENEMY_SCENES := {
	"grunt": GRUNT_SCENE,
	"scout": SCOUT_SCENE,
	"tank": TANK_SCENE,
}

const GruntWords = preload("res://data/words/grunt_words.gd")

@export var spawn_interval_seconds: float = 0.8
@export var minimum_spacing_pixels: float = 72.0

@onready var enemy_container: Node = %EnemyContainer
@onready var spawn_marker: Marker2D = %EnemySpawnMarker
@onready var base_marker: Marker2D = %BaseMarker
@onready var wave_manager: Node = %WaveManager
@onready var combat_manager: Node = %CombatManager

var active_enemies: Array[Node] = []
var spawn_queue: Array[Dictionary] = []
var spawn_timer: float = 0.0
var wave_in_progress: bool = false
var waiting_for_wave_enemy_data: bool = false
var current_wave_spawn_interval: float = 0.8

var used_grunt_words: Array[String] = []
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
	used_grunt_words.clear()
	enemy_spawn_serial = 0

	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

	active_enemies.clear()

	if enemy_container != null:
		for child in enemy_container.get_children():
			if is_instance_valid(child):
				child.queue_free()


func begin_wave(_wave_index: int) -> void:
	spawn_queue.clear()
	spawn_timer = 0.0
	wave_in_progress = true
	waiting_for_wave_enemy_data = false
	used_grunt_words.clear()

	current_wave_spawn_interval = spawn_interval_seconds

	if wave_manager != null and wave_manager.has_method("get_current_wave_data"):
		var wave_data: Dictionary = wave_manager.get_current_wave_data()
		if not wave_data.is_empty():
			current_wave_spawn_interval = float(wave_data.get("spawn_interval", spawn_interval_seconds))

	_request_next_wave_enemy()


func get_active_enemies() -> Array[Node]:
	_cleanup_invalid_enemies()
	return active_enemies.duplicate()


func get_word_for_enemy_type(enemy_type: String) -> String:
	return _get_word_for_enemy_type(enemy_type)


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
	final_enemy_data["base_target"] = base_marker

	if not final_enemy_data.has("word") or str(final_enemy_data.get("word", "")).is_empty():
		final_enemy_data["word"] = _get_word_for_enemy_type(enemy_type)

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


func _get_word_for_enemy_type(enemy_type: String) -> String:
	match enemy_type:
		"grunt":
			return _get_random_grunt_word()
		"scout":
			return _get_random_grunt_word()
		"tank":
			return _get_random_grunt_word()
		_:
			return _get_random_grunt_word()


func _get_random_grunt_word() -> String:
	var all_words: Array[String] = GruntWords.WORDS

	if all_words.is_empty():
		return "word"

	var available_words: Array[String] = []

	for word in all_words:
		if not used_grunt_words.has(word):
			available_words.append(word)

	if available_words.is_empty():
		used_grunt_words.clear()
		available_words = all_words.duplicate()

	var chosen_word: String = available_words[randi() % available_words.size()]
	used_grunt_words.append(chosen_word)
	return chosen_word


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
