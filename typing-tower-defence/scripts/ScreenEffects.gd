# res://scripts/global/ScreenEffects.gd
extends Node

signal screen_shake_requested(intensity: float, duration: float)


func shake_screen(intensity: float = 8.0, duration: float = 0.18) -> void:
	screen_shake_requested.emit(intensity, duration)
