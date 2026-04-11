extends Node

const DEFAULT_LEVEL_SCENE: PackedScene = preload("res://scenes/game/levels/grasslands.tscn")
const DEFAULT_WAVE_SET = preload("res://data/waves/wave_set_01.gd")

var selected_level_scene: PackedScene = DEFAULT_LEVEL_SCENE
var selected_wave_set_script = DEFAULT_WAVE_SET


func _ready() -> void:
	print("[GameSelection] _ready()")
	print("[GameSelection] default level = ", _describe_resource(DEFAULT_LEVEL_SCENE))
	print("[GameSelection] default wave  = ", _describe_resource(DEFAULT_WAVE_SET))
	print("[GameSelection] selected level at startup = ", _describe_resource(selected_level_scene))
	print("[GameSelection] selected wave at startup  = ", _describe_resource(selected_wave_set_script))


func set_level_scene(level_scene: PackedScene) -> void:
	print("[GameSelection] set_level_scene() called with: ", _describe_resource(level_scene))

	if level_scene == null:
		print("[GameSelection] set_level_scene() aborted: level_scene was null")
		return

	selected_level_scene = level_scene
	print("[GameSelection] selected_level_scene set to: ", _describe_resource(selected_level_scene))


func set_wave_set_script(wave_script) -> void:
	print("[GameSelection] set_wave_set_script() called with: ", _describe_resource(wave_script))

	if wave_script == null:
		print("[GameSelection] set_wave_set_script() aborted: wave_script was null")
		return

	selected_wave_set_script = wave_script
	print("[GameSelection] selected_wave_set_script set to: ", _describe_resource(selected_wave_set_script))


func get_level_scene() -> PackedScene:
	print("[GameSelection] get_level_scene() called")
	print("[GameSelection] current selected_level_scene = ", _describe_resource(selected_level_scene))

	if selected_level_scene == null:
		print("[GameSelection] selected_level_scene was null, returning DEFAULT_LEVEL_SCENE")
		return DEFAULT_LEVEL_SCENE

	print("[GameSelection] returning selected_level_scene = ", _describe_resource(selected_level_scene))
	return selected_level_scene


func get_wave_set_script():
	print("[GameSelection] get_wave_set_script() called")
	print("[GameSelection] current selected_wave_set_script = ", _describe_resource(selected_wave_set_script))

	if selected_wave_set_script == null:
		print("[GameSelection] selected_wave_set_script was null, returning DEFAULT_WAVE_SET")
		return DEFAULT_WAVE_SET

	print("[GameSelection] returning selected_wave_set_script = ", _describe_resource(selected_wave_set_script))
	return selected_wave_set_script


func get_wave_definitions() -> Array:
	print("[GameSelection] get_wave_definitions() called")

	var wave_script = get_wave_set_script()
	print("[GameSelection] get_wave_definitions() using wave_script = ", _describe_resource(wave_script))

	if wave_script == null:
		print("[GameSelection] get_wave_definitions() returning [] because wave_script was null")
		return []

	if "WAVES" in wave_script:
		var defs: Variant = wave_script.WAVES
		if typeof(defs) == TYPE_ARRAY:
			print("[GameSelection] get_wave_definitions() returning array with size: ", defs.size())
			return defs.duplicate(true)

	print("[GameSelection] get_wave_definitions() returning [] because WAVES was missing or invalid")
	return []


func reset_to_defaults() -> void:
	print("[GameSelection] reset_to_defaults() called")
	selected_level_scene = DEFAULT_LEVEL_SCENE
	selected_wave_set_script = DEFAULT_WAVE_SET
	print("[GameSelection] selected_level_scene reset to: ", _describe_resource(selected_level_scene))
	print("[GameSelection] selected_wave_set_script reset to: ", _describe_resource(selected_wave_set_script))


func _describe_resource(value) -> String:
	if value == null:
		return "null"

	if value is PackedScene:
		var packed: PackedScene = value
		var scene_state: SceneState = packed.get_state()
		if scene_state != null:
			return "PackedScene<%s>" % scene_state.get_path()
		return "PackedScene<unknown_path>"

	if value is GDScript:
		var script: GDScript = value
		return "GDScript<%s>" % script.resource_path

	if value is Resource:
		var res: Resource = value
		return "Resource<%s>" % res.resource_path

	return str(value)
