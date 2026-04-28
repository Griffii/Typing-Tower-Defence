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

@onready var upload_csv_button: Button = %UploadCSVButton
@onready var back_button: Button = %BackButton
@onready var file_dialog: FileDialog = %FileDialog

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
	if upload_csv_button != null and not upload_csv_button.pressed.is_connected(_on_upload_csv_pressed):
		upload_csv_button.pressed.connect(_on_upload_csv_pressed)

	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	
	if delete_list_button != null and not delete_list_button.pressed.is_connected(_on_delete_list_pressed):
		delete_list_button.pressed.connect(_on_delete_list_pressed)

	if file_dialog != null and not file_dialog.file_selected.is_connected(_on_file_selected):
		file_dialog.file_selected.connect(_on_file_selected)

	if file_dialog != null:
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.filters = PackedStringArray(["*.csv ; CSV Files"])


func _build_word_list_grid() -> void:
	_clear_word_list_grid()
	_word_list_buttons_by_id.clear()

	if word_list_grid == null:
		return

	word_list_grid.columns = word_list_grid_columns

	var lists: Array[WordListData] = WordLists.get_all_lists()

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


func _make_custom_list_id_from_path(path: String) -> String:
	var file_name: String = path.get_file().get_basename()
	return "custom_%s" % file_name


func _make_custom_display_name_from_path(path: String) -> String:
	return path.get_file().get_basename()


func _on_word_list_pressed(list_id: String) -> void:
	if _focused_list_id == list_id:
		return
	_focused_list_id = list_id
	_refresh_word_list_button_states()
	_refresh_detail_panel()


func _on_upload_csv_pressed() -> void:
	if file_dialog == null:
		return

	file_dialog.popup_centered_ratio(0.7)


func _on_file_selected(path: String) -> void:
	var list_id: String = _make_custom_list_id_from_path(path)
	var display_name: String = _make_custom_display_name_from_path(path)

	var ok: bool = WordLists.import_csv_as_temporary_list(path, list_id, display_name, "custom")
	if not ok:
		push_warning("WordListViewMenu: failed to import custom CSV: %s" % path)
		return

	_focused_list_id = list_id
	_build_word_list_grid()
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

func _on_back_pressed() -> void:
	back_requested.emit()
