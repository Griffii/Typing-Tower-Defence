extends Node

enum RunMode {
	LEGACY,
	ENDLESS,
	CAMPAIGN
}

var run_mode: RunMode = RunMode.LEGACY
var endless_run_config: EndlessRunConfig = null
var campaign_level_data: Resource = null


func setup_endless(config: EndlessRunConfig) -> void:
	run_mode = RunMode.ENDLESS
	endless_run_config = config
	campaign_level_data = null


func setup_campaign(level_data: Resource) -> void:
	run_mode = RunMode.CAMPAIGN
	campaign_level_data = level_data
	endless_run_config = null


func setup_legacy() -> void:
	run_mode = RunMode.LEGACY
	endless_run_config = null
	campaign_level_data = null
