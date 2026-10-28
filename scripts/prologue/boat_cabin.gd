extends Control

@onready var window_hotspot: Control = %WindowHotspot
@onready var bed_hotspot: Control = %BedHotspot
@onready var suitcase_hotspot: Control = %SuitcaseHotspot
@onready var table_hotspot: Control = %TableHotspot
@onready var window_sea: ColorRect = %WindowSea
@onready var window_shutter: ColorRect = %WindowShutter
@onready var prompt_label: Label = %PromptLabel
@onready var continue_button: Button = %ContinueButton

const DEFAULT_PROMPT := "点击窗户，把它拉开。"
var window_opened := false


func _ready() -> void:
	window_hotspot.gui_input.connect(_on_window_input)
	bed_hotspot.gui_input.connect(_on_bed_input)
	suitcase_hotspot.gui_input.connect(_on_suitcase_input)
	table_hotspot.gui_input.connect(_on_table_input)
	continue_button.pressed.connect(_on_continue_pressed)

	window_hotspot.mouse_entered.connect(func() -> void:
		if not window_opened:
			_set_prompt("窗框上有一块铜牌：拉开。")
	)
	window_hotspot.mouse_exited.connect(func() -> void: _set_prompt(DEFAULT_PROMPT))
	bed_hotspot.mouse_entered.connect(func() -> void: _set_prompt("床垫下面鼓着一块硬东西。"))
	bed_hotspot.mouse_exited.connect(func() -> void: _set_prompt(DEFAULT_PROMPT))
	suitcase_hotspot.mouse_entered.connect(func() -> void: _set_prompt("一只旧行李箱，扣着。"))
	suitcase_hotspot.mouse_exited.connect(func() -> void: _set_prompt(DEFAULT_PROMPT))
	table_hotspot.mouse_entered.connect(func() -> void: _set_prompt("矮桌上有一块停住的怀表。"))
	table_hotspot.mouse_exited.connect(func() -> void: _set_prompt(DEFAULT_PROMPT))

	if GameState.has_flag("prologue_window_open"):
		_restore_window_open()
	else:
		_set_prompt(DEFAULT_PROMPT)


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _on_window_input(event: InputEvent) -> void:
	if _is_left_click(event) and not window_opened:
		_open_window()


func _on_bed_input(event: InputEvent) -> void:
	if _is_left_click(event) and not window_opened:
		_set_prompt("床垫下面有一块硬东西。现在还不能动它。")


func _on_suitcase_input(event: InputEvent) -> void:
	if _is_left_click(event) and not window_opened:
		_set_prompt("行李箱扣着。先看看窗外。")


func _on_table_input(event: InputEvent) -> void:
	if _is_left_click(event) and not window_opened:
		_set_prompt("怀表停在 03:13。")


func _open_window() -> void:
	window_opened = true
	window_sea.visible = true
	window_shutter.visible = false
	window_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_button.visible = true
	GameState.set_flag("prologue_window_open")
	_set_prompt("海面很静。船身的影子停在水里，没有跟着船走。")


func _restore_window_open() -> void:
	window_opened = true
	window_sea.visible = true
	window_shutter.visible = false
	window_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_button.visible = true
	_set_prompt("海面很静。船身的影子停在水里，没有跟着船走。")


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/prologue/shore.tscn")


func _set_prompt(text: String) -> void:
	prompt_label.text = text
