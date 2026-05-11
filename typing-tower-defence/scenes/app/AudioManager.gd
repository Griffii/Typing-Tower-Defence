# AudioManager.gd
extends Node

@onready var music_a: AudioStreamPlayer = %MusicA
@onready var music_b: AudioStreamPlayer = %MusicB

var active_music_player: AudioStreamPlayer
var inactive_music_player: AudioStreamPlayer
var current_music: AudioStream = null
var music_tween: Tween = null

const MUSIC_BUS := "Music"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	active_music_player = music_a
	inactive_music_player = music_b
	
	music_a.process_mode = Node.PROCESS_MODE_ALWAYS
	music_b.process_mode = Node.PROCESS_MODE_ALWAYS

	music_a.bus = MUSIC_BUS
	music_b.bus = MUSIC_BUS


func play_music(stream: AudioStream, fade_time: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return

	if current_music == stream:
		return

	current_music = stream

	if music_tween != null and music_tween.is_valid():
		music_tween.kill()

	_set_stream_loop_enabled(stream, true)

	inactive_music_player.stream = stream
	inactive_music_player.volume_db = -40.0
	inactive_music_player.play()

	music_tween = create_tween()
	music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	music_tween.set_parallel(true)
	music_tween.tween_property(active_music_player, "volume_db", -40.0, fade_time)
	music_tween.tween_property(inactive_music_player, "volume_db", volume_db, fade_time)

	await music_tween.finished

	active_music_player.stop()

	var old_active := active_music_player
	active_music_player = inactive_music_player
	inactive_music_player = old_active


func stop_music(fade_time: float = 1.0) -> void:
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()

	music_tween = create_tween()
	music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	music_tween.tween_property(active_music_player, "volume_db", -40.0, fade_time)

	await music_tween.finished

	active_music_player.stop()
	current_music = null


func _set_stream_loop_enabled(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = enabled
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = enabled
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if enabled else AudioStreamWAV.LOOP_DISABLED
