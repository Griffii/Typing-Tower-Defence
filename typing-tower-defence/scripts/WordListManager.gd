class_name WordListManager
extends Node

const BUILTIN_LISTS_DIR := "res://data/word_lists"
const CUSTOM_LISTS_DIR := "user://word_lists"
const CUSTOM_WORD_MAX_LENGTH := 32

var _lists_by_id: Dictionary = {}
var _builtin_ids: Array[String] = []
var _custom_ids: Array[String] = []


func _ready() -> void:
	reload_all()


func reload_all() -> void:
	_lists_by_id.clear()
	_builtin_ids.clear()
	_custom_ids.clear()

	_ensure_custom_dir_exists()
	_load_lists_from_dir(BUILTIN_LISTS_DIR, false)
	_load_lists_from_dir(CUSTOM_LISTS_DIR, true)


func get_all_lists() -> Array[WordListData]:
	var results: Array[WordListData] = []

	for id in _lists_by_id.keys():
		var list_data: WordListData = _lists_by_id[id]
		if list_data != null:
			results.append(list_data)

	results.sort_custom(func(a: WordListData, b: WordListData) -> bool:
		return a.display_name.naturalnocasecmp_to(b.display_name) < 0
	)

	return results


func get_builtin_lists() -> Array[WordListData]:
	var results: Array[WordListData] = []

	for id in _builtin_ids:
		var list_data: WordListData = _lists_by_id.get(id, null)
		if list_data != null:
			results.append(list_data)

	results.sort_custom(func(a: WordListData, b: WordListData) -> bool:
		return a.display_name.naturalnocasecmp_to(b.display_name) < 0
	)

	return results


func get_custom_lists() -> Array[WordListData]:
	var results: Array[WordListData] = []

	for id in _custom_ids:
		var list_data: WordListData = _lists_by_id.get(id, null)
		if list_data != null:
			results.append(list_data)

	results.sort_custom(func(a: WordListData, b: WordListData) -> bool:
		return a.display_name.naturalnocasecmp_to(b.display_name) < 0
	)

	return results


func has_list(list_id: String) -> bool:
	return _lists_by_id.has(list_id)


func get_list(list_id: String) -> WordListData:
	return _lists_by_id.get(list_id, null)


func get_words_for_list(list_id: String) -> Array[String]:
	var list_data: WordListData = get_list(list_id)
	if list_data == null:
		return []

	return list_data.words.duplicate()


func get_combined_words(list_ids: Array[String], deduplicate: bool = true) -> Array[String]:
	var combined: Array[String] = []

	for list_id in list_ids:
		var list_data: WordListData = get_list(list_id)
		if list_data == null:
			continue

		for word in list_data.words:
			combined.append(word)

	if deduplicate:
		combined = _deduplicate_words(combined)

	return combined


func get_random_word_from_lists(list_ids: Array[String]) -> String:
	var pool: Array[String] = get_combined_words(list_ids, true)
	if pool.is_empty():
		return ""

	return pool[randi() % pool.size()]


func save_custom_list(list_data: WordListData) -> bool:
	if list_data == null:
		push_error("WordListManager: save_custom_list received null list_data.")
		return false

	list_data.is_custom = true
	list_data.id = _normalize_id(list_data.id)
	list_data.display_name = list_data.display_name.strip_edges()
	list_data.category = list_data.category.strip_edges()
	list_data.words = _sanitize_words(list_data.words, CUSTOM_WORD_MAX_LENGTH)

	if list_data.id.is_empty():
		push_error("WordListManager: custom list id is empty.")
		return false

	if list_data.display_name.is_empty():
		list_data.display_name = list_data.id.capitalize()

	var save_path := "%s/%s.tres" % [CUSTOM_LISTS_DIR, list_data.id]
	var result: int = ResourceSaver.save(list_data, save_path)

	if result != OK:
		push_error("WordListManager: failed to save custom list to '%s'. Error code: %d" % [save_path, result])
		return false

	reload_all()
	return true


func create_custom_list(list_id: String, display_name: String, words: Array[String], category: String = "custom") -> bool:
	var list_data := WordListData.new()
	list_data.id = _normalize_id(list_id)
	list_data.display_name = display_name.strip_edges()
	list_data.category = category.strip_edges()
	list_data.words = _sanitize_words(words, CUSTOM_WORD_MAX_LENGTH)
	list_data.is_custom = true

	return save_custom_list(list_data)


func delete_custom_list(list_id: String) -> bool:
	list_id = _normalize_id(list_id)

	if list_id.is_empty():
		return false

	var list_data: WordListData = _lists_by_id.get(list_id, null)
	if list_data == null:
		return false

	if not list_data.is_custom:
		return false

	_lists_by_id.erase(list_id)
	_custom_ids.erase(list_id)

	var path := "%s/%s.tres" % [CUSTOM_LISTS_DIR, list_id]
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err != OK:
			push_warning("WordLists: failed to delete saved custom list '%s'. Error code: %d" % [path, err])

	return true


func import_csv_as_custom_list(csv_path: String, list_id: String, display_name: String, category: String = "custom") -> bool:
	var words: Array[String] = _parse_words_from_csv(csv_path)
	if words.is_empty():
		push_error("WordListManager: no valid words found in CSV '%s'." % csv_path)
		return false

	return create_custom_list(list_id, display_name, words, category)


func import_csv_as_temporary_list(path: String, list_id: String, display_name: String, category: String = "custom") -> bool:
	var words: Array[String] = _parse_words_from_csv(path)

	if words.is_empty():
		return false

	var list_data := WordListData.new()
	list_data.id = _normalize_id(list_id)
	list_data.display_name = display_name.strip_edges()
	list_data.category = category
	list_data.words = _sanitize_words(words, CUSTOM_WORD_MAX_LENGTH)
	list_data.is_custom = true

	_lists_by_id[list_data.id] = list_data

	if not _custom_ids.has(list_data.id):
		_custom_ids.append(list_data.id)

	return true

func _load_lists_from_dir(dir_path: String, mark_as_custom: bool) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		if not mark_as_custom:
			push_warning("WordListManager: could not open built-in directory '%s'." % dir_path)
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break

		if dir.current_is_dir():
			continue

		if not (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			continue

		var full_path := dir_path.path_join(file_name)
		var resource := load(full_path)

		if resource == null:
			push_warning("WordListManager: failed to load resource '%s'." % full_path)
			continue

		if not (resource is WordListData):
			push_warning("WordListManager: resource '%s' is not a WordListData." % full_path)
			continue

		var list_data: WordListData = resource
		list_data.id = _normalize_id(list_data.id)
		list_data.display_name = list_data.display_name.strip_edges()
		list_data.category = list_data.category.strip_edges()
		list_data.words = _sanitize_words(list_data.words)
		list_data.is_custom = mark_as_custom

		if list_data.id.is_empty():
			push_warning("WordListManager: list at '%s' has empty id." % full_path)
			continue

		_lists_by_id[list_data.id] = list_data

		if mark_as_custom:
			_custom_ids.append(list_data.id)
		else:
			_builtin_ids.append(list_data.id)

	dir.list_dir_end()


func _ensure_custom_dir_exists() -> void:
	if DirAccess.dir_exists_absolute(CUSTOM_LISTS_DIR):
		return

	var err := DirAccess.make_dir_recursive_absolute(CUSTOM_LISTS_DIR)
	if err != OK:
		push_error("WordListManager: failed to create custom lists directory '%s'. Error code: %d" % [CUSTOM_LISTS_DIR, err])


func _sanitize_words(words: Array, max_length: int = -1) -> Array[String]:
	var cleaned: Array[String] = []

	for value in words:
		var word := str(value).strip_edges()

		if word.is_empty():
			continue

		if max_length > -1 and word.length() > max_length:
			continue

		cleaned.append(word)

	return cleaned


func _deduplicate_words(words: Array[String]) -> Array[String]:
	var seen := {}
	var unique_words: Array[String] = []

	for word in words:
		if seen.has(word):
			continue

		seen[word] = true
		unique_words.append(word)

	return unique_words


func _normalize_id(raw_id: String) -> String:
	var id := raw_id.strip_edges().to_lower().replace(" ", "_")

	var cleaned := ""
	for i in id.length():
		var ch := id[i]

		var is_lower := ch >= "a" and ch <= "z"
		var is_digit := ch >= "0" and ch <= "9"
		var is_underscore := ch == "_"
		var is_hyphen := ch == "-"

		if is_lower or is_digit or is_underscore or is_hyphen:
			cleaned += ch

	return cleaned


func _parse_words_from_csv(csv_path: String) -> Array[String]:
	var words: Array[String] = []

	if not FileAccess.file_exists(csv_path):
		push_error("WordListManager: CSV file does not exist '%s'." % csv_path)
		return words

	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		push_error("WordListManager: could not open CSV file '%s'." % csv_path)
		return words

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line.is_empty():
			continue

		var cols := line.split(",", false)
		if cols.is_empty():
			continue

		var word := cols[0].strip_edges().trim_prefix("\"").trim_suffix("\"")
		if word.to_lower() == "word":
			continue

		words.append(word)

	return _sanitize_words(words, CUSTOM_WORD_MAX_LENGTH)
