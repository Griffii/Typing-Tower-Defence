# res://scripts/game/screens/training_room_game_screen.gd
class_name TrainingRoomGameScreen
extends Control

signal back_to_menu_requested
signal word_lists_requested

enum TrainingStep {
	INTRO,
	SET_NAME,
	DESTROY_ONE_DUMMY,
	USE_SPECIAL,
	MAKE_50_GOLD,
	BUY_UPGRADE,
	MAKE_70_GOLD,
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

const SHOP_DEFINITIONS = preload("uid://bkilul3ytxi2o")
const DIALOGUE_OVERLAY_SCENE: PackedScene = preload("uid://bxtvbt0ut71y2")

const JISHO_AVATAR_SCENE: PackedScene = preload("uid://b807kf2rrb0yt")
const PLAYER_AVATAR_SCENE: PackedScene = preload("uid://8npj02qfrg3f")

const TUTORIAL_SPEAKERS: Array[Dictionary] = [
	{
		"speaker_id": "jisho",
		"display_name": "Jisho",
		"default_position": "right",
		"avatar_scene": JISHO_AVATAR_SCENE,
		"name_color": Color(1.0, 0.784, 1.0, 1.0),
	},
	{
		"speaker_id": "player",
		"display_name": "Player",
		"default_position": "left",
		"avatar_scene": PLAYER_AVATAR_SCENE,
		"use_player_name": true,
		"name_color": Color(1.0, 1.0, 0.784, 1.0),
	},
]

const INTRO_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "Welcome to the training room."},
		{"speaker_id": "jisho", "text": "I am Jisho. Your magical grimoire, and best friend!"},
		{"speaker_id": "player", "text": "Oh."},
		{"speaker_id": "jisho", "text": "What should I call you?"},
	]
}

const DESTROY_ONE_DUMMY_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "Really? {player_name}? If you say so."},
		{"speaker_id": "jisho", "text": "Anyway! Casting spells is simple!"},
		{"speaker_id": "jisho", "text": "You channel your magic through typing."},
		{"speaker_id": "player", "text": "Ok."},
		{"speaker_id": "jisho", "text": "Don't overthink it, just type the words you see. Try it on this training dummy."},
	]
}

const USE_SPECIAL_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "Nice!"},
		{"speaker_id": "jisho", "text": "As you cast spells, your special bar fills."},
		{"speaker_id": "jisho", "text": "When it is full, your will release a special magic attack."},
		{"speaker_id": "player", "text": "Neat."},
		{"speaker_id": "jisho", "text": "Correct. Fill up the bar and fireball those strawmen!"},
	]
}

const MAKE_50_GOLD_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "HAHAHA! BURN!!!!."},
		{"speaker_id": "jisho", "text": "Ehem... anyway."},
		{"speaker_id": "jisho", "text": "As you discover more spells you will be able to change the effect of your sepcial skill."},
		{"speaker_id": "jisho", "text": "Defeating enemies also gives you gold."},
		{"speaker_id": "jisho", "text": "Don't ask me where they keep it."},
		{"speaker_id": "jisho", "text": "You can use that gold to improve your magic damage and special skill."},
		{"speaker_id": "player", "text": "Cool."},
		{"speaker_id": "jisho", "text": "Very. Now let's make some money and get dripped out."},
	]
}

const BUY_UPGRADE_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "Nice job. Let's check out the shop."},
		{"speaker_id": "jisho", "text": "Upgrades improve your power for this run."},
		{"speaker_id": "jisho", "text": "This is practice, so these upgrades will not follow you outside this room."},
		{"speaker_id": "player", "text": "Huh."},
		{"speaker_id": "jisho", "text": "Try picking an upgrade. I recommend special skill damage."},
		{"speaker_id": "jisho", "text": "The bigger the fireball, the cleaner the bones."},
	]
}

const MAKE_70_GOLD_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "Good. You must be feeling stronger already!"},
		{"speaker_id": "jisho", "text": "The rhythm is simple: defeat enemies, earn gold, improve your spells."},
		{"speaker_id": "jisho", "text": "Make some more gold and I'll show you another cool trick."},
	]
}

const BUILD_TOWER_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "Next: towers!"},
		{"speaker_id": "jisho", "text": "Towers can be summoned with magic to help you fight."},
		{"speaker_id": "jisho", "text": "They cost gold, but once built, they give you another way to control the battle."},
		{"speaker_id": "jisho", "text": "Try building an arrow tower."},
	]
}

const CHARGE_TOWER_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "Cool right?! But, a tower is not useful by itself."},
		{"speaker_id": "jisho", "text": "You must charge it with magic before it can activate."},
		{"speaker_id": "jisho", "text": "Type the word shown on the tower to feed it power."},
		{"speaker_id": "jisho", "text": "You have to choose what to focus on, attacking enemies or charging your towers."},
	]
}

const DEFEAT_STRONG_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "Some creatures resist simple magic."},
		{"speaker_id": "jisho", "text": "That means you must type longer or more difficult words to affect them."},
		{"speaker_id": "player", "text": "Oh."},
		{"speaker_id": "jisho", "text": "Should be easy for you, let's try."},
	]
}

const FINAL_DIALOGUE: Dictionary = {
	"speakers": TUTORIAL_SPEAKERS,
	"lines": [
		{"speaker_id": "jisho", "text": "That's about everything."},
		{"speaker_id": "jisho", "text": "There are many different creatures to fight out there."},
		{"speaker_id": "jisho", "text": "As you explore, you may discover new magic, towers, enemies, and stranger things."},
		{"speaker_id": "player", "text": "Huh."},
		{"speaker_id": "jisho", "text": "Do not touch anything glowing unless I say so."},
		{"speaker_id": "jisho", "text": "Feel free to practice here as long as you like."},
		{"speaker_id": "jisho", "text": "You can freely change the word lists for the training dummies in this training room."},
		{"speaker_id": "jisho", "text": "Click the 'Word Lists' button in the top right to see the options."},
		{"speaker_id": "jisho", "text": "Use the menu in the top left to leave the training room when you are ready."},
	]
}

@onready var training_room_level: TrainingRoomLevel = %TrainingRoomLevel

@onready var game_hud: CanvasLayer = %GameHud
@onready var game_menu_overlay: CanvasLayer = %GameMenuOverlay
@onready var shop_overlay: CanvasLayer = %ShopOverlay
@onready var build_overlay: CanvasLayer = %BuildOverlay
@onready var training_word_list_overlay: TrainingWordListOverlay = %TrainingWordListOverlay


@onready var projectile_container: Node = %ProjectileContainer
@onready var typing_manager: Node = %TypingManager
@onready var combat_manager: Node = %CombatManager

@onready var name_input_container: CanvasLayer = %NameInputContainer
@onready var name_input_line: LineEdit = %NameInputLine
@onready var name_okay_button: Button = %NameOkayButton


var current_step: TrainingStep = TrainingStep.INTRO
var run_state: TrainingRunState = TrainingRunState.DIALOGUE
var previous_run_state: TrainingRunState = TrainingRunState.ACTIVE

var selected_training_word_list_ids: Array[String] = ["easy"]

var current_gold: int = 0
var strong_enemies_defeated: int = 0

var is_game_menu_open: bool = false
var is_shop_open: bool = false
var is_build_open: bool = false

var player_character: Node = null


func _ready() -> void:
	_setup_training_room()
	_connect_signals()
	await get_tree().process_frame

	if CampaignProgress != null and CampaignProgress.tutorial_completed:
		_start_free_practice()
	else:
		_start_intro()


func _setup_training_room() -> void:
	get_tree().paused = false

	if training_room_level == null:
		push_error("TrainingRoomGameScreen: Missing %TrainingRoomLevel.")
		return

	player_character = training_room_level.get_player_character()

	if training_room_level.has_method("setup_level"):
		training_room_level.setup_level(projectile_container)

	training_room_level.set_respawn_enabled(false)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.clear_dummies()

	_setup_combat_run()
	_bind_managers_to_level()
	_connect_player_signals()

	_set_word_list_change_button_visible(false)
	name_input_container.visible = false
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

		if combat_manager.has_method("set_replacement_word_provider"):
			combat_manager.set_replacement_word_provider(training_room_level)

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
		
		if game_hud.has_signal("word_list_change_pressed") and not game_hud.word_list_change_pressed.is_connected(_on_word_list_change_button_pressed):
			game_hud.word_list_change_pressed.connect(_on_word_list_change_button_pressed)

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

	if training_room_level != null:
		if training_room_level.has_signal("tower_finished_firing"):
			if not training_room_level.tower_finished_firing.is_connected(_on_training_tower_finished_firing):
				training_room_level.tower_finished_firing.connect(_on_training_tower_finished_firing)
		if training_room_level.has_signal("training_dummy_died"):
			if not training_room_level.training_dummy_died.is_connected(_on_training_dummy_died):
				training_room_level.training_dummy_died.connect(_on_training_dummy_died)

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
	
	if name_okay_button != null:
		if not name_okay_button.pressed.is_connected(_on_name_okay_button_pressed):
			name_okay_button.pressed.connect(_on_name_okay_button_pressed)
		if name_input_line != null:
			if not name_input_line.text_submitted.is_connected(_on_name_input_submitted):
				name_input_line.text_submitted.connect(_on_name_input_submitted)


func _connect_player_signals() -> void:
	if player_character == null or not is_instance_valid(player_character):
		return

	if player_character.has_signal("special_projectile_impact"):
		if not player_character.special_projectile_impact.is_connected(_on_special_projectile_impact):
			player_character.special_projectile_impact.connect(_on_special_projectile_impact)


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




func _set_word_list_change_button_visible(enabled: bool) -> void:
	if game_hud != null and game_hud.has_method("set_word_list_change_button_visible"):
		game_hud.set_word_list_change_button_visible(enabled)


func _on_word_list_change_button_pressed() -> void:
	if current_step != TrainingStep.FREE_PRACTICE:
		return

	_show_training_word_list_overlay()
	


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


func _play_dialogue(dialogue_data: Dictionary) -> void:
	_set_run_state(TrainingRunState.DIALOGUE)

	if training_room_level != null:
		training_room_level.set_respawn_enabled(false)

	if dialogue_data.is_empty():
		push_warning("TrainingRoomGameScreen: dialogue_data was empty.")
		return

	if DIALOGUE_OVERLAY_SCENE == null:
		push_warning("TrainingRoomGameScreen: DIALOGUE_OVERLAY_SCENE is null.")
		return

	var overlay: DialogueOverlay = DIALOGUE_OVERLAY_SCENE.instantiate() as DialogueOverlay

	if overlay == null:
		push_warning("TrainingRoomGameScreen: Dialogue overlay scene does not use DialogueOverlay.")
		return

	add_child(overlay)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	if overlay.has_method("start_from_raw_data"):
		overlay.start_from_raw_data(dialogue_data)
	else:
		push_warning("TrainingRoomGameScreen: DialogueOverlay missing start_from_raw_data().")
		overlay.queue_free()
		return

	await overlay.dialogue_finished



func _start_intro() -> void:
	current_step = TrainingStep.INTRO

	await _play_dialogue(INTRO_DIALOGUE)

	_start_set_name_goal()


func _start_set_name_goal() -> void:
	current_step = TrainingStep.SET_NAME

	_set_goal_text("Goal: Set your name")
	_set_run_state(TrainingRunState.DIALOGUE)

	if name_input_container != null:
		name_input_container.visible = true

	if name_input_line != null:
		name_input_line.text = ""
		name_input_line.placeholder_text = PlayerLoadout.player_name
		name_input_line.grab_focus()
		name_input_line.caret_column = 0


func _on_name_okay_button_pressed() -> void:
	if current_step != TrainingStep.SET_NAME:
		return

	if name_input_line == null:
		return

	var new_name: String = name_input_line.text.strip_edges()

	if new_name.is_empty():
		new_name = name_input_line.placeholder_text.strip_edges()

	if new_name.is_empty():
		new_name = "Spellicus"

	PlayerLoadout.set_player_name(new_name)

	_complete_set_name_goal()


func _on_name_input_submitted(_text: String) -> void:
	_on_name_okay_button_pressed()


func _complete_set_name_goal() -> void:
	if current_step != TrainingStep.SET_NAME:
		return

	if name_input_container != null:
		name_input_container.visible = false

	_start_destroy_one_dummy_goal()


func _start_destroy_one_dummy_goal() -> void:
	current_step = TrainingStep.DESTROY_ONE_DUMMY

	await _play_dialogue(DESTROY_ONE_DUMMY_DIALOGUE)

	_set_goal_text("Goal: Destroy 1 training dummy")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(false)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.spawn_one_dummy()


func _complete_destroy_one_dummy_goal() -> void:
	if current_step != TrainingStep.DESTROY_ONE_DUMMY:
		return

	_start_use_special_goal()


func _start_use_special_goal() -> void:
	current_step = TrainingStep.USE_SPECIAL

	await _play_dialogue(USE_SPECIAL_DIALOGUE)

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
	current_step = TrainingStep.MAKE_50_GOLD

	await _play_dialogue(MAKE_50_GOLD_DIALOGUE)

	_set_goal_text("Goal: Make 50 gold")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.spawn_two_dummies()


func _check_gold_goals() -> void:
	if current_step == TrainingStep.MAKE_50_GOLD:
		if current_gold >= 50:
			_complete_make_gold_goal_a()

	elif current_step == TrainingStep.MAKE_70_GOLD:
		if current_gold >= 70:
			_complete_make_gold_goal_b()


func _complete_make_gold_goal_a() -> void:
	if current_step != TrainingStep.MAKE_50_GOLD:
		return

	_start_buy_upgrade_goal()


func _start_buy_upgrade_goal() -> void:
	current_step = TrainingStep.BUY_UPGRADE

	await _play_dialogue(BUY_UPGRADE_DIALOGUE)

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
	current_step = TrainingStep.MAKE_70_GOLD

	await _play_dialogue(MAKE_70_GOLD_DIALOGUE)

	_set_goal_text("Goal: Make 70 gold")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(["easy"]))
	training_room_level.spawn_two_dummies()


func _complete_make_gold_goal_b() -> void:
	if current_step != TrainingStep.MAKE_70_GOLD:
		return

	_start_build_tower_goal()


func _start_build_tower_goal() -> void:
	current_step = TrainingStep.BUILD_TOWER

	await _play_dialogue(BUILD_TOWER_DIALOGUE)

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

	await _play_dialogue(CHARGE_TOWER_DIALOGUE)

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

	await _play_dialogue(DEFEAT_STRONG_DIALOGUE)

	_set_goal_text("Goal: Defeat 5 strong enemies (0 / 5)")
	_set_run_state(TrainingRunState.ACTIVE)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(["hard"]))
	training_room_level.spawn_two_dummies()


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

	await _play_dialogue(FINAL_DIALOGUE)

	_start_free_practice()


func _start_free_practice() -> void:
	current_step = TrainingStep.FREE_PRACTICE
	selected_training_word_list_ids = ["easy"]

	if CampaignProgress != null:
		CampaignProgress.tutorial_completed = true

	_set_goal_text("Free Practice")
	_set_run_state(TrainingRunState.ACTIVE)
	_set_word_list_change_button_visible(true)

	training_room_level.set_respawn_enabled(true)
	training_room_level.set_word_pool(_get_words_from_list_ids(selected_training_word_list_ids))
	training_room_level.spawn_two_dummies()


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


func _set_goal_text(text: String) -> void:
	if game_hud == null:
		return

	if text.strip_edges().is_empty():
		if game_hud.has_method("clear_goal_text"):
			game_hud.clear_goal_text()
	else:
		if game_hud.has_method("set_goal_text"):
			game_hud.set_goal_text(text)


func _on_training_tower_finished_firing(_slot_id: String) -> void:
	if current_step != TrainingStep.CHARGE_TOWER:
		return
	
	_complete_charge_tower_goal()


func _on_training_dummy_died(_dummy: Node, _marker_id: String) -> void:
	match current_step:
		TrainingStep.DESTROY_ONE_DUMMY:
			_complete_destroy_one_dummy_goal()

		TrainingStep.DEFEAT_5_STRONG:
			_on_strong_dummy_died()
