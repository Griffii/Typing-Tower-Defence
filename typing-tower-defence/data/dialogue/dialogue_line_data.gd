# res://scripts/data/dialogue/dialogue_line_data.gd
class_name DialogueLineData
extends Resource

@export var speaker_id: String = ""
@export var display_name_override: String = ""
@export_multiline var text: String = ""

@export_enum("left", "center", "right") var position_override: String = ""
@export var expression: String = ""
@export var animation_name: String = ""
@export var wait_after_seconds: float = 0.0

@export var add_speakers: Array[String] = []
@export var remove_speakers: Array[String] = []
@export var move_speakers: Dictionary = {}
@export var flip_speakers: Dictionary = {}
@export var focus_speaker_id: String = ""

@export var sfx_id: String = ""
