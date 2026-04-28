extends PopupPanel

signal word_list_created(list_id: String)

@onready var word_list_name_input: LineEdit = %WordListNameInput
@onready var word_list_words_input: TextEdit = %WordListWordsInput
@onready var save_word_list_button: Button = %SaveWordListButton
@onready var cancel_word_list_button: Button = %CancelWordListButton


func _ready() -> void:
	if save_word_list_button != null and not save_word_list_button.pressed.is_connected(_on_save_pressed):
		save_word_list_button.pressed.connect(_on_save_pressed)

	if cancel_word_list_button != null and not cancel_word_list_button.pressed.is_connected(_on_cancel_pressed):
		cancel_word_list_button.pressed.connect(_on_cancel_pressed)


func open_popup() -> void:
	if word_list_name_input != null:
		word_list_name_input.text = ""

	if word_list_words_input != null:
		word_list_words_input.text = ""

	popup_centered_ratio(0.65)


func _on_cancel_pressed() -> void:
	hide()


func _on_save_pressed() -> void:
	if word_list_name_input == null or word_list_words_input == null:
		return

	var display_name: String = word_list_name_input.text.strip_edges()
	var raw_text: String = word_list_words_input.text.strip_edges()

	if display_name.is_empty():
		push_warning("AddWordListPopup: word list name is empty.")
		return

	if raw_text.is_empty():
		push_warning("AddWordListPopup: word list text is empty.")
		return

	var list_id: String = "custom_%s" % _normalize_local_id(display_name)
	var normalized_text: String = _convert_comma_text_to_line_text(raw_text)

	var ok: bool = WordLists.import_text_as_temporary_list(
		normalized_text,
		list_id,
		display_name,
		"custom"
	)

	if not ok:
		push_warning("AddWordListPopup: failed to import custom word list: %s" % display_name)
		return

	hide()
	word_list_created.emit(list_id)


func _convert_comma_text_to_line_text(raw_text: String) -> String:
	var cleaned_words: Array[String] = []
	var seen_words: Dictionary = {}
	var parts: PackedStringArray = raw_text.split(",", false)

	for part in parts:
		var word: String = str(part).strip_edges()

		if word.is_empty():
			continue

		if seen_words.has(word):
			continue

		seen_words[word] = true
		cleaned_words.append(word)

	return "\n".join(cleaned_words)


func _normalize_local_id(raw_id: String) -> String:
	var id: String = raw_id.strip_edges().to_lower().replace(" ", "_")

	var cleaned: String = ""
	for i in id.length():
		var ch: String = id[i]

		var is_lower: bool = ch >= "a" and ch <= "z"
		var is_digit: bool = ch >= "0" and ch <= "9"
		var is_underscore: bool = ch == "_"
		var is_hyphen: bool = ch == "-"

		if is_lower or is_digit or is_underscore or is_hyphen:
			cleaned += ch

	if cleaned.is_empty():
		cleaned = "word_list"

	return cleaned
