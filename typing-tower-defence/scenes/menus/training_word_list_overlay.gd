# res://scripts/ui/training/training_word_list_overlay.gd
class_name TrainingWordListOverlay
extends CanvasLayer

signal word_pool_changed(words: Array[String], selected_list_ids: Array[String])
signal close_requested

const WORD_LIST_BUTTON_STYLE: StyleBox = preload("uid://bmr1ksc4wvr2x")
const WORD_LIST_BUTTON_FONT: Font = preload("uid://bxnlee350xbyr")
const WORD_LIST_BUTTON_STYLE_HOVER: StyleBox = preload("uid://c5u114ergurlo")
const WORD_LIST_BUTTON_STYLE_SELECTED: StyleBox = preload("uid://b0atmd5c8kiuy")

const WORD_LIST_BUTTON_HOVER_SCALE: Vector2 = Vector2(1.04, 1.04)
const WORD_LIST_BUTTON_NORMAL_SCALE: Vector2 = Vector2.ONE

@export var word_list_grid_columns: int = 3
@export var word_list_button_size: Vector2 = Vector2(100, 80)
@export var detail_word_columns: int = 4

@export var button_font: Font = WORD_LIST_BUTTON_FONT
@export var button_font_size: int = 14
@export var button_font_color: Color = Color.BLACK

@onready var word_list_scroll: ScrollContainer = %WordListScroll
@onready var word_list_grid: GridContainer = %WordListGrid

@onready var enable_all_button: Button = %EnableAllButton
@onready var disable_all_button: Button = %DisableAllButton
@onready var close_button: Button = %CloseButton

@onready var total_words_count: Label = %TotalWordsCount
@onready var included_lists_label: RichTextLabel = %IncludedListsLabel

@onready var detail_name_label: Label = %DetailNameLabel
@onready var detail_count_label: Label = %DetailCountLabel
@onready var detail_words_text: RichTextLabel = %DetailWordsText

@onready var animation_player: AnimationPlayer = %AnimationPlayer

var selected_list_ids: Array[String] = []
var _focused_list_id: String = ""
var _word_list_buttons_by_id: Dictionary = {}
var _is_closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_setup_layout()
	_connect_signals()
	_build_word_list_grid()
	_refresh_all()


func open_overlay(starting_selected_ids: Array[String]) -> void:
	_is_closing = false
	selected_list_ids = starting_selected_ids.duplicate()

	if selected_list_ids.is_empty():
		selected_list_ids.append("easy")

	if _focused_list_id.is_empty() and not selected_list_ids.is_empty():
		_focused_list_id = selected_list_ids[0]

	visible = true
	_set_buttons_disabled(false)
	_refresh_all()

	if animation_player != null and animation_player.has_animation("open_menu"):
		animation_player.play("open_menu")


func close_overlay() -> void:
	if _is_closing:
		return

	_is_closing = true
	_set_buttons_disabled(true)

	if animation_player != null and animation_player.has_animation("close_menu"):
		animation_player.play("close_menu")
		await animation_player.animation_finished

	visible = false
	_set_buttons_disabled(false)
	close_requested.emit()


func _setup_layout() -> void:
	if word_list_scroll != null:
		word_list_scroll.clip_contents = true
		word_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		word_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if word_list_grid != null:
		word_list_grid.columns = word_list_grid_columns
		word_list_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		word_list_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		word_list_grid.clip_contents = false

	if included_lists_label != null:
		included_lists_label.fit_content = true
		included_lists_label.scroll_active = true
		included_lists_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		included_lists_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if detail_words_text != null:
		detail_words_text.bbcode_enabled = false
		detail_words_text.fit_content = false
		detail_words_text.scroll_active = true
		detail_words_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_words_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		detail_words_text.visible = true


func _connect_signals() -> void:
	if close_button != null and not close_button.pressed.is_connected(close_overlay):
		close_button.pressed.connect(close_overlay)

	if enable_all_button != null and not enable_all_button.pressed.is_connected(_on_enable_all_pressed):
		enable_all_button.pressed.connect(_on_enable_all_pressed)

	if disable_all_button != null and not disable_all_button.pressed.is_connected(_on_disable_all_pressed):
		disable_all_button.pressed.connect(_on_disable_all_pressed)


func _build_word_list_grid() -> void:
	_clear_word_list_grid()
	_word_list_buttons_by_id.clear()

	if word_list_grid == null:
		return

	word_list_grid.columns = word_list_grid_columns

	var lists: Array[WordListData] = _get_sorted_word_lists()

	for list_data in lists:
		if list_data == null:
			continue

		var button := Button.new()

		button.custom_minimum_size = word_list_button_size
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pivot_offset = word_list_button_size * 0.5
		button.text = _get_word_list_button_text(list_data)

		button.mouse_entered.connect(_on_word_list_button_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_word_list_button_mouse_exited.bind(button))
		button.pressed.connect(_on_word_list_pressed.bind(list_data.id))

		word_list_grid.add_child(button)
		_word_list_buttons_by_id[list_data.id] = button


func _get_sorted_word_lists() -> Array[WordListData]:
	var all_lists: Array[WordListData] = WordLists.get_all_lists()

	var custom_lists: Array[WordListData] = []
	var priority_lists: Array[WordListData] = []
	var remaining_builtin_lists: Array[WordListData] = []

	for list_data in all_lists:
		if list_data == null:
			continue

		if list_data.is_custom:
			custom_lists.append(list_data)
		elif _is_priority_builtin_list(list_data):
			priority_lists.append(list_data)
		else:
			remaining_builtin_lists.append(list_data)

	custom_lists.sort_custom(_sort_by_display_name)
	priority_lists.sort_custom(_sort_priority_lists)
	remaining_builtin_lists.sort_custom(_sort_by_display_name)

	var sorted_lists: Array[WordListData] = []
	sorted_lists.append_array(custom_lists)
	sorted_lists.append_array(priority_lists)
	sorted_lists.append_array(remaining_builtin_lists)

	return sorted_lists


func _is_priority_builtin_list(list_data: WordListData) -> bool:
	return list_data.id == "easy" or list_data.id == "medium" or list_data.id == "hard"


func _sort_priority_lists(a: WordListData, b: WordListData) -> bool:
	return _get_priority_rank(a.id) < _get_priority_rank(b.id)


func _get_priority_rank(list_id: String) -> int:
	match list_id:
		"easy":
			return 0
		"medium":
			return 1
		"hard":
			return 2
		_:
			return 999


func _sort_by_display_name(a: WordListData, b: WordListData) -> bool:
	return a.display_name.naturalnocasecmp_to(b.display_name) < 0


func _clear_word_list_grid() -> void:
	if word_list_grid == null:
		return

	for child in word_list_grid.get_children():
		child.queue_free()


func _on_word_list_pressed(list_id: String) -> void:
	if _is_closing:
		return

	_focused_list_id = list_id
	_toggle_word_list(list_id)
	_emit_word_pool_changed()


func _toggle_word_list(list_id: String) -> void:
	var idx: int = selected_list_ids.find(list_id)

	if idx == -1:
		selected_list_ids.append(list_id)
	else:
		selected_list_ids.remove_at(idx)

	_refresh_all()


func _on_enable_all_pressed() -> void:
	if _is_closing:
		return

	selected_list_ids.clear()

	var lists: Array[WordListData] = _get_sorted_word_lists()

	for list_data in lists:
		if list_data == null:
			continue

		selected_list_ids.append(list_data.id)

	if _focused_list_id.is_empty() and not selected_list_ids.is_empty():
		_focused_list_id = selected_list_ids[0]

	_refresh_all()
	_emit_word_pool_changed()


func _on_disable_all_pressed() -> void:
	if _is_closing:
		return

	selected_list_ids.clear()
	_refresh_all()
	_emit_word_pool_changed()


func _refresh_all() -> void:
	_refresh_word_list_button_states()
	_refresh_word_list_summary()
	_refresh_detail_panel()


func _refresh_word_list_button_states() -> void:
	for list_id in _word_list_buttons_by_id.keys():
		var button: Button = _word_list_buttons_by_id[list_id]
		var list_data: WordListData = WordLists.get_list(list_id)

		if button == null or list_data == null:
			continue

		var is_selected: bool = selected_list_ids.has(list_id)

		button.text = _get_word_list_button_text(list_data)
		button.button_pressed = is_selected

		_apply_word_list_button_style(button, is_selected)


func _refresh_word_list_summary() -> void:
	var total_words: int = 0
	var selected_names: Array[String] = []

	for list_id in selected_list_ids:
		var list_data: WordListData = WordLists.get_list(str(list_id))

		if list_data == null:
			continue

		total_words += list_data.words.size()
		selected_names.append(list_data.display_name)

	if total_words_count != null:
		total_words_count.text = "%d words included" % total_words

	if included_lists_label != null:
		included_lists_label.clear()

		if selected_names.is_empty():
			included_lists_label.text = "No word lists selected."
		else:
			included_lists_label.text = ", ".join(selected_names)


func _refresh_detail_panel() -> void:
	var list_data: WordListData = WordLists.get_list(_focused_list_id)

	if list_data == null:
		if detail_name_label != null:
			detail_name_label.text = "No List Selected"

		if detail_count_label != null:
			detail_count_label.text = ""

		if detail_words_text != null:
			detail_words_text.text = ""

		return

	if detail_name_label != null:
		detail_name_label.text = list_data.display_name

	if detail_count_label != null:
		detail_count_label.text = "%d words" % list_data.words.size()

	if detail_words_text != null:
		detail_words_text.clear()
		detail_words_text.text = _build_word_grid_text(list_data.words)


func _build_word_grid_text(words: Array[String]) -> String:
	var columns: int = max(1, detail_word_columns)
	var rows: Array[String] = []
	var current_row: Array[String] = []

	for i in words.size():
		current_row.append(str(words[i]))

		var row_full: bool = current_row.size() >= columns
		var is_last_word: bool = i == words.size() - 1

		if row_full or is_last_word:
			rows.append("    ".join(current_row))
			current_row.clear()

	return "\n".join(rows)


func _build_selected_word_pool() -> Array[String]:
	var words: Array[String] = []
	var seen_words: Dictionary = {}

	for list_id in selected_list_ids:
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


func _emit_word_pool_changed() -> void:
	word_pool_changed.emit(_build_selected_word_pool(), selected_list_ids.duplicate())


func _get_word_list_button_text(list_data: WordListData) -> String:
	return "%s\n(%d)" % [
		list_data.display_name,
		list_data.words.size(),
	]


func _apply_word_list_button_style(button: Button, is_selected: bool) -> void:
	if button == null:
		return

	var base_style: StyleBox = WORD_LIST_BUTTON_STYLE_SELECTED if is_selected else WORD_LIST_BUTTON_STYLE
	var hover_style: StyleBox = WORD_LIST_BUTTON_STYLE_SELECTED if is_selected else WORD_LIST_BUTTON_STYLE_HOVER

	button.add_theme_stylebox_override("normal", base_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", WORD_LIST_BUTTON_STYLE_SELECTED)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", WORD_LIST_BUTTON_STYLE)

	if button_font != null:
		button.add_theme_font_override("font", button_font)

	button.add_theme_font_size_override("font_size", button_font_size)

	button.add_theme_color_override("font_color", button_font_color)
	button.add_theme_color_override("font_hover_color", button_font_color)
	button.add_theme_color_override("font_pressed_color", button_font_color)
	button.add_theme_color_override("font_focus_color", button_font_color)
	button.add_theme_color_override("font_hover_pressed_color", button_font_color)
	button.add_theme_color_override("font_disabled_color", button_font_color)


func _on_word_list_button_mouse_entered(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return

	button.z_index = 10
	var tween := create_tween()
	tween.tween_property(button, "scale", WORD_LIST_BUTTON_HOVER_SCALE, 0.08)


func _on_word_list_button_mouse_exited(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return

	button.z_index = 0
	var tween := create_tween()
	tween.tween_property(button, "scale", WORD_LIST_BUTTON_NORMAL_SCALE, 0.08)


func _set_buttons_disabled(disabled: bool) -> void:
	if close_button != null:
		close_button.disabled = disabled

	if enable_all_button != null:
		enable_all_button.disabled = disabled

	if disable_all_button != null:
		disable_all_button.disabled = disabled

	for button in _word_list_buttons_by_id.values():
		if button != null and is_instance_valid(button):
			button.disabled = disabled
