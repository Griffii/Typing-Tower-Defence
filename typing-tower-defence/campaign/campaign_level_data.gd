# res://resources/campaign/campaign_level_data.gd
class_name CampaignLevelData
extends Resource

@export var level_id: String = ""
@export var display_name: String = ""
@export var level_order: int = 0

@export var required_level_id: String = ""

@export_file("*.tscn") var level_scene_path: String = ""
@export_file("*.gd") var wave_data_script_path: String = ""

@export var enemy_families: Array[String] = []

@export_file("*.tscn") var intro_cutscene_scene_path: String = ""
@export_file("*.tscn") var outro_cutscene_scene_path: String = ""
