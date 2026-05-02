# res://scripts/game/campaign_game_screen.gd
class_name CampaignGameScreen
extends BaseGameScreen

var campaign_level_data: CampaignLevelData = null


func _load_run_content() -> void:
	print("[CampaignGameScreen] _load_run_content()")

	campaign_level_data = GameSession.campaign_level_data as CampaignLevelData

	if campaign_level_data == null:
		push_warning("CampaignGameScreen: campaign_level_data was null.")
		return

	if campaign_level_data.level_scene_path.is_empty():
		push_warning("CampaignGameScreen: level_scene_path was empty.")
		return

	var level_scene: PackedScene = load(campaign_level_data.level_scene_path)

	if level_scene == null:
		push_warning("CampaignGameScreen: failed to load level scene: %s" % campaign_level_data.level_scene_path)
		return

	load_level(level_scene)


func _setup_run_mode() -> void:
	print("[CampaignGameScreen] Setting up campaign run.")

	if campaign_level_data == null:
		wave_set = []
		total_waves = 0
		return

	if campaign_level_data.wave_data_script_path.is_empty():
		push_warning("CampaignGameScreen: wave_data_script_path was empty.")
		wave_set = []
		total_waves = 0
		return

	var wave_script: Script = load(campaign_level_data.wave_data_script_path)

	if wave_script == null:
		push_warning("CampaignGameScreen: failed to load wave script: %s" % campaign_level_data.wave_data_script_path)
		wave_set = []
		total_waves = 0
		return

	var wave_data_instance: Variant = wave_script.new()

	if wave_data_instance != null and wave_data_instance.has_method("get_wave_definitions"):
		wave_set = wave_data_instance.get_wave_definitions()
	else:
		push_warning("CampaignGameScreen: wave script missing get_wave_definitions().")
		wave_set = []

	total_waves = wave_set.size()

	if combat_manager != null and combat_manager.has_method("setup_run"):
		combat_manager.setup_run({
			"mode": "campaign",
			"wave_definitions": wave_set,
			"campaign_level_data": campaign_level_data,
			"persistent_upgrade_levels": CampaignProgress.get_upgrade_levels(),
		})

	print("[CampaignGameScreen] Campaign wave_set size = ", wave_set.size())


func _apply_run_upgrades() -> void:
	# Persistent campaign upgrades should be applied through CombatManager.setup_run().
	# Add direct player/tower upgrade application here only if needed later.
	pass


func _on_run_victory() -> void:
	if campaign_level_data != null:
		CampaignProgress.complete_level(campaign_level_data.level_id)

	_set_run_state(RunState.VICTORY)


func _on_run_defeat() -> void:
	_set_run_state(RunState.DEFEAT)


func _should_show_shop_after_wave() -> bool:
	return true

func _get_run_mode_name() -> String:
	return "campaign"
