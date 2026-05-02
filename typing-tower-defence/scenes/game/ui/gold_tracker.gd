extends Control
class_name GoldTracker

signal gold_display_updated(new_gold: int)
signal gold_added_display(amount: int, old_gold: int, new_gold: int)
signal gold_spent_display(amount: int, old_gold: int, new_gold: int)

@onready var gold_label: Label = %GoldLabel
@onready var background_panel: Control = %BackgroundPanel
@onready var gold_icon: Control = %GoldIcon

var _combat_manager: Node = null
var _current_gold: int = 0
var _search_attempts: int = 0


func _ready() -> void:
	_refresh_label()
	call_deferred("_try_bind_combat_manager")


func _exit_tree() -> void:
	_disconnect_combat_manager()


func set_gold(gold: int) -> void:
	var old_gold: int = _current_gold
	_current_gold = max(0, gold)

	_refresh_label()

	if _current_gold == old_gold:
		return

	gold_display_updated.emit(_current_gold)

	if _current_gold > old_gold:
		var added: int = _current_gold - old_gold
		gold_added_display.emit(added, old_gold, _current_gold)
		_on_gold_added(added, old_gold, _current_gold)
	else:
		var spent: int = old_gold - _current_gold
		gold_spent_display.emit(spent, old_gold, _current_gold)
		_on_gold_spent(spent, old_gold, _current_gold)


func get_gold() -> int:
	return _current_gold


func _try_bind_combat_manager() -> void:
	if _combat_manager != null and is_instance_valid(_combat_manager):
		return

	var managers: Array[Node] = get_tree().get_nodes_in_group("combat_manager")
	if not managers.is_empty():
		_bind_combat_manager(managers[0])
		return

	_search_attempts += 1

	if _search_attempts < 20:
		await get_tree().create_timer(0.25).timeout
		if is_inside_tree():
			_try_bind_combat_manager()


func _bind_combat_manager(combat_manager: Node) -> void:
	if combat_manager == null or not is_instance_valid(combat_manager):
		return

	_disconnect_combat_manager()
	_combat_manager = combat_manager

	if _combat_manager.has_signal("hud_stats_changed"):
		if not _combat_manager.hud_stats_changed.is_connected(_on_hud_stats_changed):
			_combat_manager.hud_stats_changed.connect(_on_hud_stats_changed)

	_pull_initial_gold()


func _disconnect_combat_manager() -> void:
	if _combat_manager == null or not is_instance_valid(_combat_manager):
		_combat_manager = null
		return

	if _combat_manager.has_signal("hud_stats_changed"):
		if _combat_manager.hud_stats_changed.is_connected(_on_hud_stats_changed):
			_combat_manager.hud_stats_changed.disconnect(_on_hud_stats_changed)

	_combat_manager = null


func _pull_initial_gold() -> void:
	if _combat_manager == null or not is_instance_valid(_combat_manager):
		return

	if _combat_manager.has_method("get_shop_state"):
		var shop_state: Dictionary = _combat_manager.get_shop_state()
		set_gold(int(shop_state.get("gold", 0)))
		return

	if "gold" in _combat_manager:
		set_gold(int(_combat_manager.gold))


func _on_hud_stats_changed(stats: Dictionary) -> void:
	set_gold(int(stats.get("gold", 0)))


func _refresh_label() -> void:
	if gold_label == null:
		return

	gold_label.text = "%d G" % _current_gold





func _on_gold_added(_amount: int, _old_gold: int, _new_gold: int) -> void:
	# Hook for future gain animation / sound
	pass


func _on_gold_spent(_amount: int, _old_gold: int, _new_gold: int) -> void:
	# Hook for future spend animation / sound
	pass
