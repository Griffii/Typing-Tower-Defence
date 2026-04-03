extends CanvasLayer

signal return_to_shop_requested
signal tower_purchase_requested(slot_id: String)

@onready var gold_label: Label = %GoldLabel
@onready var slot_01_button: Button = %Slot01Button
@onready var slot_02_button: Button = %Slot02Button
@onready var slot_03_button: Button = %Slot03Button
@onready var return_button: Button = %ReturnToShopButton


func _ready() -> void:
	visible = false
	return_button.pressed.connect(_on_return_pressed)
	slot_01_button.pressed.connect(func(): tower_purchase_requested.emit("slot_01"))
	slot_02_button.pressed.connect(func(): tower_purchase_requested.emit("slot_02"))
	slot_03_button.pressed.connect(func(): tower_purchase_requested.emit("slot_03"))


func show_overlay(build_state: Dictionary) -> void:
	visible = true
	refresh_build(build_state)


func hide_overlay() -> void:
	visible = false


func refresh_build(build_state: Dictionary) -> void:
	gold_label.text = "Gold: %d" % int(build_state.get("gold", 0))

	var slots: Dictionary = build_state.get("slots", {})

	_refresh_slot_button(slot_01_button, "slot_01", slots)
	_refresh_slot_button(slot_02_button, "slot_02", slots)
	_refresh_slot_button(slot_03_button, "slot_03", slots)


func _refresh_slot_button(button: Button, slot_id: String, slots: Dictionary) -> void:
	if not slots.has(slot_id):
		button.text = "-"
		button.disabled = true
		return

	var slot_data: Dictionary = slots[slot_id]
	var next_cost: int = int(slot_data.get("next_cost", -1))

	# MAXED OUT
	if next_cost < 0:
		button.text = "MAX"
		button.disabled = true
		return

	# NORMAL STATE → show + and cost
	button.text = "+\n%d" % next_cost
	button.disabled = false


func _on_return_pressed() -> void:
	return_to_shop_requested.emit()
