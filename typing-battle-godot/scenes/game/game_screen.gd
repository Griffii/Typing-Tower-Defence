# game_screen.gd
extends Control

signal back_to_menu_requested

enum RunState {
	PRE_WAVE,
	COUNTDOWN,
	WAVE_ACTIVE,
	SHOP,
	BUILD,
	VICTORY,
	DEFEAT
}

const DEFAULT_WAVE_SET = preload("res://data/waves/wave_set_01.gd")
const ARROW_PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/projectiles/arrow_projectile.tscn")
const SHOP_DEFINITIONS = preload("res://data/shop/shop_definitions.gd")
const TOWER_SCENE: PackedScene = preload("res://scenes/game/tower.tscn")

@onready var game_hud: CanvasLayer = %GameHud
@onready var countdown_overlay: CanvasLayer = %CountdownOverlay
@onready var game_over_overlay: CanvasLayer = %GameOverOverlay
@onready var game_menu_overlay: CanvasLayer = %GameMenuOverlay
@onready var shop_overlay: CanvasLayer = %ShopOverlay
@onready var build_overlay: CanvasLayer = %BuildOverlay

@onready var arrow_spawn_marker: Marker2D = %ArrowSpawnMarker
@onready var projectile_container: Node = %ProjectileContainer
@onready var tower_container: Node = %TowerContainer

@onready var enemy_path: Path2D = %EnemyPath

@onready var wave_manager: Node = %WaveManager
@onready var spawn_manager: Node = %SpawnManager
@onready var typing_manager: Node = %TypingManager
@onready var combat_manager: Node = %CombatManager

var run_state: RunState = RunState.PRE_WAVE
var current_wave_index: int = 0
var total_waves: int = 0
var run_active: bool = false
var wave_set: Array = []
var is_game_menu_open: bool = false
var is_shop_open: bool = false
var is_build_open: bool = false
var tower_nodes := {}


func _ready() -> void:
	_connect_signals()
	_load_default_wave_set()
	_reset_run()


func setup_run(run_config: Dictionary) -> void:
	wave_set = []

	if run_config.has("wave_definitions"):
		var defs: Variant = run_config.get("wave_definitions", [])
		if typeof(defs) == TYPE_ARRAY:
			wave_set = defs as Array

	if wave_set.is_empty():
		_load_default_wave_set()

	if combat_manager != null and combat_manager.has_method("setup_run"):
		combat_manager.setup_run(run_config)

	_reset_run()


func _connect_signals() -> void:
	if game_hud != null:
		if game_hud.has_signal("start_wave_pressed"):
			game_hud.start_wave_pressed.connect(_on_start_wave_pressed)
		if game_hud.has_signal("game_menu_pressed"):
			game_hud.game_menu_pressed.connect(_on_game_menu_pressed)
		if game_hud.has_signal("text_changed"):
			game_hud.text_changed.connect(_on_hud_text_changed)
		if game_hud.has_signal("text_submitted"):
			game_hud.text_submitted.connect(_on_hud_text_submitted)

	if countdown_overlay != null and countdown_overlay.has_signal("countdown_finished"):
		countdown_overlay.countdown_finished.connect(_on_countdown_finished)

	if game_over_overlay != null:
		if game_over_overlay.has_signal("back_to_menu_requested"):
			game_over_overlay.back_to_menu_requested.connect(_on_back_to_menu_pressed)
		if game_over_overlay.has_signal("play_again_requested"):
			game_over_overlay.play_again_requested.connect(_on_play_again_requested)

	if game_menu_overlay != null:
		if game_menu_overlay.has_signal("back_to_menu_requested"):
			game_menu_overlay.back_to_menu_requested.connect(_on_back_to_menu_pressed)
		if game_menu_overlay.has_signal("resume_requested"):
			game_menu_overlay.resume_requested.connect(_on_game_menu_resume_requested)

	if shop_overlay != null:
		if shop_overlay.has_signal("purchase_requested"):
			shop_overlay.purchase_requested.connect(_on_shop_purchase_requested)
		if shop_overlay.has_signal("build_mode_requested"):
			shop_overlay.build_mode_requested.connect(_on_shop_build_mode_requested)
		if shop_overlay.has_signal("next_wave_requested"):
			shop_overlay.next_wave_requested.connect(_on_shop_next_wave_requested)

	if build_overlay != null:
		if build_overlay.has_signal("return_to_shop_requested"):
			build_overlay.return_to_shop_requested.connect(_on_build_return_to_shop_requested)
		if build_overlay.has_signal("tower_purchase_requested"):
			build_overlay.tower_purchase_requested.connect(_on_build_tower_purchase_requested)


	if wave_manager != null:
		if wave_manager.has_signal("wave_started"):
			wave_manager.wave_started.connect(_on_wave_started)
		if wave_manager.has_signal("wave_cleared"):
			wave_manager.wave_cleared.connect(_on_wave_cleared)
		if wave_manager.has_signal("all_waves_cleared"):
			wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)

	if combat_manager != null:
		if combat_manager.has_signal("base_destroyed"):
			combat_manager.base_destroyed.connect(_on_base_destroyed)
		if combat_manager.has_signal("hud_stats_changed"):
			combat_manager.hud_stats_changed.connect(_on_hud_stats_changed)
		if combat_manager.has_signal("arrow_meter_changed"):
			combat_manager.arrow_meter_changed.connect(_on_arrow_meter_changed)
		if combat_manager.has_signal("arrow_meter_filled"):
			if not combat_manager.arrow_meter_filled.is_connected(_on_arrow_meter_filled):
				combat_manager.arrow_meter_filled.connect(_on_arrow_meter_filled)
		if combat_manager.has_signal("tower_state_changed"):
			combat_manager.tower_state_changed.connect(_on_tower_state_changed)

	if typing_manager != null:
		if typing_manager.has_signal("word_completed"):
			typing_manager.word_completed.connect(_on_word_completed)
		if typing_manager.has_signal("input_cleared"):
			typing_manager.input_cleared.connect(_on_typing_input_cleared)


func _load_default_wave_set() -> void:
	if DEFAULT_WAVE_SET == null:
		wave_set = []
		total_waves = 0
		push_warning("GameScreen: DEFAULT_WAVE_SET is null.")
		return

	wave_set = DEFAULT_WAVE_SET.WAVES
	total_waves = wave_set.size()


func _reset_run() -> void:
	run_active = true
	current_wave_index = 0
	total_waves = wave_set.size()
	is_game_menu_open = false
	is_shop_open = false
	is_build_open = false

	get_tree().paused = false

	if wave_manager != null and wave_manager.has_method("reset_for_new_run"):
		wave_manager.reset_for_new_run()

	if wave_manager != null and wave_manager.has_method("set_wave_definitions"):
		wave_manager.set_wave_definitions(wave_set)

	if spawn_manager != null and spawn_manager.has_method("reset_for_new_run"):
		spawn_manager.reset_for_new_run()

	if typing_manager != null and typing_manager.has_method("reset_for_new_run"):
		typing_manager.reset_for_new_run()

	if combat_manager != null and combat_manager.has_method("reset_for_new_run"):
		combat_manager.reset_for_new_run()

	if game_over_overlay != null and game_over_overlay.has_method("hide_overlay"):
		game_over_overlay.hide_overlay()

	if game_menu_overlay != null and game_menu_overlay.has_method("hide_overlay"):
		game_menu_overlay.hide_overlay()
	
	if shop_overlay != null and shop_overlay.has_method("hide_overlay"):
		shop_overlay.hide_overlay()

	if build_overlay != null and build_overlay.has_method("hide_overlay"):
		build_overlay.hide_overlay()

	_refresh_all_towers()
	_set_run_state(RunState.PRE_WAVE)
	_refresh_wave_ui()



func _set_run_state(new_state: RunState) -> void:
	run_state = new_state

	match run_state:
		RunState.PRE_WAVE:
			_disable_typing()
			_show_start_wave_button("Start Wave")
			_set_status_text("Press Start Wave when ready.")
			_hide_shop()
			_hide_build()

		RunState.COUNTDOWN:
			_disable_typing()
			_hide_start_wave_button()
			_set_status_text("Get ready...")
			_hide_shop()
			_hide_build()

		RunState.WAVE_ACTIVE:
			_enable_typing()
			_hide_start_wave_button()
			_set_status_text("Wave %d in progress." % (current_wave_index + 1))
			_hide_shop()
			_hide_build()

		RunState.SHOP:
			_disable_typing()
			_hide_start_wave_button()
			_set_status_text("Shopping Time.")
			_show_shop()
			_hide_build()

		RunState.BUILD:
			_disable_typing()
			_hide_start_wave_button()
			_set_status_text("Build Mode.")
			_hide_shop()
			_show_build()

		RunState.VICTORY:
			_disable_typing()
			_hide_start_wave_button()
			_set_status_text("Victory.")
			_hide_shop()
			_hide_build()
			_show_game_over(true)

		RunState.DEFEAT:
			_disable_typing()
			_hide_start_wave_button()
			_set_status_text("Defeat.")
			_hide_shop()
			_hide_build()
			_show_game_over(false)



func _refresh_wave_ui() -> void:
	if game_hud != null and game_hud.has_method("set_wave_text"):
		game_hud.set_wave_text(current_wave_index + 1, max(1, total_waves))


func _on_start_wave_pressed() -> void:
	if not run_active:
		return

	if is_game_menu_open or is_shop_open:
		return

	if run_state != RunState.PRE_WAVE and run_state != RunState.SHOP:
		return

	_set_run_state(RunState.COUNTDOWN)

	if countdown_overlay != null and countdown_overlay.has_method("play_countdown"):
		countdown_overlay.play_countdown(3, 1.0)


func _on_countdown_finished() -> void:
	if not run_active:
		return

	if current_wave_index >= wave_set.size():
		_on_all_waves_cleared()
		return

	_set_run_state(RunState.WAVE_ACTIVE)

	if wave_manager != null and wave_manager.has_method("start_wave"):
		wave_manager.start_wave(current_wave_index)


func _on_wave_started(wave_index: int) -> void:
	current_wave_index = wave_index
	_refresh_wave_ui()

	if typing_manager != null and typing_manager.has_method("begin_wave"):
		typing_manager.begin_wave(wave_index)


func _on_wave_cleared(wave_index: int) -> void:
	if run_state == RunState.DEFEAT or run_state == RunState.VICTORY:
		return

	if combat_manager != null and combat_manager.has_method("reset_arrow_meter"):
		combat_manager.reset_arrow_meter()

	current_wave_index = wave_index + 1
	_refresh_wave_ui()

	if current_wave_index >= total_waves:
		_on_all_waves_cleared()
		return

	_set_run_state(RunState.SHOP)


func _on_all_waves_cleared() -> void:
	if run_state == RunState.DEFEAT or run_state == RunState.VICTORY:
		return

	run_active = false
	_set_run_state(RunState.VICTORY)


func _on_base_destroyed() -> void:
	if run_state == RunState.DEFEAT or run_state == RunState.VICTORY:
		return

	run_active = false
	_set_run_state(RunState.DEFEAT)


func _on_hud_text_changed(text: String) -> void:
	if run_state != RunState.WAVE_ACTIVE:
		return
	
	if is_game_menu_open or is_shop_open:
		return
	
	if typing_manager != null and typing_manager.has_method("process_input_text"):
		typing_manager.process_input_text(text)


func _on_hud_text_submitted(_text: String) -> void:
	if run_state != RunState.WAVE_ACTIVE:
		return

	if is_game_menu_open:
		return

	if typing_manager != null and typing_manager.has_method("cancel_current_target"):
		typing_manager.cancel_current_target()


func _on_word_completed(target_enemy: Node) -> void:
	if run_state != RunState.WAVE_ACTIVE:
		return

	if combat_manager != null and combat_manager.has_method("resolve_completed_word"):
		combat_manager.resolve_completed_word(target_enemy)


func _on_typing_input_cleared() -> void:
	if game_hud != null and game_hud.has_method("clear_input"):
		game_hud.clear_input()


func _on_hud_stats_changed(stats: Dictionary) -> void:
	if game_hud == null:
		return

	if game_hud.has_method("set_gold"):
		game_hud.set_gold(int(stats.get("gold", 0)))

	if game_hud.has_method("set_base_hp"):
		game_hud.set_base_hp(int(stats.get("base_hp", 0)), int(stats.get("base_hp_max", 0)))

	if is_shop_open:
		_refresh_shop()

	if is_build_open:
		_refresh_build()



func _on_arrow_meter_changed(current_value: float, max_value: float) -> void:
	if game_hud != null and game_hud.has_method("set_arrow_meter"):
		game_hud.set_arrow_meter(current_value, max_value)


func _on_arrow_meter_filled() -> void:
	if spawn_manager == null or not spawn_manager.has_method("get_front_most_enemy"):
		return

	var target_enemy: Node = spawn_manager.get_front_most_enemy()
	if target_enemy == null or not is_instance_valid(target_enemy):
		return

	_spawn_arrow_projectile(target_enemy)


func _spawn_arrow_projectile(target_enemy: Node) -> void:
	if not is_instance_valid(arrow_spawn_marker):
		return
	if not is_instance_valid(projectile_container):
		return

	var arrow: Node = ARROW_PROJECTILE_SCENE.instantiate()
	projectile_container.add_child(arrow)

	if arrow.has_signal("impact_reached"):
		arrow.impact_reached.connect(_on_arrow_projectile_impact)

	if arrow.has_method("fire"):
		arrow.fire(arrow_spawn_marker.global_position, target_enemy, 0.35, 48.0)


func _on_arrow_projectile_impact(target_enemy: Node) -> void:
	if combat_manager != null and combat_manager.has_method("fire_castle_arrow_at_target"):
		combat_manager.fire_castle_arrow_at_target(target_enemy)

func _show_game_over(did_win: bool) -> void:
	get_tree().paused = true

	if game_over_overlay == null:
		return

	if game_over_overlay.has_method("show_results"):
		game_over_overlay.show_results({
			"did_win": did_win,
			"wave_reached": current_wave_index + 1,
			"total_waves": total_waves
		})


func _show_start_wave_button(button_text: String) -> void:
	if game_hud != null and game_hud.has_method("show_start_wave_button"):
		game_hud.show_start_wave_button(button_text)


func _hide_start_wave_button() -> void:
	if game_hud != null and game_hud.has_method("hide_start_wave_button"):
		game_hud.hide_start_wave_button()


func _set_status_text(text: String) -> void:
	if game_hud != null and game_hud.has_method("set_status_text"):
		game_hud.set_status_text(text)


func _enable_typing() -> void:
	if typing_manager != null and typing_manager.has_method("set_active"):
		typing_manager.set_active(true)

	if game_hud != null and game_hud.has_method("set_input_enabled"):
		game_hud.set_input_enabled(true)

	if game_hud != null and game_hud.has_method("clear_input"):
		game_hud.clear_input()


func _disable_typing() -> void:
	if typing_manager != null and typing_manager.has_method("set_active"):
		typing_manager.set_active(false)

	if typing_manager != null and typing_manager.has_method("clear_input_state"):
		typing_manager.clear_input_state()

	if game_hud != null and game_hud.has_method("set_input_enabled"):
		game_hud.set_input_enabled(false)

	if game_hud != null and game_hud.has_method("clear_input"):
		game_hud.clear_input()


func _on_game_menu_pressed() -> void:
	if run_state == RunState.VICTORY or run_state == RunState.DEFEAT:
		return

	is_game_menu_open = true
	get_tree().paused = true
	_disable_typing()

	if game_menu_overlay != null and game_menu_overlay.has_method("show_overlay"):
		game_menu_overlay.show_overlay()


func _on_game_menu_resume_requested() -> void:
	is_game_menu_open = false
	get_tree().paused = false

	if game_menu_overlay != null and game_menu_overlay.has_method("hide_overlay"):
		game_menu_overlay.hide_overlay()

	if run_state == RunState.WAVE_ACTIVE:
		_enable_typing()


func _on_play_again_requested() -> void:
	get_tree().paused = false
	_reset_run()


func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	back_to_menu_requested.emit()


############################################################
## Shop Menu Helpers ######################################
###########################################################

func _show_shop() -> void:
	is_shop_open = true
	
	if shop_overlay == null or combat_manager == null:
		return

	if shop_overlay.has_method("show_overlay") and combat_manager.has_method("get_shop_state"):
		shop_overlay.show_overlay(
			combat_manager.get_shop_state(),
			SHOP_DEFINITIONS.UPGRADES
		)


func _hide_shop() -> void:
	is_shop_open = false
	
	if shop_overlay != null and shop_overlay.has_method("hide_overlay"):
		shop_overlay.hide_overlay()


func _refresh_shop() -> void:
	if not is_shop_open:
		return
	if shop_overlay == null or combat_manager == null:
		return

	if shop_overlay.has_method("refresh_shop") and combat_manager.has_method("get_shop_state"):
		shop_overlay.refresh_shop(
			combat_manager.get_shop_state(),
			SHOP_DEFINITIONS.UPGRADES
		)


func _on_shop_purchase_requested(upgrade_id: String) -> void:
	if run_state != RunState.SHOP:
		return
	if combat_manager == null or not combat_manager.has_method("apply_upgrade_purchase"):
		return

	var purchased: bool = combat_manager.apply_upgrade_purchase(upgrade_id)
	if purchased:
		_refresh_shop()


func _on_shop_build_mode_requested() -> void:
	if run_state != RunState.SHOP:
		return
	
	_set_run_state(RunState.BUILD)


func _on_shop_next_wave_requested() -> void:
	print("Game Screen: _on_shop_next_wave_requested called")
	if not run_active:
		print("Game Screen: _on_shop_next_wave_requested returned - Not Run Active")
		return
	
	if run_state != RunState.SHOP:
		print("Game Screen: _on_shop_next_wave_requested returned - Not Shop State")
		return
	
	print("Game Screen: _on_shop_next_wave_requested not returned")
	
	_set_run_state(RunState.COUNTDOWN)
	print("Game Screen: State changed to: COUNTDOWN")
	if countdown_overlay != null and countdown_overlay.has_method("play_countdown"):
		countdown_overlay.play_countdown(3, 1.0)


####################################################
### Build Menu Helpers ############################
####################################################

func _show_build() -> void:
	is_build_open = true

	if build_overlay == null or combat_manager == null:
		return

	if build_overlay.has_method("show_overlay") and combat_manager.has_method("get_build_state"):
		build_overlay.show_overlay(combat_manager.get_build_state())


func _hide_build() -> void:
	is_build_open = false

	if build_overlay != null and build_overlay.has_method("hide_overlay"):
		build_overlay.hide_overlay()


func _refresh_build() -> void:
	if not is_build_open:
		return
	if build_overlay == null or combat_manager == null:
		return

	if build_overlay.has_method("refresh_build") and combat_manager.has_method("get_build_state"):
		build_overlay.refresh_build(combat_manager.get_build_state())


func _on_build_return_to_shop_requested() -> void:
	if run_state != RunState.BUILD:
		return

	_set_run_state(RunState.SHOP)


func _on_build_tower_purchase_requested(slot_id: String) -> void:
	if run_state != RunState.BUILD:
		return
	if combat_manager == null or not combat_manager.has_method("purchase_tower_upgrade"):
		return

	var purchased: bool = combat_manager.purchase_tower_upgrade(slot_id)
	if purchased:
		_refresh_build()
		_refresh_shop()
		_refresh_all_towers()


func _on_tower_state_changed() -> void:
	_refresh_all_towers()

	if is_build_open:
		_refresh_build()

	if is_shop_open:
		_refresh_shop()


func _refresh_all_towers() -> void:
	if combat_manager == null or tower_container == null or projectile_container == null:
		return

	for slot_id in combat_manager.tower_levels.keys():
		var level: int = combat_manager.get_tower_level(slot_id)

		if level <= 0:
			if tower_nodes.has(slot_id) and is_instance_valid(tower_nodes[slot_id]):
				tower_nodes[slot_id].queue_free()
			tower_nodes.erase(slot_id)
			continue

		var tower: Node2D = tower_nodes.get(slot_id, null)

		if tower == null or not is_instance_valid(tower):
			var marker: Marker2D = tower_container.get_node_or_null(slot_id)
			if marker == null:
				continue

			tower = TOWER_SCENE.instantiate()
			tower_container.add_child(tower)
			tower.global_position = marker.global_position
			tower_nodes[slot_id] = tower

		if tower.has_method("setup_tower"):
			tower.setup_tower(slot_id, combat_manager, projectile_container)
