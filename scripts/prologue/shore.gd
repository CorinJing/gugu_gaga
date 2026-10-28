extends Control

@onready var hud: Control = $GameHUD
@onready var ferryman_hotspot: Control = %FerrymanHotspot
@onready var ferryman_figure: Control = %FerrymanFigure


func _ready() -> void:
	hud.action_pressed.connect(_on_action_pressed)
	ferryman_hotspot.gui_input.connect(_on_ferryman_input)
	ferryman_hotspot.mouse_entered.connect(func() -> void:
		if not GameState.has_flag("ferry_paid"):
			hud.set_prompt("船夫伸出一只手，掌心朝上。")
	)
	ferryman_hotspot.mouse_exited.connect(_refresh_prompt)
	hud.set_location("序章 · 船头")
	_sync()


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _sync() -> void:
	if GameState.has_flag("ferry_paid"):
		ferryman_figure.position.x = 240.0
		hud.set_action("去旅馆")
	else:
		ferryman_figure.position.x = 390.0
		hud.set_action("回船舱")
	_refresh_prompt()


func _refresh_prompt() -> void:
	if GameState.has_flag("ferry_paid"):
		hud.set_prompt("船夫已经让开了。沿盐壳小路去旅馆。")
	elif GameState.has_item("coin"):
		hud.set_prompt("把硬币交给船夫。")
	else:
		hud.set_prompt("船夫伸出一只手。你还没付钱。")


func _on_ferryman_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if GameState.has_flag("ferry_paid"):
		hud.set_prompt("船夫已经让开了。")
	elif GameState.has_item("coin"):
		GameState.remove_item("coin")
		GameState.set_flag("ferry_paid")
		_sync()
		hud.set_prompt("船夫收拢手指，侧身让开。")
	else:
		hud.set_prompt("你还没付钱。")


func _on_action_pressed() -> void:
	if GameState.has_flag("ferry_paid"):
		get_tree().change_scene_to_file("res://scenes/prologue/hotel_exterior.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/prologue/boat_cabin.tscn")
