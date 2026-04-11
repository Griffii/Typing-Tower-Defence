extends Control

signal selection_finished
signal back_requested

const GRASSLANDS_SCENE: PackedScene = preload("res://scenes/game/levels/grasslands.tscn")
const SEASIDE_FARM_SCENE: PackedScene = preload("res://scenes/game/levels/seaside_farm.tscn")
const WAVE_SET_01 = preload("res://data/waves/wave_set_01.gd")
const WAVE_SET_SLIME_01 = preload("res://data/waves/wave_set_slime_01.gd")

@onready var grasslands_button: Button = %GrasslandsButton
@onready var seaside_farm_button: Button = %SeasideFarmButton
@onready var wave_set_01_button: Button = %SoldiersButton
@onready var slime_wave_button: Button = %SlimesButton
@onready var back_button: Button = %BackButton
@onready var finish_button: Button = %FinishButton

@onready var level_select_label: RichTextLabel = %LevelSelectLabel
@onready var enemy_select_label: RichTextLabel = %EnemySelectLabel

var level_button_group: ButtonGroup
var enemy_button_group: ButtonGroup


func _ready() -> void:
	_setup_button_groups()
	_connect_signals()
	_update_finish_button_state()

	var wave_effect := WaveTextEffect.new()
	level_select_label.install_effect(wave_effect)
	enemy_select_label.install_effect(wave_effect)

	level_select_label.text = "[center][wave height=8 speed=2.2 spacing=0.45]Pick a level:[/wave][/center]"
	enemy_select_label.text = "[center][wave height=8 speed=2.2 spacing=0.45]Pick an enemy type:[/wave][/center]"


func _setup_button_groups() -> void:
	level_button_group = ButtonGroup.new()
	enemy_button_group = ButtonGroup.new()

	if grasslands_button != null:
		grasslands_button.toggle_mode = true
		grasslands_button.button_group = level_button_group

	if seaside_farm_button != null:
		seaside_farm_button.toggle_mode = true
		seaside_farm_button.button_group = level_button_group

	if wave_set_01_button != null:
		wave_set_01_button.toggle_mode = true
		wave_set_01_button.button_group = enemy_button_group

	if slime_wave_button != null:
		slime_wave_button.toggle_mode = true
		slime_wave_button.button_group = enemy_button_group


func _connect_signals() -> void:
	if grasslands_button != null and not grasslands_button.pressed.is_connected(_on_grasslands_pressed):
		grasslands_button.pressed.connect(_on_grasslands_pressed)

	if seaside_farm_button != null and not seaside_farm_button.pressed.is_connected(_on_seasidefarm_pressed):
		seaside_farm_button.pressed.connect(_on_seasidefarm_pressed)

	if wave_set_01_button != null and not wave_set_01_button.pressed.is_connected(_on_wave_set_01_pressed):
		wave_set_01_button.pressed.connect(_on_wave_set_01_pressed)

	if slime_wave_button != null and not slime_wave_button.pressed.is_connected(_on_slime_wave_pressed):
		slime_wave_button.pressed.connect(_on_slime_wave_pressed)

	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	if finish_button != null and not finish_button.pressed.is_connected(_on_finish_pressed):
		finish_button.pressed.connect(_on_finish_pressed)


func _update_finish_button_state() -> void:
	if finish_button == null:
		return

	var level_selected := level_button_group != null and level_button_group.get_pressed_button() != null
	var enemy_selected := enemy_button_group != null and enemy_button_group.get_pressed_button() != null

	finish_button.disabled = not (level_selected and enemy_selected)


func _on_grasslands_pressed() -> void:
	GameSelection.set_level_scene(GRASSLANDS_SCENE)
	_update_finish_button_state()


func _on_seasidefarm_pressed() -> void:
	GameSelection.set_level_scene(SEASIDE_FARM_SCENE)
	_update_finish_button_state()


func _on_wave_set_01_pressed() -> void:
	GameSelection.set_wave_set_script(WAVE_SET_01)
	_update_finish_button_state()


func _on_slime_wave_pressed() -> void:
	GameSelection.set_wave_set_script(WAVE_SET_SLIME_01)
	_update_finish_button_state()


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_finish_pressed() -> void:
	if finish_button != null and finish_button.disabled:
		return

	selection_finished.emit()
