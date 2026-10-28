extends Control

signal action_pressed

@onready var inventory_label: Label = %InventoryLabel
@onready var prompt_label: Label = %PromptLabel
@onready var action_button: Button = %ActionButton
@onready var location_label: Label = %LocationLabel


func _ready() -> void:
	GameState.inventory_changed.connect(_refresh_inventory)
	action_button.pressed.connect(func() -> void: action_pressed.emit())
	_refresh_inventory()


func set_location(text: String) -> void:
	location_label.text = text


func set_prompt(text: String) -> void:
	prompt_label.text = text


func set_action(text: String) -> void:
	action_button.text = text
	action_button.visible = not text.is_empty()


func hide_action() -> void:
	action_button.visible = false


func _refresh_inventory() -> void:
	if GameState.inventory.is_empty():
		inventory_label.text = "空"
		return
	var lines: Array[String] = []
	for id in GameState.inventory:
		lines.append("· " + GameState.item_name(id))
	inventory_label.text = "\n".join(lines)
