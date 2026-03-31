extends Control

signal back_to_menu_requested
signal play_again_requested

@onready var title_label: Label = %TitleLabel
@onready var result_label: Label = %ResultLabel
@onready var summary_label: Label = %SummaryLabel

@onready var left_stats_title: Label = %LeftStatsTitle
@onready var left_words_label: Label = %LeftWordsLabel
@onready var left_words_list: RichTextLabel = %LeftWordsList

@onready var right_stats_title: Label = %RightStatsTitle
@onready var right_words_label: Label = %RightWordsLabel
@onready var right_words_list: RichTextLabel = %RightWordsList

@onready var back_to_menu_button: Button = %BackToMenuButton
@onready var play_again_button: Button = %PlayAgainButton
@onready var waiting_label: Label = %WaitingLabel

var rematch_locked: bool = false
var opponent_left: bool = false

func _ready() -> void:
	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)

	title_label.text = "Game Over"
	result_label.text = ""
	summary_label.text = ""

	left_stats_title.text = "Left Player"
	left_words_label.text = "Words Typed"
	left_words_list.text = ""

	right_stats_title.text = "Right Player"
	right_words_label.text = "Words Typed"
	right_words_list.text = ""

	waiting_label.text = ""
	visible = false


func show_results(data: Dictionary) -> void:
	visible = true
	rematch_locked = false
	waiting_label.text = ""

	var did_win: bool = bool(data.get("did_win", false))
	var game_length_seconds: float = float(data.get("game_length_seconds", 0.0))

	if did_win:
		result_label.text = "You Win!"
	else:
		result_label.text = "You Lose"

	var minutes: int = int(game_length_seconds) / 60
	var seconds: int = int(game_length_seconds) % 60
	summary_label.text = "Game Length: %02d:%02d" % [minutes, seconds]

	var left_data_raw: Variant = data.get("left_player", {})
	var right_data_raw: Variant = data.get("right_player", {})

	if typeof(left_data_raw) == TYPE_DICTIONARY:
		_apply_player_block(
			left_stats_title,
			left_words_list,
			left_data_raw as Dictionary,
			"Left Player"
		)

	if typeof(right_data_raw) == TYPE_DICTIONARY:
		_apply_player_block(
			right_stats_title,
			right_words_list,
			right_data_raw as Dictionary,
			"Right Player"
		)

	if opponent_left:
		play_again_button.disabled = true
		waiting_label.text = "Other player left the session."
	else:
		play_again_button.disabled = false


func set_waiting_for_rematch(is_waiting: bool) -> void:
	if opponent_left:
		play_again_button.disabled = true
		waiting_label.text = "Other player left the session."
		return

	if is_waiting:
		waiting_label.text = "Waiting for other player..."
	else:
		waiting_label.text = ""


func set_both_players_ready() -> void:
	if opponent_left:
		play_again_button.disabled = true
		waiting_label.text = "Other player left the session."
		return

	waiting_label.text = "Both players ready."


func set_opponent_left() -> void:
	opponent_left = true
	play_again_button.disabled = true
	waiting_label.text = "Other player left the session."


func hide_overlay() -> void:
	visible = false
	waiting_label.text = ""
	play_again_button.disabled = false
	rematch_locked = false
	opponent_left = false


func _apply_player_block(
	title_node: Label,
	list_node: RichTextLabel,
	player_data: Dictionary,
	default_title: String
) -> void:
	var display_name: String = String(player_data.get("title", default_title))
	title_node.text = display_name

	list_node.text = ""

	var entries_raw: Variant = player_data.get("entries", [])
	if typeof(entries_raw) != TYPE_ARRAY:
		list_node.text = "No data."
		return

	var entries: Array = entries_raw
	if entries.is_empty():
		list_node.text = "No words typed."
		return

	var lines: PackedStringArray = []

	for entry_raw in entries:
		if typeof(entry_raw) == TYPE_DICTIONARY:
			var entry: Dictionary = entry_raw as Dictionary
			lines.append(String(entry.get("word", "")))
		else:
			lines.append(String(entry_raw))

	list_node.text = "\n".join(lines)


func _on_back_to_menu_pressed() -> void:
	back_to_menu_requested.emit()


func _on_play_again_pressed() -> void:
	if rematch_locked or opponent_left:
		return

	rematch_locked = true
	play_again_button.disabled = true
	waiting_label.text = "Waiting for other player..."
	play_again_requested.emit()
