# res://scripts/game/endless_game_screen.gd
class_name EndlessGameScreen
extends BaseGameScreen

const CASTLE_WALLS_LEVEL_SCENE: PackedScene = preload("uid://na1x8ccn5sat")
const GRASSLANDS_LEVEL_SCENE: PackedScene = preload("uid://d36h1rtkqgva4")
const SEASIDE_FARM_LEVEL_SCENE: PackedScene = preload("uid://bx4vrgw3koyaf")


func _load_run_content() -> void:
	print("[EndlessGameScreen] _load_run_content()")

	var config: EndlessRunConfig = GameSession.endless_run_config

	if config == null:
		push_error("EndlessGameScreen: endless_run_config was null.")
		return

	var level_scene: PackedScene = _get_level_scene_for_map_id(config.map_id)

	if level_scene == null:
		push_error("EndlessGameScreen: No level scene found for map_id: %s" % config.map_id)
		return

	load_level(level_scene)


func _setup_run_mode() -> void:
	print("[EndlessGameScreen] Setting up endless run.")

	var config: EndlessRunConfig = GameSession.endless_run_config

	if config == null:
		push_error("EndlessGameScreen: endless config was null.")
		wave_set = []
		total_waves = 0
		return

	if wave_manager != null and wave_manager.has_method("build_endless_wave_definitions"):
		wave_set = wave_manager.build_endless_wave_definitions(config)
	else:
		push_error("EndlessGameScreen: WaveManager cannot build endless wave definitions.")
		wave_set = []

	total_waves = wave_set.size()

	if total_waves <= 0:
		push_warning("EndlessGameScreen: generated 0 waves. Check enabled enemies and selected word lists.")

	if combat_manager != null and combat_manager.has_method("setup_run"):
		combat_manager.setup_run({
			"mode": "endless",
			"wave_definitions": wave_set,
			"run_config": config,
			"persistent_upgrade_levels": {
				"word_damage": 0,
				"special_damage": 0,
				"special_meter_gain": 0,
				"gold_gain": 0,
			},
		})

	print("[EndlessGameScreen] Map ID: ", config.map_id)
	print("[EndlessGameScreen] Enemy groups: ", config.enabled_enemy_groups)
	print("[EndlessGameScreen] Word lists: ", config.selected_word_list_ids)
	print("[EndlessGameScreen] Endless waves generated: ", total_waves)


func _get_level_scene_for_map_id(map_id: String) -> PackedScene:
	match map_id:
		"castle_walls":
			return CASTLE_WALLS_LEVEL_SCENE
		"grasslands":
			return GRASSLANDS_LEVEL_SCENE
		"seaside_farm":
			return SEASIDE_FARM_LEVEL_SCENE
		_:
			return null


func _get_run_mode_name() -> String:
	return "endless"
	

func _apply_run_upgrades() -> void:
	pass


func _on_run_victory() -> void:
	_set_run_state(RunState.VICTORY)


func _on_run_defeat() -> void:
	_set_run_state(RunState.DEFEAT)


func _should_show_shop_after_wave() -> bool:
	return true
