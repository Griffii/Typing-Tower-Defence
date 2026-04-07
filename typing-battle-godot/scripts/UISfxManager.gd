extends Node

@onready var hover_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var click_player: AudioStreamPlayer = AudioStreamPlayer.new()

var hover_sound: AudioStream = preload("res://assets/sfx/menus/hover-sfx.ogg")
var click_sound: AudioStream = preload("res://assets/sfx/menus/click-sfx.ogg")

func _ready():
	add_child(hover_player)
	add_child(click_player)

	hover_player.stream = hover_sound
	click_player.stream = click_sound

	# Hook existing UI
	_connect_buttons(get_tree().root)

	# Hook future UI
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)


func _connect_buttons(root: Node) -> void:
	for node in root.get_children():
		if node is BaseButton:
			_connect_button(node)
		_connect_buttons(node)


func _connect_button(button: BaseButton) -> void:
	if not button.mouse_entered.is_connected(_on_hover):
		button.mouse_entered.connect(_on_hover)

	if not button.pressed.is_connected(_on_click):
		button.pressed.connect(_on_click)


func _on_hover() -> void:
	if not hover_player.playing:
		hover_player.play()


func _on_click() -> void:
	click_player.play()
