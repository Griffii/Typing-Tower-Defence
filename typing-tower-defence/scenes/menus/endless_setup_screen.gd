extends Control

const AVAILABLE_MAP_IDS: Array[String] = [
	"grasslands",
	"seaside_farm",
]

const AVAILABLE_ENEMY_GROUPS: Array[String] = [
	"soldiers",
	"slimes",
]

const ENEMY_GROUP_TO_TYPES := {
	"soldiers": ["grunt", "scout", "tank", "boss"],
	"slimes": ["slime", "slime_boss"],
}

@onready var map_option_button: OptionButton = %MapOptionButton

@onready var soldiers_check_box: CheckBox = %SoldiersCheckBox
@onready var slimes_check_box: CheckBox = %SlimesCheckBox

@onready var enable_all_button: Button = %EnableAllButton
@onready var disable_all_button: Button = %DisableAllButton
@onready var upload_csv_button: Button = %UploadCSVButton

@onready var word_list_grid: GridContainer = %WordListGrid

@onready var detail_name_label: Label = %DetailNameLabel
@onready var detail_category_label: Label = %DetailCategoryLabel
@onready var detail_count_label: Label = %DetailCountLabel
@onready var detail_words_text: RichTextLabel = %DetailWordsText

@onready var summary_label: Label = %SummaryLabel
@onready var back_button: Button = %BackButton
@onready var start_button: Button = %StartButton

@onready var file_dialog: FileDialog = %FileDialog

var run_config: EndlessRunConfig
var _focused_list_id: String = ""
var _word_list_buttons_by_id: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_create_or_reset_config()
	_build_map_options()
	_connect_ui()
	_build_word_list_grid()
	_refresh_ui_from_config()


func _create_or_reset_config() -> void:
	run_config = EndlessRunConfig.new()

	if AVAILABLE_MAP_IDS.is_empty():
		run_config.map_id = ""
	else:
		run_config.map_id = AVAILABLE_MAP_IDS[0]

	run_config.enabled_enemy_groups = ["soldiers"]
	run_config.selected_word_list_ids = []


func _build_map_options() -> void:
	map_option_button.clear()

	for i in AVAILABLE_MAP_IDS.size():
		var map_id := AVAILABLE_MAP_IDS[i]
		map_option_button.add_item(_format_display_name(map_id), i)

	var selected_index := AVAILABLE_MAP_IDS.find(run_config.map_id)
	if selected_index == -1:
		selected_index = 0

	if AVAILABLE_MAP_IDS.size() > 0:
		map_option_button.select(selected_index)


func _connect_ui() -> void:
	if not map_option_button.item_selected.is_connected(_on_map_selected):
		map_option_button.item_selected.connect(_on_map_selected)

	if not soldiers_check_box.toggled.is_connected(_on_soldiers_toggled):
		soldiers_check_box.toggled.connect(_on_soldiers_toggled)

	if not slimes_check_box.toggled.is_connected(_on_slimes_toggled):
		slimes_check_box.toggled.connect(_on_slimes_toggled)

	if not enable_all_button.pressed.is_connected(_on_enable_all_pressed):
		enable_all_button.pressed.connect(_on_enable_all_pressed)

	if not disable_all_button.pressed.is_connected(_on_disable_all_pressed):
		disable_all_button.pressed.connect(_on_disable_all_pressed)

	if not upload_csv_button.pressed.is_connected(_on_upload_csv_pressed):
		upload_csv_button.pressed.connect(_on_upload_csv_pressed)

	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)

	if not file_dialog.file_selected.is_connected(_on_file_selected):
		file_dialog.file_selected.connect(_on_file_selected)

	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.csv ; CSV Files"])


func _build_word_list_grid() -> void:
	_clear_word_list_grid()
	_word_list_buttons_by_id.clear()

	var lists: Array[WordListData] = WordLists.get_all_lists()

	for list_data in lists:
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 90)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true

		var is_selected: bool = run_config.selected_word_list_ids.has(list_data.id)
		button.button_pressed = is_selected
		button.text = _get_word_list_button_text(list_data)

		button.pressed.connect(_on_word_list_pressed.bind(list_data.id))

		word_list_grid.add_child(button)
		_word_list_buttons_by_id[list_data.id] = button

	if _focused_list_id.is_empty() and not lists.is_empty():
		_focused_list_id = lists[0].id

	_refresh_word_list_button_states()
	_refresh_detail_panel()
	_refresh_summary()
	_refresh_start_button_state()

func _clear_word_list_grid() -> void:
	for child in word_list_grid.get_children():
		child.queue_free()


func _refresh_ui_from_config() -> void:
	soldiers_check_box.button_pressed = run_config.enabled_enemy_groups.has("soldiers")
	slimes_check_box.button_pressed = run_config.enabled_enemy_groups.has("slimes")

	var selected_index := AVAILABLE_MAP_IDS.find(run_config.map_id)
	if selected_index >= 0:
		map_option_button.select(selected_index)

	_refresh_word_list_button_states()
	_refresh_detail_panel()
	_refresh_summary()
	_refresh_start_button_state()


func _refresh_word_list_button_states() -> void:
	for list_id in _word_list_buttons_by_id.keys():
		var button: Button = _word_list_buttons_by_id[list_id]
		var list_data: WordListData = WordLists.get_list(list_id)

		if button == null or list_data == null:
			continue

		var is_selected : bool = run_config.selected_word_list_ids.has(list_id)
		var is_focused : bool = _focused_list_id == list_id

		button.button_pressed = is_selected
		button.text = _get_word_list_button_text(list_data)

		if is_focused and is_selected:
			button.modulate = Color(0.8, 1.0, 0.8, 1.0)
		elif is_focused:
			button.modulate = Color(0.9, 0.9, 1.0, 1.0)
		elif is_selected:
			button.modulate = Color(0.85, 1.0, 0.85, 1.0)
		else:
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _refresh_detail_panel() -> void:
	var list_data: WordListData = WordLists.get_list(_focused_list_id)

	if list_data == null:
		detail_name_label.text = "No List Selected"
		detail_category_label.text = ""
		detail_count_label.text = ""
		detail_words_text.text = ""
		return

	detail_name_label.text = list_data.display_name
	detail_category_label.text = "Category: %s" % list_data.category
	detail_count_label.text = "Words: %d" % list_data.words.size()
	detail_words_text.text = "\n".join(list_data.words)


func _refresh_summary() -> void:
	var selected_lists := run_config.selected_word_list_ids.size()
	var selected_groups : int = run_config.enabled_enemy_groups.size()

	summary_label.text = "Map: %s | Enemy Groups: %d | Word Lists: %d" % [
		_format_display_name(run_config.map_id),
		selected_groups,
		selected_lists,
	]


func _refresh_start_button_state() -> void:
	var has_map := not run_config.map_id.is_empty()
	var has_enemy_group : bool = not run_config.enabled_enemy_groups.is_empty()
	var has_word_list := not run_config.selected_word_list_ids.is_empty()

	start_button.disabled = not (has_map and has_enemy_group and has_word_list)


func _get_word_list_button_text(list_data: WordListData) -> String:
	var prefix := "[ON] " if run_config.selected_word_list_ids.has(list_data.id) else "[OFF] "
	var source := "Custom" if list_data.is_custom else "Built-in"

	return "%s%s\n%d words | %s" % [
		prefix,
		list_data.display_name,
		list_data.words.size(),
		source,
	]


func _set_enemy_group_enabled(group_id: String, enabled: bool) -> void:
	var idx : int = run_config.enabled_enemy_groups.find(group_id)

	if enabled:
		if idx == -1:
			run_config.enabled_enemy_groups.append(group_id)
	else:
		if idx != -1:
			run_config.enabled_enemy_groups.remove_at(idx)

	_refresh_summary()
	_refresh_start_button_state()


func _toggle_word_list(list_id: String) -> void:
	var idx := run_config.selected_word_list_ids.find(list_id)

	if idx == -1:
		run_config.selected_word_list_ids.append(list_id)
	else:
		run_config.selected_word_list_ids.remove_at(idx)

	_focused_list_id = list_id

	_refresh_word_list_button_states()
	_refresh_detail_panel()
	_refresh_summary()
	_refresh_start_button_state()


func _enable_all_word_lists() -> void:
	run_config.selected_word_list_ids.clear()

	for list_data in WordLists.get_all_lists():
		run_config.selected_word_list_ids.append(list_data.id)

	_refresh_word_list_button_states()
	_refresh_detail_panel()
	_refresh_summary()
	_refresh_start_button_state()


func _disable_all_word_lists() -> void:
	run_config.selected_word_list_ids.clear()

	_refresh_word_list_button_states()
	_refresh_detail_panel()
	_refresh_summary()
	_refresh_start_button_state()


func _make_custom_list_id_from_path(path: String) -> String:
	var file_name := path.get_file().get_basename()
	return "custom_%s" % file_name


func _make_custom_display_name_from_path(path: String) -> String:
	return path.get_file().get_basename()


func _format_display_name(value: String) -> String:
	return value.replace("_", " ").capitalize()


func get_enabled_enemy_types() -> Array[String]:
	var expanded_types: Array[String] = []

	for group_id in run_config.enabled_enemy_groups:
		var group_types: Array = ENEMY_GROUP_TO_TYPES.get(group_id, [])

		for enemy_type in group_types:
			if not expanded_types.has(enemy_type):
				expanded_types.append(enemy_type)

	return expanded_types


func _on_map_selected(index: int) -> void:
	if index < 0 or index >= AVAILABLE_MAP_IDS.size():
		return

	run_config.map_id = AVAILABLE_MAP_IDS[index]
	_refresh_summary()
	_refresh_start_button_state()


func _on_soldiers_toggled(toggled_on: bool) -> void:
	_set_enemy_group_enabled("soldiers", toggled_on)


func _on_slimes_toggled(toggled_on: bool) -> void:
	_set_enemy_group_enabled("slimes", toggled_on)


func _on_enable_all_pressed() -> void:
	_enable_all_word_lists()


func _on_disable_all_pressed() -> void:
	_disable_all_word_lists()


func _on_upload_csv_pressed() -> void:
	file_dialog.popup_centered_ratio(0.7)


func _on_file_selected(path: String) -> void:
	var list_id := _make_custom_list_id_from_path(path)
	var display_name := _make_custom_display_name_from_path(path)

	var ok := WordLists.import_csv_as_custom_list(path, list_id, display_name, "custom")
	if not ok:
		push_warning("Failed to import custom CSV: %s" % path)
		return

	_build_word_list_grid()

	if WordLists.has_list(list_id):
		if not run_config.selected_word_list_ids.has(list_id):
			run_config.selected_word_list_ids.append(list_id)

		_focused_list_id = list_id

	_refresh_word_list_button_states()
	_refresh_detail_panel()
	_refresh_summary()
	_refresh_start_button_state()


func _on_word_list_pressed(list_id: String) -> void:
	_toggle_word_list(list_id)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _on_start_pressed() -> void:
	if start_button.disabled:
		return

	print("Starting endless mode with config:")
	print("Map: ", run_config.map_id)
	print("Enemy Groups: ", run_config.enabled_enemy_groups)
	print("Expanded Enemy Types: ", get_enabled_enemy_types())
	print("Word Lists: ", run_config.selected_word_list_ids)

	# Later:
	# GameSession.current_endless_run_config = run_config
	# get_tree().change_scene_to_file("res://scenes/game/game_screen.tscn")
