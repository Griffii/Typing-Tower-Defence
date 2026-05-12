# res://scripts/GameFlags.gd
extends Node

signal dev_mode_changed(is_enabled: bool)

var dev_mode: bool = false


func set_dev_mode(value: bool) -> void:
	if dev_mode == value:
		return

	dev_mode = value
	dev_mode_changed.emit(dev_mode)


func toggle_dev_mode() -> bool:
	set_dev_mode(not dev_mode)
	return dev_mode


func is_dev_mode_enabled() -> bool:
	return dev_mode
