# res://scripts/game/screens/training_room_game_screen.gd
class_name TrainingRoomGameScreen
extends Control

signal back_to_menu_requested
signal word_lists_requested

enum TrainingStep {
	INTRO,
	DESTROY_ONE_DUMMY,
	USE_SPECIAL,
	MAKE_100_GOLD_A,
	BUY_UPGRADE,
	MAKE_100_GOLD_B,
	BUILD_TOWER,
	CHARGE_TOWER,
	DEFEAT_5_STRONG,
	FINAL_DIALOGUE,
	FREE_PRACTICE,
}

enum TrainingRunState {
	DIALOGUE,
	ACTIVE,
	SHOP,
	BUILD,
	PAUSED,
}

const SHOP_DEFINITIONS = preload("res://data/shop/shop_definitions.gd")

@onready var training_room_level: TrainingRoomLevel = %TrainingRoomLevel

@onready var game_hud: CanvasLayer = %GameHud
@onready var game_menu_overlay: CanvasLayer = %GameMenuOverlay
@onready var shop_overlay: CanvasLayer = %ShopOverlay
@onready var build_overlay: CanvasLayer = %BuildOverlay
@onready var training_word_list_overlay: TrainingWordListOverlay = %TrainingWordListOverlay
@onready var dialogue_overlay: CanvasLayer = %DialogueOverlay

@onready var projectile_container: Node = %ProjectileContainer
@onready var typing_manager: Node = %TypingManager
@onready var combat_manager: Node = %CombatManager

@onready var goal_label: Label = %GoalLabel

var current_step: TrainingStep = TrainingStep.INTRO
var run_state: TrainingRunState = TrainingRunState.DIALOGUE
var previous_run_state: TrainingRunState = TrainingRunState.ACTIVE

var selected_training_word_list_ids: Array[String] = ["easy"]

var current_gold: int = 0
var gold_at_goal_start: int = 0
var strong_enemies_defeated: int = 0

var is_game_menu_open: bool = false
var is_shop_open: bool = false
var is_build_open: bool = false

var player_character: Node = null


func _ready() -> void:
	_setup_training_room()
	_connect_signals()
	await get_tree().process_frame
	_start_intro()


# ---------------------------
# SETUP
# ---------------------------

func _setup_training_room() -> void:
	get_tree().paused = false

	if training_room_level == null:
		push_error("TrainingRoomGameScreen: Missing %TrainingRoomLevel.")
		return

	player_character = training_room_level.get_player_character()

	training_room_level.set_respawn_enabled(false)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.clear_dummies()

	_setup_combat_run()
	_bind_managers_to_level()
	_connect_player_signals()

	_hide_game_menu()
	_hide_shop()
	_hide_build()
	_hide_training_word_list_overlay()

	_set_goal_text("")
	_set_status_text("Training.")
	_hide_start_wave_button()
	_enable_typing(false)


func _setup_combat_run() -> void:
	if combat_manager == null:
		return

	if combat_manager.has_method("setup_run"):
		combat_manager.setup_run({
			"mode": "training",
			"wave_definitions": [],
			"persistent_upgrade_levels": {
				"word_damage": 0,
				"special_damage": 0,
				"special_meter_gain": 0,
				"gold_gain": 0,
			},
		})

	if combat_manager.has_method("reset_for_new_run"):
		combat_manager.reset_for_new_run()

	if combat_manager.has_method("set_available_tower_slots"):
		combat_manager.set_available_tower_slots(training_room_level.get_tower_slot_ids())

	current_gold = 0
	_refresh_gold_ui()


func _bind_managers_to_level() -> void:
	if typing_manager != null:
		if typing_manager.has_method("set_level"):
			typing_manager.set_level(training_room_level)

		if typing_manager.has_method("reset_for_new_run"):
			typing_manager.reset_for_new_run()

	if combat_manager != null:
		if combat_manager.has_method("set_enemy_container"):
			combat_manager.set_enemy_container(training_room_level.get_enemy_container())

		if combat_manager.has_method("set_player"):
			combat_manager.set_player(training_room_level.get_player_character())

	if build_overlay != null:
		if build_overlay.has_method("set_level"):
			build_overlay.set_level(training_room_level)


func _connect_signals() -> void:
	if game_hud != null:
		if game_hud.has_signal("game_menu_pressed") and not game_hud.game_menu_pressed.is_connected(_on_game_menu_pressed):
			game_hud.game_menu_pressed.connect(_on_game_menu_pressed)

		if game_hud.has_signal("text_changed") and not game_hud.text_changed.is_connected(_on_hud_text_changed):
			game_hud.text_changed.connect(_on_hud_text_changed)

		if game_hud.has_signal("text_submitted") and not game_hud.text_submitted.is_connected(_on_hud_text_submitted):
			game_hud.text_submitted.connect(_on_hud_text_submitted)

	if game_menu_overlay != null:
		if game_menu_overlay.has_signal("back_to_menu_requested") and not game_menu_overlay.back_to_menu_requested.is_connected(_on_back_to_menu_pressed):
			game_menu_overlay.back_to_menu_requested.connect(_on_back_to_menu_pressed)

		if game_menu_overlay.has_signal("resume_requested") and not game_menu_overlay.resume_requested.is_connected(_on_game_menu_resume_requested):
			game_menu_overlay.resume_requested.connect(_on_game_menu_resume_requested)

		if game_menu_overlay.has_signal("word_lists_requested") and not game_menu_overlay.word_lists_requested.is_connected(_on_word_lists_requested):
			game_menu_overlay.word_lists_requested.connect(_on_word_lists_requested)

	if shop_overlay != null:
		if shop_overlay.has_signal("purchase_requested") and not shop_overlay.purchase_requested.is_connected(_on_shop_purchase_requested):
			shop_overlay.purchase_requested.connect(_on_shop_purchase_requested)

		if shop_overlay.has_signal("build_mode_requested") and not shop_overlay.build_mode_requested.is_connected(_on_shop_build_mode_requested):
			shop_overlay.build_mode_requested.connect(_on_shop_build_mode_requested)

		if shop_overlay.has_signal("next_wave_requested") and not shop_overlay.next_wave_requested.is_connected(_on_shop_next_wave_requested):
			shop_overlay.next_wave_requested.connect(_on_shop_next_wave_requested)

	if build_overlay != null:
		if build_overlay.has_signal("return_to_shop_requested") and not build_overlay.return_to_shop_requested.is_connected(_on_build_return_to_shop_requested):
			build_overlay.return_to_shop_requested.connect(_on_build_return_to_shop_requested)

		if build_overlay.has_signal("tower_purchase_requested") and not build_overlay.tower_purchase_requested.is_connected(_on_build_tower_purchase_requested):
			build_overlay.tower_purchase_requested.connect(_on_build_tower_purchase_requested)

	if training_word_list_overlay != null:
		if training_word_list_overlay.has_signal("word_pool_changed") and not training_word_list_overlay.word_pool_changed.is_connected(_on_training_word_pool_changed):
			training_word_list_overlay.word_pool_changed.connect(_on_training_word_pool_changed)

	if typing_manager != null:
		if typing_manager.has_signal("word_completed") and not typing_manager.word_completed.is_connected(_on_word_completed):
			typing_manager.word_completed.connect(_on_word_completed)

		if typing_manager.has_signal("input_cleared") and not typing_manager.input_cleared.is_connected(_on_typing_input_cleared):
			typing_manager.input_cleared.connect(_on_typing_input_cleared)

		if typing_manager.has_signal("special_used") and not typing_manager.special_used.is_connected(_on_special_used):
			typing_manager.special_used.connect(_on_special_used)

	if combat_manager != null:
		if combat_manager.has_signal("hud_stats_changed") and not combat_manager.hud_stats_changed.is_connected(_on_hud_stats_changed):
			combat_manager.hud_stats_changed.connect(_on_hud_stats_changed)

		if combat_manager.has_signal("special_meter_changed") and not combat_manager.special_meter_changed.is_connected(_on_special_meter_changed):
			combat_manager.special_meter_changed.connect(_on_special_meter_changed)

		if combat_manager.has_signal("special_meter_filled") and not combat_manager.special_meter_filled.is_connected(_on_special_meter_filled):
			combat_manager.special_meter_filled.connect(_on_special_meter_filled)

		if combat_manager.has_signal("tower_state_changed") and not combat_manager.tower_state_changed.is_connected(_on_tower_state_changed):
			combat_manager.tower_state_changed.connect(_on_tower_state_changed)


func _connect_player_signals() -> void:
	if player_character == null or not is_instance_valid(player_character):
		return

	if player_character.has_signal("special_projectile_impact"):
		if not player_character.special_projectile_impact.is_connected(_on_special_projectile_impact):
			player_character.special_projectile_impact.connect(_on_special_projectile_impact)


# ---------------------------
# RUN STATE
# ---------------------------

func _set_run_state(new_state: TrainingRunState) -> void:
	run_state = new_state

	match run_state:
		TrainingRunState.DIALOGUE:
			_enable_typing(false)
			_hide_start_wave_button()
			_set_status_text("Dialogue.")
			_hide_shop()
			_hide_build()

		TrainingRunState.ACTIVE:
			_enable_typing(true)
			_hide_start_wave_button()
			_set_status_text("Training.")
			_hide_shop()
			_hide_build()

		TrainingRunState.SHOP:
			_enable_typing(false)
			_hide_start_wave_button()
			_set_status_text("Training Shop.")
			_show_shop()
			_hide_build()

		TrainingRunState.BUILD:
			_enable_typing(false)
			_hide_start_wave_button()
			_set_status_text("Build Mode.")
			_hide_shop()
			_show_build()

		TrainingRunState.PAUSED:
			_enable_typing(false)
			_hide_start_wave_button()
			_set_status_text("Paused.")


# ---------------------------
# HUD / TYPING
# ---------------------------

func _on_hud_text_changed(text: String) -> void:
	if run_state != TrainingRunState.ACTIVE:
		return

	if is_game_menu_open or is_shop_open or is_build_open:
		return

	if typing_manager != null and typing_manager.has_method("process_input_text"):
		typing_manager.process_input_text(text)


func _on_hud_text_submitted(_text: String) -> void:
	if run_state != TrainingRunState.ACTIVE:
		return

	if is_game_menu_open or is_shop_open or is_build_open:
		return

	if typing_manager != null and typing_manager.has_method("cancel_current_target"):
		typing_manager.cancel_current_target()


func _on_word_completed(completed_target: Node) -> void:
	if run_state != TrainingRunState.ACTIVE:
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


func _enable_typing(enabled: bool) -> void:
	if typing_manager != null and typing_manager.has_method("set_active"):
		typing_manager.set_active(enabled)

	if not enabled and typing_manager != null and typing_manager.has_method("clear_input_state"):
		typing_manager.clear_input_state()

	if game_hud != null and game_hud.has_method("set_input_enabled"):
		game_hud.set_input_enabled(enabled)

	if game_hud != null and game_hud.has_method("clear_input"):
		game_hud.clear_input()


func _hide_start_wave_button() -> void:
	if game_hud != null and game_hud.has_method("hide_start_wave_button"):
		game_hud.hide_start_wave_button()


func _set_status_text(text: String) -> void:
	if game_hud != null and game_hud.has_method("set_status_text"):
		game_hud.set_status_text(text)


func _refresh_gold_ui() -> void:
	if game_hud != null and game_hud.has_method("set_gold"):
		game_hud.set_gold(current_gold)


func _on_hud_stats_changed(stats: Dictionary) -> void:
	if stats.has("gold"):
		current_gold = int(stats.get("gold", current_gold))
		_refresh_gold_ui()

	if game_hud != null and game_hud.has_method("set_base_hp"):
		game_hud.set_base_hp(
			int(stats.get("base_hp", 0)),
			int(stats.get("base_hp_max", 0))
		)

	if is_shop_open:
		_refresh_shop()

	if is_build_open:
		_refresh_build()

	_check_gold_goals()


# ---------------------------
# SPECIAL
# ---------------------------

func _on_special_meter_changed(current_value: float, max_value: float) -> void:
	if player_character == null or not is_instance_valid(player_character):
		return

	if player_character.has_method("set_special_meter"):
		player_character.set_special_meter(current_value, max_value)


func _on_special_meter_filled() -> void:
	if run_state != TrainingRunState.ACTIVE:
		return

	if player_character == null or not is_instance_valid(player_character):
		return

	var target_enemy: Node = _get_front_most_training_enemy()
	if target_enemy == null:
		return

	if player_character.has_method("fire_special_projectile"):
		player_character.fire_special_projectile(target_enemy, projectile_container)


func _on_special_projectile_impact(target_enemy: Node) -> void:
	if combat_manager != null and combat_manager.has_method("fire_player_special_at_target"):
		combat_manager.fire_player_special_at_target(target_enemy)

	if current_step == TrainingStep.USE_SPECIAL:
		_complete_use_special_goal()


func _on_special_used() -> void:
	if current_step == TrainingStep.USE_SPECIAL:
		_complete_use_special_goal()


func _get_front_most_training_enemy() -> Node:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue

		if enemy.has_method("is_enemy_dead") and enemy.is_enemy_dead():
			continue

		return enemy

	return null


# ---------------------------
# GAME MENU
# ---------------------------

func _on_game_menu_pressed() -> void:
	if is_game_menu_open:
		return

	previous_run_state = run_state
	is_game_menu_open = true
	get_tree().paused = true
	_set_run_state(TrainingRunState.PAUSED)

	if game_menu_overlay != null and game_menu_overlay.has_method("show_overlay"):
		game_menu_overlay.show_overlay()


func _on_game_menu_resume_requested() -> void:
	is_game_menu_open = false
	get_tree().paused = false

	if game_menu_overlay != null and game_menu_overlay.has_method("hide_overlay"):
		game_menu_overlay.hide_overlay()

	_set_run_state(previous_run_state)


func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	back_to_menu_requested.emit()


func _on_word_lists_requested() -> void:
	word_lists_requested.emit()


func _hide_game_menu() -> void:
	is_game_menu_open = false

	if game_menu_overlay != null and game_menu_overlay.has_method("hide_overlay"):
		game_menu_overlay.hide_overlay()


# ---------------------------
# SHOP
# ---------------------------

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
	if run_state != TrainingRunState.SHOP:
		return

	if combat_manager == null or not combat_manager.has_method("apply_upgrade_purchase"):
		return

	var purchased: bool = combat_manager.apply_upgrade_purchase(upgrade_id)

	if purchased:
		_refresh_shop()

		if current_step == TrainingStep.BUY_UPGRADE:
			_complete_buy_upgrade_goal()


func _on_shop_build_mode_requested() -> void:
	if run_state != TrainingRunState.SHOP:
		return

	if current_step == TrainingStep.BUY_UPGRADE:
		return

	_set_run_state(TrainingRunState.BUILD)


func _on_shop_next_wave_requested() -> void:
	if run_state != TrainingRunState.SHOP:
		return

	if current_step == TrainingStep.BUY_UPGRADE:
		return

	_set_run_state(TrainingRunState.ACTIVE)


func _set_shop_mode_upgrades_only() -> void:
	if shop_overlay == null:
		return

	if shop_overlay.has_method("set_build_mode_enabled"):
		shop_overlay.set_build_mode_enabled(false)

	if shop_overlay.has_method("set_upgrade_buttons_enabled"):
		shop_overlay.set_upgrade_buttons_enabled(true)


# ---------------------------
# BUILD
# ---------------------------

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
	if run_state != TrainingRunState.BUILD:
		return

	_set_run_state(TrainingRunState.SHOP)


func _on_build_tower_purchase_requested(slot_id: String, tower_type: String) -> void:
	if run_state != TrainingRunState.BUILD:
		return

	if combat_manager == null or not combat_manager.has_method("purchase_tower_upgrade"):
		return

	var purchased: bool = combat_manager.purchase_tower_upgrade(slot_id, tower_type)

	if purchased:
		_refresh_build()
		_refresh_shop()

		if training_room_level != null:
			training_room_level.refresh_all_towers(combat_manager)

		if current_step == TrainingStep.BUILD_TOWER:
			_complete_build_tower_goal()


func _set_build_mode_towers_only() -> void:
	if build_overlay == null:
		return

	if build_overlay.has_method("set_regular_upgrade_buttons_enabled"):
		build_overlay.set_regular_upgrade_buttons_enabled(false)

	if build_overlay.has_method("set_tower_buttons_enabled"):
		build_overlay.set_tower_buttons_enabled(true)


func _on_tower_state_changed() -> void:
	if training_room_level != null:
		training_room_level.refresh_all_towers(combat_manager)

	if is_build_open:
		_refresh_build()

	if is_shop_open:
		_refresh_shop()

	if current_step == TrainingStep.CHARGE_TOWER:
		_complete_charge_tower_goal()


# ---------------------------
# TRAINING WORD LIST OVERLAY
# ---------------------------

func _show_training_word_list_overlay() -> void:
	if training_word_list_overlay != null:
		training_word_list_overlay.open_overlay(selected_training_word_list_ids)


func _hide_training_word_list_overlay() -> void:
	if training_word_list_overlay != null:
		training_word_list_overlay.visible = false


func _on_training_word_pool_changed(words: Array[String], selected_ids: Array[String]) -> void:
	if current_step != TrainingStep.FREE_PRACTICE:
		return

	selected_training_word_list_ids = selected_ids.duplicate()

	if words.is_empty():
		return

	training_room_level.reset_dummies_with_word_pool(words, 2)


# ---------------------------
# DIALOGUE
# ---------------------------

func _play_dialogue(lines: Array[Dictionary]) -> void:
	_set_run_state(TrainingRunState.DIALOGUE)

	if training_room_level != null:
		training_room_level.set_respawn_enabled(false)

	if dialogue_overlay == null:
		return

	dialogue_overlay.visible = true
	dialogue_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	if dialogue_overlay.has_method("play_dialogue"):
		await dialogue_overlay.play_dialogue(lines)
	elif dialogue_overlay.has_method("start_dialogue"):
		dialogue_overlay.start_dialogue(lines)

		if dialogue_overlay.has_signal("dialogue_finished"):
			await dialogue_overlay.dialogue_finished
	elif dialogue_overlay.has_method("start_from_lines"):
		dialogue_overlay.start_from_lines(lines)

		if dialogue_overlay.has_signal("dialogue_finished"):
			await dialogue_overlay.dialogue_finished
	else:
		push_warning("TrainingRoomGameScreen: DialogueOverlay needs play_dialogue(), start_dialogue(), or start_from_lines().")

	dialogue_overlay.visible = false


# ---------------------------
# TRAINING FLOW
# ---------------------------

func _start_intro() -> void:
	current_step = TrainingStep.INTRO

	await _play_dialogue([
		{"speaker": "Jisho", "text": "Welcome to the training room."},
		{"speaker": "Jisho", "text": "I am Jisho. This is where you learn how to survive."},
		{"speaker": "Player", "text": "Survive?"},
		{"speaker": "Jisho", "text": "Yes. Also, change your name now if you want. Names are powerful. Mostly for menus."},
	])

	_start_destroy_one_dummy_goal()


func _start_destroy_one_dummy_goal() -> void:
	current_step = TrainingStep.DESTROY_ONE_DUMMY

	await _play_dialogue([
		{"speaker": "Jisho", "text": "Your magic is simple. Type the word above an enemy to damage it."},
		{"speaker": "Jisho", "text": "Destroy one training dummy."},
	])

	_set_goal_text("Goal: Destroy 1 training dummy")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(false)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.spawn_one_dummy()

	_listen_for_next_dummy_death(_complete_destroy_one_dummy_goal)


func _complete_destroy_one_dummy_goal() -> void:
	if current_step != TrainingStep.DESTROY_ONE_DUMMY:
		return

	_start_use_special_goal()


func _start_use_special_goal() -> void:
	current_step = TrainingStep.USE_SPECIAL

	await _play_dialogue([
		{"speaker": "Jisho", "text": "Good. Now attack multiple enemies."},
		{"speaker": "Jisho", "text": "As you type, your special bar fills. When it is full, use your special attack."},
	])

	_set_goal_text("Goal: Use your special")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.spawn_two_dummies()


func _complete_use_special_goal() -> void:
	if current_step != TrainingStep.USE_SPECIAL:
		return

	_start_make_gold_goal_a()


func _start_make_gold_goal_a() -> void:
	current_step = TrainingStep.MAKE_100_GOLD_A
	gold_at_goal_start = current_gold

	await _play_dialogue([
		{"speaker": "Jisho", "text": "Defeating enemies gives you gold."},
		{"speaker": "Jisho", "text": "Gold lets you buy upgrades and build defenses."},
	])

	_set_goal_text("Goal: Make 100 gold")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.spawn_two_dummies()


func _check_gold_goals() -> void:
	if current_step == TrainingStep.MAKE_100_GOLD_A:
		if current_gold - gold_at_goal_start >= 100:
			_complete_make_gold_goal_a()

	elif current_step == TrainingStep.MAKE_100_GOLD_B:
		if current_gold - gold_at_goal_start >= 100:
			_complete_make_gold_goal_b()


func _complete_make_gold_goal_a() -> void:
	if current_step != TrainingStep.MAKE_100_GOLD_A:
		return

	_start_buy_upgrade_goal()


func _start_buy_upgrade_goal() -> void:
	current_step = TrainingStep.BUY_UPGRADE

	await _play_dialogue([
		{"speaker": "Jisho", "text": "Now open the shop."},
		{"speaker": "Jisho", "text": "Buy any upgrade. Build mode is disabled for now."},
	])

	_set_goal_text("Goal: Buy an upgrade")

	training_room_level.set_respawn_enabled(false)
	training_room_level.clear_dummies()

	_set_run_state(TrainingRunState.SHOP)
	_set_shop_mode_upgrades_only()


func _complete_buy_upgrade_goal() -> void:
	if current_step != TrainingStep.BUY_UPGRADE:
		return

	_hide_shop()
	_start_make_gold_goal_b()


func _start_make_gold_goal_b() -> void:
	current_step = TrainingStep.MAKE_100_GOLD_B
	gold_at_goal_start = current_gold

	await _play_dialogue([
		{"speaker": "Jisho", "text": "Good. Now test your upgrade."},
		{"speaker": "Jisho", "text": "Make 100 more gold."},
	])

	_set_goal_text("Goal: Make 100 gold again")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.spawn_two_dummies()


func _complete_make_gold_goal_b() -> void:
	if current_step != TrainingStep.MAKE_100_GOLD_B:
		return

	_start_build_tower_goal()


func _start_build_tower_goal() -> void:
	current_step = TrainingStep.BUILD_TOWER

	await _play_dialogue([
		{"speaker": "Jisho", "text": "Next: towers."},
		{"speaker": "Jisho", "text": "Use gold and magic to build towers. They help defeat enemies."},
		{"speaker": "Jisho", "text": "Buy a tower now. Regular upgrades are disabled."},
	])

	_set_goal_text("Goal: Build a tower")

	training_room_level.set_respawn_enabled(false)
	training_room_level.clear_dummies()

	_set_run_state(TrainingRunState.BUILD)
	_set_build_mode_towers_only()


func _complete_build_tower_goal() -> void:
	if current_step != TrainingStep.BUILD_TOWER:
		return

	_hide_build()
	_start_charge_tower_goal()


func _start_charge_tower_goal() -> void:
	current_step = TrainingStep.CHARGE_TOWER

	await _play_dialogue([
		{"speaker": "Jisho", "text": "A tower is not useful by itself."},
		{"speaker": "Jisho", "text": "Charge it with magic. Type tower words until it activates."},
	])

	_set_goal_text("Goal: Charge the tower")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.spawn_two_dummies()


func _complete_charge_tower_goal() -> void:
	if current_step != TrainingStep.CHARGE_TOWER:
		return

	_start_defeat_strong_goal()


func _start_defeat_strong_goal() -> void:
	current_step = TrainingStep.DEFEAT_5_STRONG
	strong_enemies_defeated = 0

	await _play_dialogue([
		{"speaker": "Jisho", "text": "Stronger creatures resist weak magic."},
		{"speaker": "Jisho", "text": "That means you must type longer and more difficult words to affect them."},
		{"speaker": "Jisho", "text": "Defeat five strong dummies."},
	])

	_set_goal_text("Goal: Defeat 5 strong enemies (0 / 5)")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(["hard"]))
	training_room_level.spawn_two_dummies()

	_listen_for_dummy_deaths(_on_strong_dummy_died)


func _on_strong_dummy_died() -> void:
	if current_step != TrainingStep.DEFEAT_5_STRONG:
		return

	strong_enemies_defeated += 1
	_set_goal_text("Goal: Defeat 5 strong enemies (%d / 5)" % strong_enemies_defeated)

	if strong_enemies_defeated >= 5:
		_complete_defeat_strong_goal()


func _complete_defeat_strong_goal() -> void:
	if current_step != TrainingStep.DEFEAT_5_STRONG:
		return

	_start_final_dialogue()


func _start_final_dialogue() -> void:
	current_step = TrainingStep.FINAL_DIALOGUE

	await _play_dialogue([
		{"speaker": "Jisho", "text": "That's about everything."},
		{"speaker": "Jisho", "text": "There are lots of different creatures to fight out there."},
		{"speaker": "Jisho", "text": "As you explore, you may discover new types of magic, towers, enemies, and all sorts of things."},
		{"speaker": "Jisho", "text": "Feel free to practice here as long as you like."},
		{"speaker": "Jisho", "text": "Use the menu in the top left to leave the training room when you're ready."},
	])

	_start_free_practice()


func _start_free_practice() -> void:
	current_step = TrainingStep.FREE_PRACTICE
	selected_training_word_list_ids = ["easy"]

	_set_goal_text("Free Practice")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(selected_training_word_list_ids))
	training_room_level.spawn_two_dummies()

	_show_training_word_list_overlay()


# ---------------------------
# WORD LISTS
# ---------------------------

func _get_words_from_list_ids(list_ids: Array[String]) -> Array[String]:
	var words: Array[String] = []
	var seen_words: Dictionary = {}

	for list_id in list_ids:
		var list_data: WordListData = WordLists.get_list(str(list_id))

		if list_data == null:
			continue

		for word in list_data.words:
			var clean_word: String = str(word).strip_edges()

			if clean_word.is_empty():
				continue

			var key: String = clean_word.to_lower()

			if seen_words.has(key):
				continue

			seen_words[key] = true
			words.append(clean_word)

	return words


# ---------------------------
# DUMMY DEATH LISTENERS
# ---------------------------

func _listen_for_next_dummy_death(callback: Callable) -> void:
	await get_tree().process_frame

	for dummy: Node in get_tree().get_nodes_in_group("training_dummies"):
		if dummy.has_signal("enemy_died"):
			dummy.enemy_died.connect(
				func(_enemy: Node) -> void:
					callback.call(),
				CONNECT_ONE_SHOT
			)


func _listen_for_dummy_deaths(callback: Callable) -> void:
	for dummy: Node in get_tree().get_nodes_in_group("training_dummies"):
		if dummy.has_signal("enemy_died"):
			if not dummy.enemy_died.is_connected(_on_any_training_dummy_died):
				dummy.enemy_died.connect(_on_any_training_dummy_died.bind(callback))


func _on_any_training_dummy_died(_enemy: Node, callback: Callable) -> void:
	callback.call()

	await get_tree().create_timer(0.1).timeout

	if current_step == TrainingStep.DEFEAT_5_STRONG:
		_listen_for_dummy_deaths(callback)


# ---------------------------
# MISC
# ---------------------------

func _set_goal_text(text: String) -> void:
	if goal_label != null:
		goal_label.text = text
