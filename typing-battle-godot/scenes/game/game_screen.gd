extends Control

signal back_to_menu_requested

enum RunState {
	PRE_WAVE,
	COUNTDOWN,
	WAVE_ACTIVE,
	SHOP,
	VICTORY,
	DEFEAT
}

const DEFAULT_WAVE_SET = preload("res://data/waves/wave_set_01.gd")

@onready var game_hud: CanvasLayer = %GameHud
@onready var countdown_overlay: CanvasLayer = %CountdownOverlay
@onready var game_over_overlay: CanvasLayer = %GameOverOverlay
@onready var game_menu_overlay: CanvasLayer = %GameMenuOverlay

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


func _ready() -> void:
	_connect_signals()
	_load_default_wave_set()
	_reset_run()


func setup_run(run_config: Dictionary) -> void:
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
		if combat_manager.has_signal("soldier_meter_changed"):
			combat_manager.soldier_meter_changed.connect(_on_soldier_meter_changed)

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

	get_tree().paused = false

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

	_set_run_state(RunState.PRE_WAVE)
	_refresh_wave_ui()
	_on_hud_stats_changed({
		"score": 0,
		"gold": 0,
		"base_hp": 0,
		"base_hp_max": 0
	})
	_on_soldier_meter_changed(0.0, 100.0)


func _set_run_state(new_state: RunState) -> void:
	run_state = new_state

	match run_state:
		RunState.PRE_WAVE:
			_disable_typing()
			_show_start_wave_button("Start Wave")
			_set_status_text("Press Start Wave when ready.")

		RunState.COUNTDOWN:
			_disable_typing()
			_hide_start_wave_button()
			_set_status_text("Get ready...")

		RunState.WAVE_ACTIVE:
			_enable_typing()
			_hide_start_wave_button()
			_set_status_text("Wave %d in progress." % (current_wave_index + 1))

		RunState.SHOP:
			_disable_typing()
			_show_start_wave_button("Start Next Wave")
			_set_status_text("Wave cleared.")

		RunState.VICTORY:
			_disable_typing()
			_hide_start_wave_button()
			_set_status_text("Victory.")
			_show_game_over(true)

		RunState.DEFEAT:
			_disable_typing()
			_hide_start_wave_button()
			_set_status_text("Defeat.")
			_show_game_over(false)


func _refresh_wave_ui() -> void:
	if game_hud != null and game_hud.has_method("set_wave_text"):
		game_hud.set_wave_text(current_wave_index + 1, max(1, total_waves))


func _on_start_wave_pressed() -> void:
	if not run_active:
		return

	if is_game_menu_open:
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

	if is_game_menu_open:
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

	if game_hud.has_method("set_score"):
		game_hud.set_score(int(stats.get("score", 0)))

	if game_hud.has_method("set_gold"):
		game_hud.set_gold(int(stats.get("gold", 0)))

	if game_hud.has_method("set_base_hp"):
		game_hud.set_base_hp(int(stats.get("base_hp", 0)), int(stats.get("base_hp_max", 0)))


func _on_soldier_meter_changed(current_value: float, max_value: float) -> void:
	if game_hud != null and game_hud.has_method("set_soldier_meter"):
		game_hud.set_soldier_meter(current_value, max_value)


func _show_game_over(did_win: bool) -> void:
	get_tree().paused = true

	if game_over_overlay == null:
		return

	if game_over_overlay.has_method("show_results"):
		game_over_overlay.show_results({
			"did_win": did_win,
			"wave_reached": current_wave_index,
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
