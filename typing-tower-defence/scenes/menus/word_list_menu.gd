extends Control

signal back_requested

@export var word_list_grid_columns: int = 3
@export var word_list_button_size: Vector2 = Vector2(100, 80)
@export var detail_word_columns: int = 4

@export var word_list_button_normal: StyleBox
@export var word_list_button_hover: StyleBox
@export var word_list_button_pressed: StyleBox
@export var word_list_button_focused: StyleBox

@onready var word_list_scroll: ScrollContainer = %WordListScroll
@onready var word_list_grid: GridContainer = %WordListGrid

@onready var add_new_word_list_button: Button = %AddNewWordListButton
@onready var add_word_list_popup: PopupPanel = %AddWordListPopup

@onready var back_button: Button = %BackButton

@onready var detail_name_label: Label = %DetailNameLabel
@onready var detail_count_label: Label = %DetailCountLabel
@onready var detail_words_text: RichTextLabel = %DetailWordsText
@onready var delete_list_button: Button = %DeleteListButton

var _focused_list_id: String = ""
var _word_list_buttons_by_id: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_setup_layout()
	_connect_signals()
	_build_word_list_grid()
	_refresh_detail_panel()


func _setup_layout() -> void:
	if word_list_scroll != null:
		word_list_scroll.clip_contents = true
		word_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		word_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		word_list_scroll.custom_minimum_size = Vector2(400, 300)

	if word_list_grid != null:
		word_list_grid.columns = word_list_grid_columns
		word_list_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		word_list_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if detail_words_text != null:
		detail_words_text.bbcode_enabled = false
		detail_words_text.fit_content = false
		detail_words_text.scroll_active = true
		detail_words_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_words_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		detail_words_text.custom_minimum_size = Vector2(420, 300)
		detail_words_text.visible = true


func _connect_signals() -> void:
	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	if delete_list_button != null and not delete_list_button.pressed.is_connected(_on_delete_list_pressed):
		delete_list_button.pressed.connect(_on_delete_list_pressed)

	if add_new_word_list_button != null and not add_new_word_list_button.pressed.is_connected(_on_add_new_word_list_pressed):
		add_new_word_list_button.pressed.connect(_on_add_new_word_list_pressed)

	if add_word_list_popup != null and add_word_list_popup.has_signal("word_list_created"):
		if not add_word_list_popup.word_list_created.is_connected(_on_word_list_created):
			add_word_list_popup.word_list_created.connect(_on_word_list_created)


func _build_word_list_grid() -> void:
	_clear_word_list_grid()
	_word_list_buttons_by_id.clear()

	if word_list_grid == null:
		return

	word_list_grid.columns = word_list_grid_columns

	var lists: Array[WordListData] = _get_sorted_word_lists()

	for list_data in lists:
		var button := Button.new()
		button.custom_minimum_size = word_list_button_size
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = false
		button.text = list_data.display_name

		_apply_word_list_button_style(button)

		button.pressed.connect(_on_word_list_pressed.bind(list_data.id))

		word_list_grid.add_child(button)
		_word_list_buttons_by_id[list_data.id] = button

	_refresh_word_list_button_states()
	_refresh_detail_panel()


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


func _apply_word_list_button_style(button: Button) -> void:
	if button == null:
		return

	if word_list_button_normal != null:
		button.add_theme_stylebox_override("normal", word_list_button_normal)

	if word_list_button_hover != null:
		button.add_theme_stylebox_override("hover", word_list_button_hover)

	if word_list_button_pressed != null:
		button.add_theme_stylebox_override("pressed", word_list_button_pressed)

	if word_list_button_focused != null:
		button.add_theme_stylebox_override("focus", word_list_button_focused)


func _refresh_word_list_button_states() -> void:
	for list_id in _word_list_buttons_by_id.keys():
		var button: Button = _word_list_buttons_by_id[list_id]
		var list_data: WordListData = WordLists.get_list(list_id)

		if button == null or list_data == null:
			continue

		var is_focused: bool = _focused_list_id == list_id

		button.text = list_data.display_name
		button.button_pressed = false

		if is_focused:
			button.modulate = Color(0.9, 0.9, 1.0, 1.0)
		else:
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _refresh_detail_panel() -> void:
	var list_data: WordListData = WordLists.get_list(_focused_list_id)

	if list_data == null:
		detail_name_label.text = "No List Selected"
		detail_count_label.text = ""
		detail_words_text.text = ""

		if delete_list_button != null:
			delete_list_button.visible = false

		return

	detail_name_label.text = list_data.display_name
	detail_count_label.text = "%d words" % list_data.words.size()
	detail_words_text.clear()
	detail_words_text.text = _build_word_grid_text(list_data.words)

	if delete_list_button != null:
		delete_list_button.visible = list_data.is_custom


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


func _on_word_list_pressed(list_id: String) -> void:
	if _focused_list_id == list_id:
		return

	_focused_list_id = list_id
	_refresh_word_list_button_states()
	_refresh_detail_panel()


func _on_delete_list_pressed() -> void:
	if _focused_list_id.is_empty():
		return

	var list_data: WordListData = WordLists.get_list(_focused_list_id)
	if list_data == null:
		return

	if not list_data.is_custom:
		return

	var deleted: bool = false

	if WordLists.has_method("delete_custom_list"):
		deleted = WordLists.delete_custom_list(_focused_list_id)

	if not deleted:
		push_warning("WordListViewMenu: failed to delete custom list: %s" % _focused_list_id)
		return

	_focused_list_id = ""
	_build_word_list_grid()
	_refresh_word_list_button_states()
	_refresh_detail_panel()


func _on_add_new_word_list_pressed() -> void:
	if add_word_list_popup == null:
		return

	if add_word_list_popup.has_method("open_popup"):
		add_word_list_popup.open_popup()
	else:
		add_word_list_popup.popup_centered_ratio(0.65)


func _on_word_list_created(list_id: String) -> void:
	_focused_list_id = list_id
	_build_word_list_grid()
	_refresh_word_list_button_states()
	_refresh_detail_panel()


func _on_back_pressed() -> void:
	back_requested.emit()
