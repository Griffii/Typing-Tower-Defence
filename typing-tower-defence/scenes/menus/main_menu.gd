extends Control

signal play_requested
signal endless_mode_requested
signal settings_requested
signal wordlistsmenu_requested

const LIGHTNING_SCENE: PackedScene = preload("res://scenes/game/projectiles/lightning_projectile.tscn")
const GRUNT_ENEMY_SCENE: PackedScene = preload("res://scenes/game/enemies/grunt_enemy.tscn")
const SLIME_ENEMY_SCENE: PackedScene = preload("res://scenes/game/enemies/slime_enemy.tscn")

const MENU_ENEMY_SCENES: Array[PackedScene] = [
	GRUNT_ENEMY_SCENE,
	SLIME_ENEMY_SCENE,
]

const TITLE_TEXT := "Typing\nTower Defence!"
const TITLE_TYPED_COLOR := "6fdc8c"
const MENU_ENEMY_MOVE_SPEED := 50.0

@onready var endless_button: Button = %EndlessButton
@onready var settings_button: Button = %SettingsButton
@onready var word_lists_button: Button = %WordListsButton
@onready var story_button: Button = %StoryButton

@onready var title_label: RichTextLabel = %TitleLabel
@onready var tower_container: Node2D = %TowerContainer
@onready var lightning_marker: Marker2D = %LightningMarker
@onready var animation_player: AnimationPlayer = %TowerAnimPlayer
@onready var typing_sfx_player: AudioStreamPlayer2D = %TypingSfxPlayer

@onready var enemy_spawn_marker: Marker2D = %EnemySpawnMarker
@onready var enemy_path: Path2D = %EnemyPath

var rng := RandomNumberGenerator.new()
var is_shoot_animation_playing := false
var type_color_effect: TypeColorEffect = null


func _ready() -> void:
	rng.randomize()
	
	endless_button.pressed.connect(_on_endless_mode_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	word_lists_button.pressed.connect(_on_wordlists_pressed)
	
	if animation_player != null and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	
	title_label.bbcode_enabled = true
	title_label.scroll_active = false
	title_label.fit_content = true
	
	var wave_effect := WaveTextEffect.new()
	title_label.install_effect(wave_effect)
	
	type_color_effect = TypeColorEffect.new()
	title_label.install_effect(type_color_effect)
	
	_reset_title_text()
	
	call_deferred("_run_title_cycle")
	call_deferred("_run_menu_enemy_cycle")


func _reset_title_text() -> void:
	if type_color_effect != null:
		type_color_effect.typed_count = 0

	title_label.text = "[wave height=8 speed=2.2 spacing=0.45][typecolor color=%s]%s[/typecolor]" % [
		TITLE_TYPED_COLOR,
		TITLE_TEXT
	]


func _run_title_cycle() -> void:
	while is_inside_tree():
		if type_color_effect == null:
			return

		type_color_effect.typed_count = 0
		title_label.queue_redraw()

		await get_tree().create_timer(rng.randf_range(1.8, 3.8)).timeout

		for i in range(1, TITLE_TEXT.length() + 1):
			type_color_effect.typed_count = i
			title_label.queue_redraw()
			_play_typing_sfx()

			var delay := rng.randf_range(0.07, 0.15)

			if rng.randf() < 0.24:
				delay += rng.randf_range(0.06, 0.18)

			await get_tree().create_timer(delay).timeout

		await get_tree().create_timer(0.2).timeout

		type_color_effect.typed_count = 0
		title_label.queue_redraw()
		_play_random_shoot_animation()

		while is_shoot_animation_playing and is_inside_tree():
			await get_tree().process_frame

		await get_tree().create_timer(rng.randf_range(2.5, 5.0)).timeout


func _run_menu_enemy_cycle() -> void:
	while is_inside_tree():
		await get_tree().create_timer(rng.randf_range(8.0, 16.0)).timeout
		_spawn_menu_enemy()


func _spawn_menu_enemy() -> void:
	if enemy_path == null or enemy_spawn_marker == null:
		return

	if MENU_ENEMY_SCENES.is_empty():
		return

	var curve: Curve2D = enemy_path.curve
	if curve == null:
		return

	var enemy_scene: PackedScene = MENU_ENEMY_SCENES[rng.randi_range(0, MENU_ENEMY_SCENES.size() - 1)]
	if enemy_scene == null:
		return

	var path_follow: PathFollow2D = PathFollow2D.new()
	path_follow.rotates = false
	path_follow.loop = false
	enemy_path.add_child(path_follow)

	var enemy_instance: Node = enemy_scene.instantiate()
	path_follow.add_child(enemy_instance)

	if enemy_instance is Node2D:
		(enemy_instance as Node2D).position = Vector2.ZERO

	var label_root := enemy_instance.find_child("LabelRoot", true, false)
	if label_root is CanvasItem:
		(label_root as CanvasItem).visible = false

	var spawn_local: Vector2 = enemy_path.to_local(enemy_spawn_marker.global_position)
	var start_offset: float = curve.get_closest_offset(spawn_local)
	var path_length: float = curve.get_baked_length()

	path_follow.progress = start_offset

	var remaining_distance: float = maxf(path_length - start_offset, 1.0)
	var travel_time: float = remaining_distance / MENU_ENEMY_MOVE_SPEED

	var tween := create_tween()
	tween.tween_property(path_follow, "progress", path_length, travel_time)
	tween.finished.connect(_on_menu_enemy_tween_finished.bind(path_follow))


func _on_menu_enemy_tween_finished(path_follow: PathFollow2D) -> void:
	if is_instance_valid(path_follow):
		path_follow.queue_free()


func _play_typing_sfx() -> void:
	if typing_sfx_player == null:
		return

	typing_sfx_player.pitch_scale = rng.randf_range(0.96, 1.04)
	typing_sfx_player.play()


func _play_random_shoot_animation() -> void:
	if animation_player == null or is_shoot_animation_playing:
		return

	is_shoot_animation_playing = true

	if rng.randi_range(0, 1) == 0:
		animation_player.play("shoot_blue")
	else:
		animation_player.play("shoot_yellow")


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot_blue" or anim_name == "shoot_yellow":
		is_shoot_animation_playing = false


func spawn_lightning() -> void:
	if LIGHTNING_SCENE == null or lightning_marker == null or tower_container == null:
		return

	var lightning_instance := LIGHTNING_SCENE.instantiate()
	tower_container.add_child(lightning_instance)

	var spawn_pos := tower_container.to_local(lightning_marker.global_position)

	if lightning_instance.has_method("fire"):
		lightning_instance.fire(spawn_pos)
	elif lightning_instance is Node2D:
		lightning_instance.position = spawn_pos



## Button press signal requests
func _on_play_pressed() -> void:
	play_requested.emit()

func _on_endless_mode_pressed() -> void:
	endless_mode_requested.emit()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_wordlists_pressed() -> void:
	wordlistsmenu_requested.emit()
