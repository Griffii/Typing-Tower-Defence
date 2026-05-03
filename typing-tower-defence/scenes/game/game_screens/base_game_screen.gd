# res://scripts/game/base_game_screen.gd
class_name BaseGameScreen
extends Control

signal back_to_menu_requested
signal return_to_map_requested
signal word_lists_requested

enum RunState {
	PRE_WAVE,
	COUNTDOWN,
	WAVE_ACTIVE,
	SHOP,
	BUILD,
	VICTORY,
	DEFEAT
}

const SHOP_DEFINITIONS = preload("res://data/shop/shop_definitions.gd")

var DEV_MODE: bool = true

var selected_level_scene: PackedScene = null
var selected_wave_defs: Array = []

@onready var battlefield: Node = %Battlefield

@onready var game_hud: CanvasLayer = %GameHud
@onready var countdown_overlay: CanvasLayer = %CountdownOverlay
@onready var game_over_overlay: CanvasLayer = %GameOverOverlay
@onready var game_menu_overlay: CanvasLayer = %GameMenuOverlay
@onready var shop_overlay: CanvasLayer = %ShopOverlay
@onready var build_overlay: CanvasLayer = %BuildOverlay

@onready var projectile_container: Node = %ProjectileContainer

@onready var wave_manager: Node = %WaveManager
@onready var spawn_manager: Node = %SpawnManager
@onready var typing_manager: Node = %TypingManager
@onready var combat_manager: Node = %CombatManager

@onready var dev_stuff: CanvasLayer = %DevStuff
@onready var skip_wave_button: Button = %DEBUG_SkipWave

var current_level: BattlefieldLevel = null
var player_character: PlayerCharacter = null

var run_state: RunState = RunState.PRE_WAVE
var current_wave_index: int = 0
var total_waves: int = 0
var run_active: bool = false
var wave_set: Array = []

var is_game_menu_open: bool = false
var is_shop_open: bool = false
var is_build_open: bool = false

var current_gold: int = 0


func _ready() -> void:
	_connect_signals()
	_load_run_content()
	_setup_run_mode()
	_reset_run()
	_apply_run_upgrades()
	_set_dev_visibility()


func _set_dev_visibility() -> void:
	if dev_stuff == null:
		return

	dev_stuff.visible = DEV_MODE


func _load_run_content() -> void:
	pass


func _setup_run_mode() -> void:
	pass


func _apply_run_upgrades() -> void:
	pass


func _on_run_victory() -> void:
	_set_run_state(RunState.VICTORY)


func _on_run_defeat() -> void:
	_set_run_state(RunState.DEFEAT)


func _should_show_shop_after_wave() -> bool:
	return true


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
		if game_over_overlay.has_signal("return_to_map_requested"):
			game_over_overlay.return_to_map_requested.connect(_on_return_to_map_requested)

	if game_menu_overlay != null:
		if game_menu_overlay.has_signal("back_to_menu_requested"):
			game_menu_overlay.back_to_menu_requested.connect(_on_back_to_menu_pressed)
		if game_menu_overlay.has_signal("resume_requested"):
			game_menu_overlay.resume_requested.connect(_on_game_menu_resume_requested)
		if game_menu_overlay.has_signal("word_lists_requested"):
			game_menu_overlay.word_lists_requested.connect(_on_word_lists_requested)

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

		if combat_manager.has_signal("special_meter_changed"):
			combat_manager.special_meter_changed.connect(_on_special_meter_changed)

		if combat_manager.has_signal("special_meter_filled"):
			if not combat_manager.special_meter_filled.is_connected(_on_special_meter_filled):
				combat_manager.special_meter_filled.connect(_on_special_meter_filled)

		if combat_manager.has_signal("tower_state_changed"):
			combat_manager.tower_state_changed.connect(_on_tower_state_changed)
		if combat_manager.has_signal("base_damaged"):
			combat_manager.base_damaged.connect(_on_base_damaged)
		if combat_manager.has_signal("base_repaired"):
			combat_manager.base_repaired.connect(_on_base_repaired)

	if typing_manager != null:
		if typing_manager.has_signal("word_completed"):
			typing_manager.word_completed.connect(_on_word_completed)
		if typing_manager.has_signal("input_cleared"):
			typing_manager.input_cleared.connect(_on_typing_input_cleared)
	
	if skip_wave_button != null:
		if not skip_wave_button.pressed.is_connected(debug_skip_wave):
			skip_wave_button.pressed.connect(debug_skip_wave)


func load_level(level_scene: PackedScene) -> void:
	if current_level != null and is_instance_valid(current_level):
		current_level.queue_free()
		current_level = null

	player_character = null

	if level_scene == null:
		push_warning("GameScreen: level_scene was null.")
		return

	current_level = level_scene.instantiate() as BattlefieldLevel

	if current_level == null:
		push_warning("GameScreen: Loaded level is not a BattlefieldLevel.")
		return

	battlefield.add_child(current_level)

	if current_level.has_method("setup_level"):
		current_level.setup_level(projectile_container)

	_cache_player_character()
	_connect_player_character_signals()
	_apply_level_references_to_systems()


func _cache_player_character() -> void:
	player_character = null

	if current_level == null:
		return

	if not current_level.has_method("get_player_character"):
		push_warning("GameScreen: current_level has no get_player_character().")
		return

	player_character = current_level.get_player_character()

	if player_character == null or not is_instance_valid(player_character):
		push_warning("GameScreen: Level returned no valid PlayerCharacter.")
		player_character = null


func _connect_player_character_signals() -> void:
	if player_character == null or not is_instance_valid(player_character):
		return

	if player_character.has_signal("special_projectile_impact"):
		if not player_character.special_projectile_impact.is_connected(_on_special_projectile_impact):
			player_character.special_projectile_impact.connect(_on_special_projectile_impact)

	if player_character.has_signal("player_damaged"):
		if not player_character.player_damaged.is_connected(_on_player_damaged):
			player_character.player_damaged.connect(_on_player_damaged)


func _apply_level_references_to_systems() -> void:
	if current_level == null:
		return

	if spawn_manager != null:
		if spawn_manager.has_method("set_enemy_path") and current_level.has_method("get_enemy_path"):
			spawn_manager.set_enemy_path(current_level.get_enemy_path())

		if spawn_manager.has_method("set_enemy_spawn_marker") and current_level.has_method("get_enemy_spawn_marker"):
			spawn_manager.set_enemy_spawn_marker(current_level.get_enemy_spawn_marker())

		if spawn_manager.has_method("set_enemy_container") and current_level.has_method("get_enemy_container"):
			spawn_manager.set_enemy_container(current_level.get_enemy_container())

		if spawn_manager.has_method("set_enemy_scale") and current_level.has_method("get_enemy_scale"):
			spawn_manager.set_enemy_scale(current_level.get_enemy_scale())

	if typing_manager != null and typing_manager.has_method("set_level"):
		typing_manager.set_level(current_level)

	if build_overlay != null and build_overlay.has_method("set_level"):
		build_overlay.set_level(current_level)

	if combat_manager != null and combat_manager.has_method("set_available_tower_slots"):
		if current_level.has_method("get_tower_slot_ids"):
			combat_manager.set_available_tower_slots(current_level.get_tower_slot_ids())


func setup_run(run_config: Dictionary) -> void:
	wave_set = []

	if run_config.has("wave_definitions"):
		var defs: Variant = run_config.get("wave_definitions", [])
		if typeof(defs) == TYPE_ARRAY:
			wave_set = defs as Array

	total_waves = wave_set.size()

	if combat_manager != null and combat_manager.has_method("setup_run"):
		combat_manager.setup_run(run_config)

	_reset_run()


func _reset_run() -> void:
	run_active = true
	current_wave_index = 0
	total_waves = wave_set.size()
	is_game_menu_open = false
	is_shop_open = false
	is_build_open = false
	current_gold = 0

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

	if player_character != null and is_instance_valid(player_character):
		player_character.reset_special_meter()

	if game_over_overlay != null and game_over_overlay.has_method("hide_overlay"):
		game_over_overlay.hide_overlay()

	if game_menu_overlay != null and game_menu_overlay.has_method("hide_overlay"):
		game_menu_overlay.hide_overlay()

	if shop_overlay != null and shop_overlay.has_method("hide_overlay"):
		shop_overlay.hide_overlay()

	if build_overlay != null and build_overlay.has_method("hide_overlay"):
		build_overlay.hide_overlay()

	if current_level != null and current_level.has_method("reset_level_state"):
		current_level.reset_level_state()

	if current_level != null and current_level.has_method("refresh_all_towers"):
		current_level.refresh_all_towers(combat_manager)

	_refresh_gold_ui()
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


func _refresh_gold_ui() -> void:
	if game_hud != null and game_hud.has_method("set_gold"):
		game_hud.set_gold(current_gold)


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

	if combat_manager != null and combat_manager.has_method("reset_special_meter"):
		combat_manager.reset_special_meter()

	if player_character != null and is_instance_valid(player_character):
		player_character.reset_special_meter()

	current_wave_index = wave_index + 1
	_refresh_wave_ui()

	if current_wave_index >= total_waves:
		_on_all_waves_cleared()
		return

	if _should_show_shop_after_wave():
		_set_run_state(RunState.SHOP)
	else:
		_set_run_state(RunState.PRE_WAVE)


func _on_all_waves_cleared() -> void:
	if run_state == RunState.DEFEAT or run_state == RunState.VICTORY:
		return

	run_active = false
	_on_run_victory()


func _on_base_damaged(_amount: int) -> void:
	if current_level == null:
		return

	if current_level.protect != null and current_level.protect.has_method("play_take_damage"):
		current_level.protect.play_take_damage()


func _on_base_repaired(_amount: int) -> void:
	if current_level == null:
		return

	if current_level.protect != null and current_level.protect.has_method("spawn_repair_burst"):
		current_level.protect.spawn_repair_burst()


func _on_base_destroyed() -> void:
	if run_state == RunState.DEFEAT or run_state == RunState.VICTORY:
		return

	run_active = false
	_on_run_defeat()


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


func _on_word_completed(completed_target: Node) -> void:
	if run_state != RunState.WAVE_ACTIVE:
		return

	if completed_target == null or not is_instance_valid(completed_target):
		return

	if completed_target.is_in_group("enemies"):
		if combat_manager != null and combat_manager.has_method("resolve_completed_word"):
			combat_manager.resolve_completed_word(completed_target)
		return

	if completed_target.has_method("can_accept_word") and completed_target.has_method("complete_current_word"):
		if completed_target.can_accept_word():
			completed_target.complete_current_word()


func _on_typing_input_cleared() -> void:
	if game_hud != null and game_hud.has_method("clear_input"):
		game_hud.clear_input()


func _on_hud_stats_changed(stats: Dictionary) -> void:
	if game_hud == null:
		return

	if stats.has("gold"):
		current_gold = int(stats.get("gold", current_gold))

	if game_hud.has_method("set_gold"):
		game_hud.set_gold(current_gold)

	if game_hud.has_method("set_base_hp"):
		game_hud.set_base_hp(
			int(stats.get("base_hp", 0)),
			int(stats.get("base_hp_max", 0))
		)

	if current_level != null and current_level.protect != null:
		if current_level.protect.has_method("set_base_hp"):
			current_level.protect.set_base_hp(
				int(stats.get("base_hp", 0)),
				int(stats.get("base_hp_max", 0))
			)

	if is_shop_open:
		_refresh_shop()

	if is_build_open:
		_refresh_build()


func _on_special_meter_changed(current_value: float, max_value: float) -> void:
	if player_character == null or not is_instance_valid(player_character):
		return

	player_character.set_special_meter(current_value, max_value)


func _on_special_meter_filled() -> void:
	if spawn_manager == null or not spawn_manager.has_method("get_front_most_enemy"):
		return

	if player_character == null or not is_instance_valid(player_character):
		return

	var target_enemy: Node = spawn_manager.get_front_most_enemy()
	if target_enemy == null or not is_instance_valid(target_enemy):
		return

	player_character.fire_special_projectile(target_enemy, projectile_container)


func _on_special_projectile_impact(target_enemy: Node) -> void:
	if combat_manager != null and combat_manager.has_method("fire_player_special_at_target"):
		combat_manager.fire_player_special_at_target(target_enemy)


func _on_player_damaged(amount: int) -> void:
	if combat_manager != null and combat_manager.has_method("apply_base_damage"):
		combat_manager.apply_base_damage(amount)


func debug_skip_wave() -> void:
	if run_state != RunState.WAVE_ACTIVE:
		return

	if spawn_manager == null:
		return

	if not spawn_manager.has_method("debug_force_spawn_all_remaining_enemies"):
		return

	var enemies: Array[Node] = spawn_manager.debug_force_spawn_all_remaining_enemies()

	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue

		if enemy.has_method("is_enemy_dead") and enemy.is_enemy_dead():
			continue

		if combat_manager != null and combat_manager.has_method("apply_tower_hit"):
			combat_manager.apply_tower_hit(enemy, 9999)
		elif enemy.has_method("apply_damage"):
			enemy.apply_damage(9999)


func _show_game_over(did_win: bool) -> void:
	get_tree().paused = true

	if game_over_overlay == null:
		return

	if game_over_overlay.has_method("show_results"):
		game_over_overlay.show_results({
			"did_win": did_win,
			"wave_reached": current_wave_index + 1,
			"total_waves": total_waves,
			"mode": _get_run_mode_name()
		})


func _get_run_mode_name() -> String:
	return "base"

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


func _on_word_lists_requested() -> void:
	word_lists_requested.emit()
	

func _on_return_to_map_requested() -> void:
	get_tree().paused = false
	return_to_map_requested.emit()

func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	back_to_menu_requested.emit()


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
	if not run_active:
		return

	if run_state != RunState.SHOP:
		return

	_set_run_state(RunState.COUNTDOWN)
	if countdown_overlay != null and countdown_overlay.has_method("play_countdown"):
		countdown_overlay.play_countdown(3, 1.0)


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


func _on_build_return_to_shop_requested() -> void:
	if run_state != RunState.BUILD:
		return

	_set_run_state(RunState.SHOP)


func _refresh_build() -> void:
	if not is_build_open:
		return
	if build_overlay == null or combat_manager == null:
		return

	if build_overlay.has_method("refresh_build") and combat_manager.has_method("get_build_state"):
		build_overlay.refresh_build(combat_manager.get_build_state())


func _on_build_tower_purchase_requested(slot_id: String, tower_type: String) -> void:
	if run_state != RunState.BUILD:
		return
	if combat_manager == null or not combat_manager.has_method("purchase_tower_upgrade"):
		return

	var purchased: bool = combat_manager.purchase_tower_upgrade(slot_id, tower_type)
	if purchased:
		_refresh_build()
		_refresh_shop()

		if current_level != null and current_level.has_method("refresh_all_towers"):
			current_level.refresh_all_towers(combat_manager)


func _on_tower_state_changed() -> void:
	if current_level != null and current_level.has_method("refresh_all_towers"):
		current_level.refresh_all_towers(combat_manager)

	if is_build_open:
		_refresh_build()

	if is_shop_open:
		_refresh_shop()
