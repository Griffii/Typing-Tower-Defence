extends Control

signal start_requested
signal back_requested

const ENEMY_GROUP_TO_TYPES := {
	"soldiers": ["grunt", "scout", "tank", "boss"],
	"slimes": ["slime", "boss_slime"],
}

@export var word_list_grid_columns: int = 3
@export var word_list_button_size: Vector2 = Vector2(100, 80)

@onready var castle_walls_button: Button = %CastleWallsButton
@onready var grasslands_button: Button = %GrasslandsButton
@onready var seaside_farm_button: Button = %SeasideFarmButton

@onready var soldiers_button: Button = %SoldiersButton
@onready var slimes_button: Button = %SlimesButton

@onready var word_list_scroll: ScrollContainer = %WordListScroll
@onready var word_list_grid: GridContainer = %WordListGrid

@onready var enable_all_button: Button = %EnableAllButton
@onready var disable_all_button: Button = %DisableAllButton
@onready var add_new_word_list_button: Button = %AddNewWordListButton
@onready var add_word_list_popup: PopupPanel = %AddWordListPopup

@onready var total_words_count: Label = %TotalWordsCount
@onready var included_lists_label: RichTextLabel = %IncludedListsLabel

@onready var summary_label: Label = %SummaryLabel
@onready var back_button: Button = %BackButton
@onready var start_button: Button = %StartButton

var run_config: EndlessRunConfig
var map_button_group: ButtonGroup
var _word_list_buttons_by_id: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_create_or_reset_config()
	_setup_layout()
	_setup_buttons()
	_connect_signals()
	_build_word_list_grid()
	_refresh_ui_from_config()


func _create_or_reset_config() -> void:
	run_config = EndlessRunConfig.new()
	run_config.map_id = "castle_walls"
	run_config.enabled_enemy_groups = []
	run_config.selected_word_list_ids = []


func _setup_layout() -> void:
	if word_list_scroll != null:
		word_list_scroll.clip_contents = true
		word_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		word_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if word_list_grid != null:
		word_list_grid.columns = word_list_grid_columns
		word_list_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		word_list_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if included_lists_label != null:
		included_lists_label.fit_content = true
		included_lists_label.scroll_active = true
		included_lists_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		included_lists_label.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _setup_buttons() -> void:
	map_button_group = ButtonGroup.new()

	_setup_map_button(castle_walls_button)
	_setup_map_button(grasslands_button)
	_setup_map_button(seaside_farm_button)

	_setup_toggle_button(soldiers_button)
	_setup_toggle_button(slimes_button)

	if castle_walls_button != null:
		castle_walls_button.button_pressed = true

	if grasslands_button != null:
		grasslands_button.button_pressed = false

	if seaside_farm_button != null:
		seaside_farm_button.button_pressed = false

	if soldiers_button != null:
		soldiers_button.button_pressed = false

	if slimes_button != null:
		slimes_button.button_pressed = false


func _setup_map_button(button: Button) -> void:
	if button == null:
		return

	button.toggle_mode = true
	button.button_group = map_button_group


func _setup_toggle_button(button: Button) -> void:
	if button == null:
		return

	button.toggle_mode = true
	button.button_group = null


func _connect_signals() -> void:
	if castle_walls_button != null and not castle_walls_button.pressed.is_connected(_on_castle_walls_pressed):
		castle_walls_button.pressed.connect(_on_castle_walls_pressed)
	
	if grasslands_button != null and not grasslands_button.pressed.is_connected(_on_grasslands_pressed):
		grasslands_button.pressed.connect(_on_grasslands_pressed)

	if seaside_farm_button != null and not seaside_farm_button.pressed.is_connected(_on_seaside_farm_pressed):
		seaside_farm_button.pressed.connect(_on_seaside_farm_pressed)

	if soldiers_button != null and not soldiers_button.toggled.is_connected(_on_soldiers_toggled):
		soldiers_button.toggled.connect(_on_soldiers_toggled)

	if slimes_button != null and not slimes_button.toggled.is_connected(_on_slimes_toggled):
		slimes_button.toggled.connect(_on_slimes_toggled)

	if enable_all_button != null and not enable_all_button.pressed.is_connected(_on_enable_all_pressed):
		enable_all_button.pressed.connect(_on_enable_all_pressed)

	if disable_all_button != null and not disable_all_button.pressed.is_connected(_on_disable_all_pressed):
		disable_all_button.pressed.connect(_on_disable_all_pressed)

	if add_new_word_list_button != null and not add_new_word_list_button.pressed.is_connected(_on_add_new_word_list_pressed):
		add_new_word_list_button.pressed.connect(_on_add_new_word_list_pressed)

	if add_word_list_popup != null and add_word_list_popup.has_signal("word_list_created"):
		if not add_word_list_popup.word_list_created.is_connected(_on_word_list_created):
			add_word_list_popup.word_list_created.connect(_on_word_list_created)

	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	if start_button != null and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)


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
		button.toggle_mode = true

		var is_selected: bool = run_config.selected_word_list_ids.has(list_data.id)
		button.button_pressed = is_selected
		button.text = _get_word_list_button_text(list_data)

		button.pressed.connect(_on_word_list_pressed.bind(list_data.id))

		word_list_grid.add_child(button)
		_word_list_buttons_by_id[list_data.id] = button

	_refresh_word_list_button_states()
	_refresh_word_list_summary()
	_refresh_summary()
	_refresh_start_button_state()


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


func _refresh_ui_from_config() -> void:
	if castle_walls_button != null:
		castle_walls_button.button_pressed = run_config.map_id == "castle_walls"
	
	if grasslands_button != null:
		grasslands_button.button_pressed = run_config.map_id == "grasslands"

	if seaside_farm_button != null:
		seaside_farm_button.button_pressed = run_config.map_id == "seaside_farm"

	if soldiers_button != null:
		soldiers_button.button_pressed = run_config.enabled_enemy_groups.has("soldiers")

	if slimes_button != null:
		slimes_button.button_pressed = run_config.enabled_enemy_groups.has("slimes")

	_refresh_word_list_button_states()
	_refresh_word_list_summary()
	_refresh_summary()
	_refresh_start_button_state()


func _refresh_word_list_button_states() -> void:
	for list_id in _word_list_buttons_by_id.keys():
		var button: Button = _word_list_buttons_by_id[list_id]
		var list_data: WordListData = WordLists.get_list(list_id)

		if button == null or list_data == null:
			continue

		var is_selected: bool = run_config.selected_word_list_ids.has(list_id)

		button.button_pressed = is_selected
		button.text = _get_word_list_button_text(list_data)

		if is_selected:
			button.modulate = Color(0.85, 1.0, 0.85, 1.0)
		else:
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _refresh_word_list_summary() -> void:
	var total_words: int = 0
	var selected_names: Array[String] = []

	for list_id in run_config.selected_word_list_ids:
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


func _refresh_summary() -> void:
	var selected_lists: int = run_config.selected_word_list_ids.size()
	var selected_groups: int = run_config.enabled_enemy_groups.size()

	summary_label.text = "Map: %s | Enemy Groups: %d | Word Lists: %d" % [
		_format_display_name(run_config.map_id),
		selected_groups,
		selected_lists,
	]


func _refresh_start_button_state() -> void:
	var has_map: bool = not run_config.map_id.is_empty()
	var has_enemy_group: bool = not run_config.enabled_enemy_groups.is_empty()
	var has_word_list: bool = not run_config.selected_word_list_ids.is_empty()

	start_button.disabled = not (has_map and has_enemy_group and has_word_list)


func _get_word_list_button_text(list_data: WordListData) -> String:
	return "%s\n(%d)" % [
		list_data.display_name,
		list_data.words.size(),
	]


func _set_enemy_group_enabled(group_id: String, enabled: bool) -> void:
	var idx: int = run_config.enabled_enemy_groups.find(group_id)

	if enabled:
		if idx == -1:
			run_config.enabled_enemy_groups.append(group_id)
	else:
		if idx != -1:
			run_config.enabled_enemy_groups.remove_at(idx)

	_refresh_summary()
	_refresh_start_button_state()


func _toggle_word_list(list_id: String) -> void:
	var idx: int = run_config.selected_word_list_ids.find(list_id)

	if idx == -1:
		run_config.selected_word_list_ids.append(list_id)
	else:
		run_config.selected_word_list_ids.remove_at(idx)

	_refresh_word_list_button_states()
	_refresh_word_list_summary()
	_refresh_summary()
	_refresh_start_button_state()


func _enable_all_word_lists() -> void:
	run_config.selected_word_list_ids.clear()

	for list_data in _get_sorted_word_lists():
		run_config.selected_word_list_ids.append(list_data.id)

	_refresh_word_list_button_states()
	_refresh_word_list_summary()
	_refresh_summary()
	_refresh_start_button_state()


func _disable_all_word_lists() -> void:
	run_config.selected_word_list_ids.clear()

	_refresh_word_list_button_states()
	_refresh_word_list_summary()
	_refresh_summary()
	_refresh_start_button_state()


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


func _on_castle_walls_pressed() -> void:
	run_config.map_id = "castle_walls"
	_refresh_summary()
	_refresh_start_button_state()

func _on_grasslands_pressed() -> void:
	run_config.map_id = "grasslands"
	_refresh_summary()
	_refresh_start_button_state()

func _on_seaside_farm_pressed() -> void:
	run_config.map_id = "seaside_farm"
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


func _on_add_new_word_list_pressed() -> void:
	if add_word_list_popup == null:
		return

	if add_word_list_popup.has_method("open_popup"):
		add_word_list_popup.open_popup()
	else:
		add_word_list_popup.popup_centered_ratio(0.65)


func _on_word_list_created(list_id: String) -> void:
	_build_word_list_grid()

	if WordLists.has_list(list_id):
		if not run_config.selected_word_list_ids.has(list_id):
			run_config.selected_word_list_ids.append(list_id)

	_refresh_word_list_button_states()
	_refresh_word_list_summary()
	_refresh_summary()
	_refresh_start_button_state()


func _on_word_list_pressed(list_id: String) -> void:
	_toggle_word_list(list_id)


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_start_pressed() -> void:
	if start_button.disabled:
		return

	match run_config.map_id:
		"castle_walls", "grasslands", "seaside_farm":
			pass
		_:
			push_warning("EndlessSetupScreen: Unknown map_id: %s" % run_config.map_id)
			return

	var finalized_config: EndlessRunConfig = run_config.duplicate(true) as EndlessRunConfig

	GameSession.setup_endless(finalized_config)

	start_requested.emit()
