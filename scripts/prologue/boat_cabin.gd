extends Control

@onready var hud: Control = $GameHUD
@onready var window_hotspot: Control = %WindowHotspot
@onready var bed_hotspot: Control = %BedHotspot
@onready var suitcase_hotspot: Control = %SuitcaseHotspot
@onready var table_hotspot: Control = %TableHotspot
@onready var window_sea: ColorRect = %WindowSea
@onready var window_shutter: ColorRect = %WindowShutter

const DEFAULT_PROMPT := "点击窗户，把它拉开。"


func _ready() -> void:
	window_hotspot.gui_input.connect(_on_window_input)
	bed_hotspot.gui_input.connect(_on_bed_input)
	suitcase_hotspot.gui_input.connect(_on_suitcase_input)
	table_hotspot.gui_input.connect(_on_table_input)
	hud.action_pressed.connect(_on_action_pressed)

	window_hotspot.mouse_entered.connect(func() -> void:
		if not GameState.has_flag("prologue_window_open"):
			hud.set_prompt("窗框上有一块铜牌：拉开。")
	)
	window_hotspot.mouse_exited.connect(_refresh_prompt)
	bed_hotspot.mouse_entered.connect(func() -> void: hud.set_prompt("床垫下面鼓着一块硬东西。"))
	bed_hotspot.mouse_exited.connect(_refresh_prompt)
	suitcase_hotspot.mouse_entered.connect(func() -> void: hud.set_prompt("一只旧行李箱，没有锁。"))
	suitcase_hotspot.mouse_exited.connect(_refresh_prompt)
	table_hotspot.mouse_entered.connect(func() -> void: hud.set_prompt("矮桌上有一块停住的怀表。"))
	table_hotspot.mouse_exited.connect(_refresh_prompt)

	hud.set_location("序章 · 船舱")
	_sync_window()
	_refresh_prompt()


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _sync_window() -> void:
	var opened := GameState.has_flag("prologue_window_open")
	window_sea.visible = opened
	window_shutter.visible = not opened
	window_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE if opened else Control.MOUSE_FILTER_STOP
	hud.set_action("去船头" if opened else "")


func _refresh_prompt() -> void:
	if GameState.has_flag("has_coin"):
		hud.set_prompt("该去船头了。")
	elif GameState.has_flag("mattress_cut"):
		hud.set_prompt("床垫里掉出一枚硬币。")
	elif GameState.has_flag("prologue_window_open"):
		hud.set_prompt("船已经靠岸。")
	else:
		hud.set_prompt(DEFAULT_PROMPT)


func _on_window_input(event: InputEvent) -> void:
	if _is_left_click(event) and not GameState.has_flag("prologue_window_open"):
		GameState.set_flag("prologue_window_open")
		_sync_window()
		hud.set_prompt("海面很静。船身的影子停在水里，没有跟着船走。")


func _on_suitcase_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if not GameState.has_item("knife"):
		GameState.add_item("knife")
		hud.set_prompt("你从行李箱里找到一把小折刀。")
	else:
		hud.set_prompt("行李箱里只剩旧衣服和几封没拆的信。")


func _on_bed_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	if GameState.has_flag("mattress_cut"):
		hud.set_prompt("床垫已经割开。")
	elif not GameState.has_item("knife"):
		hud.set_prompt("床垫下面有一块硬东西。手指抠不进去。")
	else:
		GameState.set_flag("mattress_cut")
		GameState.add_item("coin")
		hud.set_prompt("你割开床垫。一枚旧硬币滚出来。")
		hud.set_action("去船头" if GameState.has_flag("prologue_window_open") else "")


func _on_table_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	GameState.add_item("pocket_watch")
	hud.set_prompt("怀表停在 03:13。")


func _on_action_pressed() -> void:
	if GameState.has_flag("prologue_window_open"):
		get_tree().change_scene_to_file("res://scenes/prologue/shore.tscn")
